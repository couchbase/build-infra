#!/usr/bin/env python3.6

"""
Simple program to regenerate the bare repositories needed for the build
database loader program; to be used only when the repository tree has
been corrupted or deleted.

Simply runs through all the projects, taking all the remotes from the
project documents in the build database and checks out or updates each
repository for each project.
"""

import argparse
import configparser
import logging
import os
import pathlib
import urllib.error
import sys

import dulwich.errors

import cbbuild.cbutil.db as cbutil_db
import cbbuild.cbutil.git as cbutil_git


# Set up logging and handler
logger = logging.getLogger('load_build_database')
logger.setLevel(logging.DEBUG)

ch = logging.StreamHandler()
logger.addHandler(ch)


def regenerate_repositories(db_info, repo_info):
    """
    Run through all project documents found in build database, extract
    remote info from each and checkout/update bare repositories for each
    project
    """

    db = cbutil_db.CouchbaseDB(db_info)
    repo_base_dir = pathlib.Path(repo_info['repo_basedir'])
    repo_cache = cbutil_git.RepoCache()

    # Create base directory, if needed
    os.makedirs(repo_base_dir, exist_ok=True)

    for proj in db.query_documents('project', simple=True):
        proj_name = proj['name']
        logger.info(f'Creating {proj_name} repository...')
        project_data = db.get_document(f'project:{proj_name}')

        for remote in project_data['remotes']:
            for url in project_data['remotes'][remote]:
                print(f'    Adding remote {url} for {proj_name}...')
                try:
                    repo_cache.get_repo(
                        proj_name, repo_base_dir / proj_name, remote, url
                    )
                except (dulwich.errors.GitProtocolError,
                        urllib.error.HTTPError):
                    print(f'        Remote {url} no longer valid, skipping')
                    pass


def main():
    """
    Parse the command line arguments, handle configuration setup,
    then regenerate all necessary repositories (ensuring all branches
    are added) as dictated from the project documents in the build
    database
    """

    parser = argparse.ArgumentParser(
        description='Regenerate all repositories for build database'
    )
    parser.add_argument('-c', '--config', dest='db_repo_config',
                        help='Configuration file for build database',
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

    # Do the regenerations
    regenerate_repositories(db_info, repo_info)


if __name__ == '__main__':
    main()
