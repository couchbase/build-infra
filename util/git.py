"""
Collection of methods for using Git via Dulwich, primarily designed
for use with the build database
"""

import pathlib
import sys

from collections import namedtuple

import dulwich.errors

from dulwich.client import get_transport_and_path
from dulwich.porcelain import clone, remote_add
from dulwich.repo import Repo


class MissingCommitError(Exception):
    """Module-level exception for missing/invalid commits"""

    pass


class RepoCacheEntry:
    """Simple class to handle entries for the repository cache"""

    def __init__(self, name, directory, remotes, current_remote):
        """Basic initialization for cache entry"""

        self.name = name
        self.directory = directory
        self.remotes = remotes
        self.current_remote = current_remote
        self.origin = None

    def add_remote(self, remote):
        """Add a new remote to the entry and set it as the current one"""

        self.remotes.append(remote)
        self.current_remote = remote

    def set_origin(self, remote_name):
        """Set the repository's origin to the given remote"""

        self.origin = remote_name


class RepoCache:
    """
    Managed which repositories are being accessed and keep track
    to allow for caching information to avoid excess remote access
    and keep the process moving as quickly as possible
    """

    default_bytes_err_stream = getattr(sys.stderr, 'buffer', sys.stderr)
    RemoteEntry = namedtuple('RemoteEntry', ['name', 'url'])

    def __init__(self):
        """Initialize the cache"""

        self.cache = dict()

    def get_remotes(self, repo):
        """Get the current set of remotes for a given repository"""

        conf = repo.get_config()
        remotes = list()

        for key in conf.keys():
            if key[0] == b'remote':
                remotes.append(self.RemoteEntry(
                    key[1].decode(), conf.get(key, b'url').decode()
                ))

        return remotes

    @staticmethod
    def fetch(repo, remote_location, outstream=sys.stdout,
              errstream=default_bytes_err_stream):
        """
        Modified form of dulwich's porcelain.fetch method which
        fetches from all remotes
        """

        client, path = get_transport_and_path(remote_location)
        remote_refs = client.fetch(
            path, repo,
            determine_wants=repo.object_store.determine_wants_all,
            progress=errstream.write
        )

        return remote_refs

    @staticmethod
    def find_origin(remotes):
        """
        Determine a repository's origin remote, if it exists;
        a list of the remotes for the repository is passed
        """

        found_origin = None

        for remote in remotes:
            if remote.name == 'origin':
                found_origin = remote
                break

        return found_origin

    def get_repo(self, project, repo_dir, remote, repo_url=None):
        """
        Given a project and it's repository information (checkout directory,
        remote name and URL), look at the cache and determine what needs
        to be done for the repository.

        Specifically, only fetch from the remote when needed:
          - Repository is checked out, remote is new
          - Repository is checked out, but not already in cache
          - Repository is not checked out (the clone essentially
            does the fetching)

        Note that fetches are not necessary each time the repository is
        accessed, as it will contain all the information needed when the
        build-manfiest repository was accessed; only remote changes and
        initial access require a fetch.

        Ensure cache is kept up to date with all changes made, and keep
        track of the current remote (needed to know when to do another
        fetch for the repository).
        """

        repo_dir = str(repo_dir.resolve())
        repo_exists = pathlib.Path(pathlib.Path(repo_dir) / 'config').exists()

        if repo_exists:
            # Repository is already checked out, so initialize connection
            # and update cache based on current cache information
            repo = Repo(repo_dir)

            if project in self.cache:
                # Repository in cache, do sanity check for repository
                # directory and remote, fetching from URL if we have
                # a new remote (and adding remote to the repository)
                repo_entry = self.cache[project]

                if repo_dir != repo_entry.directory:
                    raise RuntimeError(
                        f'Project directory given does not match what is '
                        f'currently in cache: '
                        f'{repo_dir} != {repo_entry.directory}'
                    )

                remotes = [remote.name for remote in repo_entry.remotes]

                if remote not in remotes:
                    repo_entry.add_remote(self.RemoteEntry(remote, repo_url))
                    self.fetch(repo, repo_url)
            else:
                # Repository needs to be added to cache, ensure URL
                # has been given, then create cache entry, update
                # remote information (setting origin if necessary;
                # this will not be needed in next dulwich release),
                # then fetch from URL
                if repo_url is None:
                    raise RuntimeError(f'New project "{project}" has no '
                                       f'remote URL')

                remotes = self.get_remotes(repo)
                remote_names = [remote.name for remote in remotes]

                self.cache[project] = RepoCacheEntry(
                    remote, repo_dir, remotes, remote
                )

                if remote not in remote_names:
                    self.cache[project].add_remote(
                        self.RemoteEntry(remote, repo_url)
                    )
                    origin = self.find_origin(remotes)

                    if origin and repo_url == origin.url:
                        self.cache[project].set_origin(remote)
                    else:
                        remote_add(repo_dir, remote, repo_url)

                self.fetch(repo, repo_url)
        else:
            # Repository has not been checked out yet, therefore
            # there will be no cache entry, so ensure URL is given,
            # set up cache entry and clone the repo, setting the
            # origin to the current remote (NOTE: this doesn't work
            # properly in dulwich until the next (0.18.5) release,
            # but code is in place for when it does).
            if repo_url is None:
                raise RuntimeError(f'New project "{project}" has no '
                                   f'remote URL')

            remotes = [self.RemoteEntry(remote, repo_url)]
            self.cache[project] = RepoCacheEntry(
                remote, repo_dir, remotes, remote
            )
            self.cache[project].set_origin(remote)

            try:
                repo = clone(repo_url, target=repo_dir, bare=True,
                             origin=remote.encode('utf-8'))
            except dulwich.errors.HangupException:
                raise RuntimeError(
                    f'Unable to clone bare repo "{repo_url}" into directory '
                    f'{repo_dir}'
                )

        return repo


class ManifestWalker:
    """
    Walk all branches for a manifest repository and return key info
    and the contents of each commit; this walker moves forward in
    Git history
    """

    def __init__(self, manifest_dir, latest_sha):
        """Initialize the repository connection and encode latest SHAs"""

        self.repo = Repo(manifest_dir)
        self.latest_sha = [sha.encode('utf-8') for sha in latest_sha]

    def walk(self):
        """
        Find all branches and do a full walk from a given commit,
        history forward, returning key information and contents
        of each commit
        """

        branches = [
            self.repo.get_object(self.repo.refs[ref])
            for ref in self.repo.refs.keys()
            if ref.startswith(b'refs/remotes')
        ]

        walker = self.repo.get_walker(
            include=list(set([branch.id for branch in branches])),
            exclude=self.latest_sha, reverse=True
        )

        for entry in walker:
            changes = entry.changes()

            # Skip any commit that doesn't have exactly one change
            # (Zero is a merge commit, more than one is a multi-file
            # commit)
            if len(changes) != 1:
                continue

            change = changes[0]
            yield ((change.new.path, entry.commit),
                   self.repo.get_object(change.new.sha).as_pretty_string())


class CommitWalker:
    """
    Walk a given project's commit history and return key info for each
    commit; handle merges appropriately
    """

    def __init__(self, project, repo_dir, remote, repo_url, repo_cache):
        """Initialize the repository connection and set/update the cache"""

        self.repo = repo_cache.get_repo(project, repo_dir, remote, repo_url)

    def walk(self, commit_sha, cache, check_func, update_func):
        """
        Walk the commit history back starting from the given SHA
        and return key info for each commit; the functions for
        checking termination of a given walk path as well as updating
        a cache for tracking commits are passed through dynamically
        """

        commits = list()

        try:
            stack = [self.repo.get_object(commit_sha)]
        except KeyError:
            raise MissingCommitError(f'Invalid SHA: {commit_sha.decode()}')

        # Instead of using dulwich's get_walker method, use a stack
        # and manually step through the commits; this allows each one
        # to be checked on a given terminating condition to prevent
        # duplicate commits from previous builds being added
        while stack:
            node = stack.pop()

            if check_func(node, cache):
                update_func(node, cache)
                commits.append(node)
                stack.extend(
                    [self.repo.get_object(comm) for comm in node.parents]
                )

        return commits


class DiffWalker:
    """
    Handles determining which new commits occurred between two successive
    builds, taking into account possibly having no previous build
    """

    def __init__(self, repo_dir):
        """Initialize the repository connection"""

        # Making the assumption the repo is already checked out
        # at this location from previous steps
        self.repo = Repo(str(repo_dir.resolve()))

    def walk(self, old_shas, new_shas):
        """
        Walk through the set of commits between the sets of given SHAs
        to determine the new commits and return the list of the commits
        """

        try:
            walker = self.repo.get_walker(include=new_shas, exclude=old_shas)
        except dulwich.errors.MissingCommitError as exc:
            raise MissingCommitError(exc)

        return [entry.commit for entry in walker]
