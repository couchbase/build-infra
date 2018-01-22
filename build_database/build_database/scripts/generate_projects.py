#!/usr/bin/env python3.6

"""
Quick program to insert new 'projects' documents
"""

import argparse
import configparser
import pathlib
import sys

import cbbuild.manifest.info as mf_info
import cbbuild.manifest.parse as mf_parse
import cbbuild.cbutil.db as cbutil_db
import cbbuild.cbutil.git as cbutil_git


class AddProject:
    """
    Class to create or update project documents in the build database
    """

    def __init__(self, db_info, repo_info):
        """Basic initialization"""

        self.db = cbutil_db.CouchbaseDB(db_info)
        self.repo_base_path = pathlib.Path(repo_info['repo_basedir'])

    @staticmethod
    def get_manifest_info(manifest_xml):
        """
        Parse the manifest XML and create a dictionary with the data
        """

        manifest_info = mf_parse.Manifest(manifest_xml, is_bytes=True)
        manifest_data = manifest_info.parse_data()

        return mf_info.ManifestInfo(manifest_data)

    def update_project_documents(self, manifest_info):
        """
        Add or update a set of given project documents from a given
        manifest
        """

        for proj_name, proj_info in manifest_info.projects.items():
            # See if project document already is in the database and extract
            # for updating if so, otherwise create a new dictionary for
            # population
            key_name = f'project:{proj_name}'

            try:
                project_data = self.db.get_document(key_name)
            except cbutil_db.NotFoundError:
                project_data = dict(
                    type='project', key_=key_name, name=proj_name
                )

            remote, repo_url = \
                manifest_info.get_project_remote_info(proj_name)

            if 'remotes' in project_data:
                if remote in project_data['remotes']:
                    if repo_url not in project_data['remotes'][remote]:
                        project_data['remotes'][remote].append(repo_url)
                else:
                    project_data['remotes'][remote] = [repo_url]
            else:
                project_data['remotes'] = {remote: [repo_url]}

            self.db.upsert_documents({key_name: project_data})


def main():
    """
    Parse command line, read in configuration file then got through the
    full build-manifests repository to generate all projects documents
    """

    parser = argparse.ArgumentParser(
        description='Perform initial loading of build database from manifests'
    )
    parser.add_argument('-c', '--config', dest='add_proj_config',
                        help='Configuration file for build database loader',
                        default='build_db_loader_conf.ini')

    args = parser.parse_args()

    # Check configuration file information
    add_proj_config = configparser.ConfigParser()
    add_proj_config.read(args.add_proj_config)

    if any(key not in add_proj_config for key in ['build_db', 'repos']):
        print(
            f'Invalid or unable to read config file {args.add_proj_config}'
        )
        sys.exit(1)

    db_info = add_proj_config['build_db']
    db_required_keys = ['db_uri', 'username', 'password']

    if any(key not in db_info for key in db_required_keys):
        print(
            f'One of the following DB keys is missing in the config file:\n'
            f'    {", ".join(db_required_keys)}'
        )
        sys.exit(1)

    repo_info = add_proj_config['repos']
    repo_required_keys = ['manifest_dir', 'manifest_url', 'repo_basedir']

    if any(key not in repo_info for key in repo_required_keys):
        print(
            f'One of the following repo keys is missing in the '
            f'config file:\n    {", ".join(repo_required_keys)}'
        )
        sys.exit(1)

    # Now run through all the manifests in build-manifests and update
    # the database with new project documents
    add_projects = AddProject(db_info, repo_info)
    last_manifest = []  # Start from beginning
    manifest_repo = repo_info['manifest_dir']

    print('Checking out/updating the build-manifests repo...')
    cbutil_git.checkout_repo(manifest_repo, repo_info['manifest_url'])

    manifest_walker = cbutil_git.ManifestWalker(manifest_repo, last_manifest)

    for commit_info, manifest_xml in manifest_walker.walk():
        try:
            manifest_info = add_projects.get_manifest_info(manifest_xml)
        except mf_parse.InvalidManifest as exc:
            # If the file is not an XML file, simply move to next one
            print(f'{commit_info[0]}: {exc}, skipping...')
            continue

        add_projects.update_project_documents(manifest_info)


if __name__ == '__main__':
    main()
