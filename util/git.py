"""
Collection of methods for using Git via Dulwich
"""

from dulwich.repo import Repo


class ManifestWalker:
    """
    Walk all branches for a manifest repository and return key info
    and the contents of each commit; this walker moves forward in
    Git history
    """

    exclude_commits = [b'79aaba8ca8700c14709951a1b86ab67b0b12331a']

    def __init__(self, manifest_dir):
        """Set up repository access"""

        self.repo = Repo(manifest_dir)

    def walk(self):
        """
        Find all branches and do a full walk, history forward,
        of all commits, returning key information and contents
        of each commit
        """

        commits = [
            self.repo.get_object(self.repo.refs[ref])
            for ref in self.repo.refs.keys()
            if ref.startswith(b'refs/remotes')
        ]

        walker = self.repo.get_walker(
            include=[commit.id for commit in commits],
            exclude=self.exclude_commits, reverse=True
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
