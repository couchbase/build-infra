#!/usr/bin/env python3.6

"""
Program to determine the current list of systems available on the various
virtual platforms (currently Xen, with possible future support for Docker
and VMware/vSphere) and update a database with key information for each
VM / container
"""

import argparse
import logging
import sys

import yaml

import cbbuild.cbutil.db as cbutil_db


# Set up logging and handler
logger = logging.getLogger('load_build_database')
logger.setLevel(logging.INFO)

ch = logging.StreamHandler()
logger.addHandler(ch)

# Module path containing various supported platforms (e.g. Xen)
platform_mod = 'infradb.platforms'


def import_class(module_path, classname):
    """Import a given class from the given module"""

    try:
        try:
            __import__(module_path, globals(), locals(), classname)
            mod = sys.modules[module_path]
        except (ValueError, ImportError, KeyError) as err:
            raise err

        return getattr(mod, classname)
    except AttributeError:
        raise ImportError('Failed while importing class %s from module %s'
                          % (classname, module_path))


class FindSystems:
    """ """

    def __init__(self, db_info, platforms):
        """Basic initialization"""

        self.db = cbutil_db.CouchbaseDB(db_info)
        self.platforms = platforms
        self.system_info = {}

    def determine_systems(self):
        """
        Based on given platforms from configuration, determine systems
        that need to be inventoried
        """

        for platform in self.platforms:
            # Import appropriate class for given platform
            host_type = platform['host_type']
            cls = import_class(
                '{}.{}'.format(platform_mod, host_type), 'System'
            )

            # Run through set of hosts and gather information
            # (instantiates the imported class)
            for host_info in platform['hosts']:
                host_system = cls(**host_info)
                self.system_info.update(host_system.find_systems())

    def update_db(self):
        """Update determined documents (keyed off host)"""

        self.db.upsert_documents(self.system_info)


def main():
    """
    Read configuration, do basic sanity check, then acquire information
    from given hosts
    """

    parser = argparse.ArgumentParser(
        description='Scan known systems for current inventory information'
    )
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Enable debugging output')
    parser.add_argument('-c', '--config', dest='sys_config',
                        help='Configuration file for system info updater',
                        default='servers.yaml')

    args = parser.parse_args()

    # Set logging to debug level on stream handler if --debug was set
    if args.debug:
        ch.setLevel(logging.DEBUG)

    with open(args.sys_config) as fh:
        try:
            sys_config = yaml.load(fh)
        except yaml.YAMLError as exc:
            print(f'Failed to parse servers.yaml: {exc.message}')
            sys.exit(1)

    if 'build_db' not in sys_config:
        print(f'Config file missing "build_db" information')
        sys.exit(1)

    if 'platforms' not in sys_config:
        print(f'Config file missing "platforms" information')
        sys.exit(1)

    systems = FindSystems(sys_config['build_db'][0], sys_config['platforms'])
    systems.determine_systems()
    systems.update_db()


if __name__ == '__main__':
    main()
