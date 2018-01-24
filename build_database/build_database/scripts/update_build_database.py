#!/usr/bin/env python3.6

"""
A framework program to handle changes to the document schema for given
types of documents; a module can be dynamically imported to utilize this
program so changes can be made easily without having to write a full new
program each time.

NOTE: This version is currently hardcoded for a specific change, it will
      be generalized to just be the framework code in the next revision.
"""

import argparse
import configparser
import logging
import pathlib
import sys

import cbbuild.cbutil.db as cbutil_db
import cbbuild.cbutil.git as cbutil_git


# Set up logging and handler
logger = logging.getLogger('build_database')
logger.setLevel(logging.INFO)

ch = logging.StreamHandler()
logger.addHandler(ch)


class UpdateCommits:
    """Handle updating the 'commit' documents in the build database"""

    def __init__(self, db_info, repo_info):
        """Set up information for database and repository access"""

        self.db = cbutil_db.CouchbaseDB(db_info)
        self.repo_base_dir = pathlib.Path(repo_info['repo_basedir'])
        self.repo_cache = cbutil_git.RepoCache()

    def get_remote(self, proj_name, url):
        """
        Retrieve a remote named based on the project name and URL;
        uses the project documents in the build database to determine
        this, returning None of the URL can't be found
        """

        key_name = f'project:{proj_name}'

        try:
            project_data = self.db.get_document(key_name)
        except cbutil_db.NotFoundError:
            logger.error(f"Project document '{key_name}' not found "
                         f"in database, aborting")
            sys.exit(1)

        for remote in project_data['remotes']:
            if url in project_data['remotes'][remote]:
                return remote
        else:
            return None

    def add_keys_to_commit_docs(self, document):
        """
        Several new keys are being added to the commit documents in
        the build_database:
            - project and sha (to make certain things easier)
            - author
            - committer
        A new document is generated to preserve order of the keys (since
        Python 3.6 databases do so by default)
        """

        commit_name = document['key_']
        remote_url = document['remote']
        project, sha = commit_name.rsplit('-', 1)

        # Acquire remote and get cached repository (necessary for this
        # to properly work, will fail if not found)
        remote = self.get_remote(project, remote_url)

        if remote is None:
            logger.error(f"Remote URL '{remote_url}' not found in project "
                         f"document 'project:{project}', aborting")
            sys.exit(1)

        repo = self.repo_cache.get_repo(
            project, self.repo_base_dir / project, remote, remote_url
        )

        try:
            commit = repo.get_object(sha.encode('utf-8'))
        except KeyError:
            print(f"Commit b'{sha}' not found in repository '{project}' "
                  f"under remote '{remote}', aborting")
            sys.exit(1)

        # Build new document to keep keys in same order as existing
        # updated documents
        new_document = dict(type='commit', key_=commit_name)
        new_document['project'] = project
        new_document['sha'] = sha
        new_document['in_build'] = document['in_build']
        new_document['author'] = commit.author.decode(errors='replace')
        new_document['committer'] = commit.committer.decode(errors='replace')
        new_document['summary'] = document['summary']
        new_document['timestamp'] = document['timestamp']
        new_document['parents'] = document['parents']
        new_document['remote'] = remote_url

        self.db.upsert_documents({commit_name: new_document})


def update_documents(doctype, db_info, repo_info):
    """
    General method to update/create documents in the build database

    NOTE: Currently hardcoded for a commit update, will be generalized
          in next revision
    """

    update_commits = UpdateCommits(db_info, repo_info)
    progress = 1

    for doc in update_commits.db.iterate_documents(doctype):
        if progress % 1000 == 0:
            print('.', end='', flush=True)

        if 'author' not in doc:
            update_commits.add_keys_to_commit_docs(doc)

        progress += 1

    print('\n')  # Final newline for progress 'bar'


def main():
    """
    Parse the command line arguments, handle configuration setup,
    then run the appropriate code to update the necessary schemas
    """

    parser = argparse.ArgumentParser(
        description='Update documents in build database'
    )
    parser.add_argument('-c', '--config', dest='db_repo_config',
                        help='Configuration file for build database loader',
                        default='build_db_loader_conf.ini')

    args = parser.parse_args()

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

    # Do actual change/update
    # NOTE: this will be replaced by a more general mechanism in
    #       the next revision
    update_documents('commit', db_info, repo_info)


if __name__ == '__main__':
    main()
