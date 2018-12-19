import logging
import pathlib

import cbbuild.cbutil.git as cbutil_git


# Set up logging and handler
logger = logging.getLogger('util.build_diff')
logger.setLevel(logging.INFO)

ch = logging.StreamHandler()
logger.addHandler(ch)


class BuildDiff:
    """
    Used to produce a diff between two arbitrary builds in the build database.
    The general schema of the JSON form of the diff is:
    {
        "removed": {
            "project": COMMIT,   # commit as of earlier build
            ....
        },
        "added": {
            "project": COMMIT,   # commit as of later build
            ....
        },
        "changed": {
            "project": {
                "from": COMMIT,
                "to": COMMIT,
                "added": [
                    COMMIT, COMMIT, ...
                ],
                "removed": [
                    COMMIT, COMMIT, ...
                ]
            }
        }
    }

    where in all cases, COMMIT is a dict matching a commit entry in the
    build database.

    All top-level keys will always exist, even if their values are empty
    dictionaries. Inside "changed", only projects with changes will exist.
    The dict value of all such projects will contain all keys (from, to,
    aded, removed), even if their values are empty lists.

    NOTE: this does not attempt to handle projects that appear multiple
    times in a manifest. Only the first entry per project will be diffed.
    """

    def __init__(self, db_conn, product, from_build, to_build, git_dir):
        """Basic initialization"""

        self.db = db_conn
        self.product = product
        self.from_build = \
            self.db.get_build(product, *from_build.split('-')[:2]).manifest
        self.to_build = \
            self.db.get_build(product, *to_build.split('-')[:2]).manifest
        self.git_dir = pathlib.Path(git_dir)

    @staticmethod
    def _sha(key):
        """Returns the SHA portion of a commit key"""

        return key.split('-')[-1].encode('utf-8')

    def _new_commits(self, project, from_commit, to_commit):
        """
        Returns list of commits in to_commit that are not in from_commit,
        equivalent to "git log from_commit..to_commit"
        """

        repo_dir = self.git_dir / project
        logger.debug(f"Computing added commits in {project}")

        return [
            self.db.get_document(f'{project}-{commit.sha().hexdigest()}')
            for commit in cbutil_git.DiffWalker(repo_dir).walk(
                [self._sha(from_commit)], [self._sha(to_commit)]
            )
        ]

    def get_diff(self):
        """
        Performs the overall diff and returns a Python dict representation
        """

        diffs = {
            'removed': {
                ele: self.db.get_document(self.from_build[ele][0])
                for ele in set(self.from_build) - set(self.to_build)
            },
            'added': {
                ele: self.db.get_document(self.to_build[ele][0])
                for ele in set(self.to_build) - set(self.from_build)
            },
            'changed': dict(),
        }

        for project in set(self.from_build) & set(self.to_build):
            from_commit = self.from_build[project][0]
            to_commit = self.to_build[project][0]

            if from_commit == to_commit:
                continue

            diffs['changed'][project] = {
                'from': self.db.get_document(from_commit),
                'to': self.db.get_document(to_commit),
                'added': self._new_commits(project, from_commit, to_commit),
                'removed': self._new_commits(project, to_commit, from_commit),
            }

        return diffs

    # differ = BuildDiff(
    #     db_info, args.product, args.from_build, args.to_build,
    #     repos_info['repo_basedir']
    # )
    # print(json.dumps(differ.get_diff()))
