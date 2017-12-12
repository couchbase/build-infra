"""
Program to do initial data load for the build database.

Keep document with all branches for build-team-manifests and latest-seen
commit for each branch

Start with a manifest from build-team-manifests, extract build entry
from this

Next, step through Git history of build-team-manifests, and use each
commit to generate a new build entry

(For update, use first mentioned document to do incremental updates;
don't redo commits already done.)
"""

import argparse
import configparser
import logging
import pathlib
import sys

from collections import defaultdict

import cbbuild.manifest.info as mf_info
import cbbuild.manifest.parse as mf_parse
import cbbuild.cbutil.db as cbutil_db
import cbbuild.cbutil.git as cbutil_git


# Set up logging and handler
logger = logging.getLogger('load_build_database')
logger.setLevel(logging.INFO)

ch = logging.StreamHandler()
logger.addHandler(ch)


class BuildDBLoader:
    """
    Used for loading initial build and Git data into the build database
    """

    def __init__(self, db_info, repo_info):
        """Basic initialization"""

        self.initial_data = None
        self.db = cbutil_db.CouchbaseDB(db_info)
        self.prod_ver_index = self.db.get_product_version_index()
        self.first_prod_ver_build = False
        self.project = None
        self.repo_base_path = pathlib.Path(repo_info['repo_basedir'])
        self.repo_cache = cbutil_git.RepoCache()

    @staticmethod
    def get_manifest_info(manifest_xml):
        """
        Parse the manifest XML and create a dictionary with the data
        """

        manifest_info = mf_parse.Manifest(manifest_xml, is_bytes=True)
        manifest_data = manifest_info.parse_data()

        return mf_info.ManifestInfo(manifest_data)

    def get_last_manifest(self):
        """
        Retrieve the commit SHA for the last build manifest fully
        processed; if the document or key doesn't exist, assume
        we're starting from the beginning
        """

        try:
            doc = self.db.get_document('last-manifest')
        except cbutil_db.NotFoundError:
            return []
        else:
            return [doc['latest_sha']] if 'latest_sha' in doc else []

    def update_last_manifest(self, manifest_sha):
        """
        Update the last build manifest document in the database
        with the new commit SHA
        """

        self.db.upsert_documents(
            {'last-manifest': {'latest_sha': manifest_sha}}
        )

    def is_new_commit(self, commit, cache):
        """
        Check a given commit is being seen for the first time by seeing
        if it's already in the local cache or in the build database
        """

        return (commit.id not in cache and not self.db.key_in_db(
            f'{self.project}-{commit.id.decode()}'
        ))

    @staticmethod
    def update_commit_cache(commit, cache):
        """Add given commit to the local cache"""

        cache.append(commit.id)

    def find_commits(self, project, shas, manifest_info):
        """
        Find all new commits for a given project from a given list of
        commit SHAs.  This does a custom walk through the Git repo for
        the project and compares to a local cache of commits along
        with checking the database.

        Returns a list of the new commits (potentially empty), along
        with any invalid commit SHAs that had been passed in.

        TODO: This doesn't quite handle when there are multiple commit
              SHAs for the project and one of them is invalid, due to
              an unknown ordering issue.  This should be fixed, if at
              all possible.
        """

        # Temporarily set for other methods to access
        self.project = project

        new_commits = list()
        invalid_shas = list()
        commit_cache = list()

        remote, project_url = manifest_info.get_project_remote_info(project)
        project_shas = [sha.replace(f'{project}-', '') for sha in shas]
        commit_walker = cbutil_git.CommitWalker(
            project, self.repo_base_path / project, remote, project_url,
            self.repo_cache
        )

        for project_sha in project_shas:
            try:
                new_commits.extend(commit_walker.walk(
                    project_sha.encode('utf-8'), commit_cache,
                    self.is_new_commit, self.update_commit_cache
                ))
            except cbutil_git.MissingCommitError:
                invalid_shas.append(f'{project}-{project_sha}')

        # Reset to ensure not accidentally re-used by another run
        # of the method or other methods
        self.project = None

        return new_commits, invalid_shas

    def generate_build_document(self, commit_info, manifest_info):
        """
        Generate a build entry from the given build manifest.

        Most of the information for the document is determined here,
        except the 'invalid_shas' and 'commits' keys which are
        populated later by other methods.  Returns the collected
        build document data for further use by the program.
        """

        manifest_path, commit = commit_info
        build_name = manifest_info.name
        logger.info(f'Generating build document for manifest {build_name}...')

        # See if build document already is in the database and extract
        # for updating if so, otherwise create a new dictionary for
        # population
        try:
            build_data = self.db.get_document(build_name)
        except cbutil_db.NotFoundError:
            build_data = dict(type='build', key_=build_name)

        projects = dict()

        for project_name in manifest_info.get_projects():
            project_shas = manifest_info.get_project_shas(
                project_name
            )
            projects[project_name] = [
                f'{project_name}-{sha}' for sha in project_shas
            ]
        build_data['manifest'] = projects
        build_data['invalid_shas'] = list()  # Populated (potentially) later

        release_keys = ('product', 'release', 'version', 'build_num')
        release_data = manifest_info.get_release_info()
        product, release, version, build_num = release_data
        build_data.update(dict(zip(release_keys, release_data)))

        index_key = f'{product}-{version}'
        build_data['prev_build_num'] = (
            self.prod_ver_index.get(index_key, None)
        )

        build_data['commits'] = list()   # Populated (potentially) later
        build_data['manifest_sha'] = commit.id.decode()
        build_data['manifest_path'] = manifest_path.decode()
        build_data['timestamp'] = commit.commit_time
        build_data['download_url'] = (
            f'http://latestbuilds.service.couchbase.com/builds/latestbuilds/'
            f'{product}/{release}/{build_num}'
        )

        self.db.upsert_documents({build_name: build_data})

        self.first_prod_ver_build = (
            True if build_data['prev_build_num'] is None else False
        )
        self.prod_ver_index[index_key] = build_num
        self.db.update_product_version_index(self.prod_ver_index)

        return build_data

    def generate_commit_documents(self, build_data, manifest_info):
        """
        From the given build manifest data, determine all new commits
        for said build manifest and generate commit documents for
        the build database for them.

        Done on a per-project basis, if any invalid commit SHAs are
        found, the entries are removed from the relevant 'manifest' key
        in the build document and added to the 'invalid_shas' key for
        future reference, and commit history is ignored.
        """

        projects = build_data['manifest']
        invalid_project_shas = defaultdict(list)

        for project in projects:
            commits = dict()

            commit_info, invalid_shas = self.find_commits(
                project, projects[project], manifest_info
            )

            if invalid_shas:
                # We hit a bad SHA, so pop the project and SHA onto
                # a dictionary and rebuild the build_data without
                # that specific project SHA
                invalid_project_shas[project].extend(invalid_shas)
                shas = build_data['manifest'][project]
                build_data['manifest'][project] = [
                    sha for sha in shas if sha not in invalid_shas
                ]
                continue

            for commit in commit_info:
                commit_name = f'{project}-{commit.id.decode()}'
                logger.debug(f'Generating commit document for '
                             f'commit {commit_name}')

                commit_data = dict(type='commit', key_=commit_name)

                commit_data['in_build'] = list()  # Populated later
                commit_data['summary'] = \
                    commit.message.decode(errors='replace')
                commit_data['timestamp'] = commit.commit_time
                commit_data['parents'] = [
                    f'{project}-{commit_id.decode()}'
                    for commit_id in commit.parents
                ]
                commit_data['remote'] = \
                    manifest_info.get_project_remote_info(project)[1]
                commits[commit_name] = commit_data

            if commits:
                self.db.upsert_documents(commits)

        if invalid_project_shas:
            # We had bad project SHAs, so we need to clean up build_data
            # a bit - in particular, if we have a project in the 'manifest'
            # key with a now empty SHA list, we need to remove it entirely
            # from the key - then add the list of invalid SHAs and write
            # the build document back out with the updated information
            logging.debug(f'Invalid SHAs found: '
                          f'{", ".join(invalid_project_shas)}')
            build_name = build_data['key_']
            build_data['manifest'] = {
                project: sha for project, sha
                in build_data['manifest'].items() if sha
            }
            build_data['invalid_shas'] = invalid_project_shas
            self.db.upsert_documents({build_name: build_data})

    def update_build_commit_documents(self, build_data):
        """
        For the given build manifest data, determine build and commit
        associations and update the relevant documents.

        This handles both existing and new projects for a given build,
        and only inserts the last commit document ID for the build
        document's manifest if it's a new project (either entirely new,
        or re-added after having been removed previously), otherwise
        it inserts all the relevant commit document IDs.

        Reciprocally, all relevant commit documents have their key
        'in_build' updated with the build document ID.
        """

        product, version, prev_build_num = (
            build_data[key] for key
            in ['product', 'version', 'prev_build_num']
        )
        prev_build_data = self.db.get_document(
            f'{product}-{version}-{prev_build_num}'
        )

        for project, shas in build_data['manifest'].items():
            new_shas = [sha.replace(f'{project}-', '').encode('utf-8')
                        for sha in shas]
            old_shas = [sha.replace(f'{project}-', '').encode('utf-8')
                        for sha in prev_build_data['manifest'].get(
                            project, []
                        )]

            diff_walker = cbutil_git.DiffWalker(self.repo_base_path / project)
            diff_commits = diff_walker.walk(old_shas, new_shas)

            if not diff_commits:
                continue

            if old_shas:
                commit_ids = [f'{project}-{commit.id.decode()}'
                              for commit in diff_commits]
            else:
                # Only keep most recent commit for new projects
                commit_ids = [f'{project}-{diff_commits[0].id.decode()}']

            build_name = build_data['key_']
            logger.debug(f'Updating {build_name} build document for '
                         f'the following commits: {", ".join(commit_ids)}')
            build_document = self.db.get_document(build_name)
            build_document['commits'].extend(commit_ids)
            self.db.upsert_documents({build_name: build_document})

            for commit_id in commit_ids:
                commit_document = self.db.get_document(commit_id)

                # The check protects from duplicate build document IDs
                # for a commit (potentially due to a loading failure)
                if build_name not in commit_document['in_build']:
                    commit_document['in_build'].append(build_name)

                self.db.upsert_documents({commit_id: commit_document})


def main():
    """
    Parse the command line arguments, handle configuration setup,
    initialize loader, then walk all manifests and generate data
    which is then put into the database
    """

    parser = argparse.ArgumentParser(
        description='Perform initial loading of build database from manifests'
    )
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Enable debugging output')
    parser.add_argument('-c', '--config', dest='db_repo_config',
                        help='Configuration file for build database loader',
                        default='build_db_loader_conf.ini')

    args = parser.parse_args()

    # Set logging to debug level on stream handler if --debug was set
    if args.debug:
        ch.setLevel(logging.DEBUG)

    # Check configuration file information
    db_repo_config = configparser.ConfigParser()
    db_repo_config.read(args.db_repo_config)

    if any(key not in db_repo_config for key in ['build_db', 'repos']):
        logger.error(
            f'Invalid or unable to read config file {args.db_repo_config}'
        )
        sys.exit(1)

    db_info = db_repo_config['build_db']
    db_required_keys = ['db_uri', 'username', 'password']

    if any(key not in db_info for key in db_required_keys):
        logger.error(
            f'One of the following DB keys is missing in the config file:\n'
            f'    {", ".join(db_required_keys)}'
        )
        sys.exit(1)

    repo_info = db_repo_config['repos']
    repo_required_keys = ['manifest_dir', 'manifest_url', 'repo_basedir']

    if any(key not in repo_info for key in repo_required_keys):
        logger.error(
            f'One of the following repo keys is missing in the '
            f'config file:\n    {", ".join(repo_required_keys)}'
        )
        sys.exit(1)

    # Setup loader, read in latest manifest processed, get build manifest
    # information, checkout/update build manifest repo and walk it,
    # generating the build documents, then the new commits for the build,
    # and then linking the build and commit entries to each other as needed,
    # finishing with updating the last manifest document (needed to do
    # incremental updates or restart an interrupted loading run)
    build_db_loader = BuildDBLoader(db_info, repo_info)
    last_manifest = build_db_loader.get_last_manifest()
    manifest_repo = repo_info['manifest_dir']

    logger.info('Checking out/updating the build-manifests repo...')
    cbutil_git.checkout_repo(manifest_repo, repo_info['manifest_url'])

    logger.info(f'Creating manifest walker and walking it...')
    if last_manifest:
        logger.info(f'    starting after commit {last_manifest[0]}...')

    manifest_walker = cbutil_git.ManifestWalker(manifest_repo, last_manifest)

    for commit_info, manifest_xml in manifest_walker.walk():
        try:
            manifest_info = build_db_loader.get_manifest_info(manifest_xml)
        except mf_parse.InvalidManifest as exc:
            # If the file is not an XML file, simply move to next one
            logger.info(f'{commit_info[0]}: {exc}, skipping...')
            continue

        build_data = build_db_loader.generate_build_document(commit_info,
                                                             manifest_info)
        build_db_loader.generate_commit_documents(build_data, manifest_info)

        if not build_db_loader.first_prod_ver_build:
            build_db_loader.update_build_commit_documents(build_data)

        logger.debug('Updating last manifest document...')
        build_db_loader.update_last_manifest(build_data['manifest_sha'])


if __name__ == '__main__':
    main()
