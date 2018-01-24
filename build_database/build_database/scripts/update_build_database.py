#!/usr/bin/env python3.6

"""
A framework program to handle changes to the document schema for given
types of documents; a module can be dynamically imported to utilize this
program so changes can be made easily without having to write a full new
program each time.
"""

import argparse
import configparser
import importlib
import logging
import sys


# Set up logging and handler
logger = logging.getLogger('build_database.scripts.update_build_database')
logger.setLevel(logging.INFO)

ch = logging.StreamHandler()
logger.addHandler(ch)


def update_documents(module_name, db_info, repo_info):
    """
    General method to update/create documents in the build database
    """

    try:
        mod = importlib.import_module(f'.{module_name}', package='modules')
    except ImportError as exc:
        logging.error(f'Importing {module_name} failed: {exc}')
        sys.exit(1)

    update = mod.UpdateDocuments(db_info, repo_info)
    progress = 1

    for doc in update.db.query_documents(update.doctype, simple=True):
        if progress % 1000 == 0:
            print('.', end='', flush=True)

        update.update_documents(doc)

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
    parser.add_argument('module', help='Module name containing changes')

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
    update_documents(args.module, db_info, repo_info)


if __name__ == '__main__':
    main()
