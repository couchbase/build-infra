import argparse
import collections
import configparser
import json
import logging
import pathlib
import sys
from subprocess import check_output

import cbbuild.cbutil.db as cbutil_db
import cbbuild.cbutil.git as cbutil_git

# Set up logging and handler
logger = logging.getLogger('diff_builds')
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

    def __init__(self, db_info, product, from_build, to_build, gitdir):
        self.db = cbutil_db.CouchbaseDB(db_info)
        self.product = product
        fromb = from_build.split('-')
        tob = to_build.split('-')
        self.from_build = self.db.get_build(product, fromb[0], fromb[1]).manifest
        self.to_build = self.db.get_build(product, tob[0], tob[1]).manifest
        self.gitdir = pathlib.Path(gitdir)

    @staticmethod
    def __sha(key):
        """Returns the SHA portion of a commit key"""

        return key.split('-')[-1].encode("utf-8")

    def __get_missing(self, maniA, maniB):
        """
        Returns dictionary of projects and their SHAs in A
        that are missing in B
        """

        missing = {}

        for project, commits in maniA.items():
            if project not in maniB:
                missing[project] = self.db.get_document(commits[0])

        return missing

    def __added_commits(self, project, from_commit, to_commit):
        """
        Returns list of commits in to_commit that are not
        in from_commit, equivalent to "git log from_commit..to_commit".
        """

        repodir = self.gitdir / project
        logger.debug(f"Computing added commits in {project}")
        return [
            self.db.get_document(f'{project}-{commit.sha().hexdigest()}') for commit in
            cbutil_git.DiffWalker(repodir).walk(
                [self.__sha(from_commit)],
                [self.__sha(to_commit)]
            )
        ]

    def __get_diffs(self, project, from_commit, to_commit):
        """
        Returns dictionary of diffs for a project
        """

        diffs = {}
        diffs["from"] = self.db.get_document(from_commit)
        diffs["to"] = self.db.get_document(to_commit)
        diffs["added"] = self.__added_commits(
            project, from_commit, to_commit
        )
        diffs["removed"] = self.__added_commits(
            project, to_commit, from_commit
        )
        return diffs

    def get_diff(self):
        """
        Performs the overall diff and returns a Python dict representation
        """

        diff = {}
        diff["removed"] = self.__get_missing(self.from_build, self.to_build)
        diff["added"] = self.__get_missing(self.to_build, self.from_build)
        diff["changed"] = {}

        for project, commits in self.from_build.items():
            if project not in self.to_build:
                continue

            from_commit = commits[0]
            to_commit = self.to_build[project][0]
            if from_commit == to_commit:
                continue

            diff["changed"][project] = \
                self.__get_diffs(project, from_commit, to_commit)

        return diff

def main():
    parser = argparse.ArgumentParser(
        description='Diff two builds in the build database'
    )
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Enable debugging output')
    parser.add_argument('-c', '--config', dest='db_repo_configfile',
                        help='Configuration file for build database loader',
                        default='build_db_conf.ini')
    parser.add_argument('product', help='Product name')
    parser.add_argument('from_build', help='Earlier build (X.Y.Z-BBBB)')
    parser.add_argument('to_build', help='Later build (X.Y.Z-BBBB)')
    args = parser.parse_args()

    # Set logging to debug level on stream handler if --debug was set
    if args.debug:
        logger.setLevel(logging.DEBUG)

    # Read database config file
    db_repo_config = configparser.ConfigParser()
    db_repo_config.read(args.db_repo_configfile)

    if 'build_db' not in db_repo_config or 'repos' not in db_repo_config:
        logger.error(
            f'Invalid or unable to read config file {args.db_repo_configfile}'
        )
        sys.exit(1)

    db_info = db_repo_config['build_db']
    repos_info = db_repo_config['repos']

    differ = BuildDiff(
        db_info, args.product, args.from_build, args.to_build,
        repos_info['repo_basedir']
    )
    print(json.dumps(differ.get_diff()))

if __name__ == '__main__':
    main()
