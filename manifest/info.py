"""
Common functions to extract key pieces of data from the dictionary
form of a manifest file.  This module only operates on the information
within a manifest itself, not derived information.
"""

from collections import defaultdict, namedtuple


class ManifestInfo:
    """"""

    def __init__(self, manifest_data):
        """Initial setup of manifest object"""

        self.name = list(manifest_data)[0]
        self.manifest_data = manifest_data[self.name]
        self.remotes = self.store_remotes()
        self.defaults = self.store_defaults()
        self.projects = self.store_projects()

    def store_remotes(self):
        """
        Organize remotes information. Uses namedtuples for easy access
        """

        remotes = dict()

        RemoteEntry = namedtuple('RemoteEntry', ['name', 'fetch', 'review'])
        remote_info = self.manifest_data['remotes']

        for remote, remote_data in remote_info.items():
            remotes[remote] = RemoteEntry(
                remote, remote_data['fetch'], remote_data.get('review')
            )

        return remotes

    def store_defaults(self):
        """
        Organize defaults information.  Uses a namedtuple for easy access
        """

        DefaultEntry = namedtuple(
            'DefaultEntry', ['remote', 'revision']
        )
        default_info = self.manifest_data['defaults']

        defaults = DefaultEntry(
            default_info['remote'], default_info['revision']
        )

        return defaults

    def store_projects(self):
        """
        Organize projects information, handling partial information
        properly.  Uses namedtuples for easy access
        """

        projects = defaultdict(list)

        ProjectEntry = namedtuple(
            'ProjectEntry', ['name', 'path', 'remote', 'revision', 'group',
                             'upstream', 'annotation', 'copyfile']
        )
        AnnotationEntry = namedtuple(
            'AnnotationEntry', ['name', 'value', 'keep']
        )
        CopyFileEntry = namedtuple('CopyFileEntry', ['src', 'dest'])

        project_info = self.manifest_data['projects']

        for project, project_data_list in project_info.items():
            for project_data in project_data_list:
                project_data['name'] = project

                if project_data.get('annotation'):
                    annotations = project_data['annotation']
                    project_data['annotation'] = [
                        AnnotationEntry(**annotation)
                        for annotation in annotations
                    ]
                else:
                    project_data['annotation'] = None

                if project_data.get('copyfile'):
                    copyfiles = project_data['copyfile']
                    project_data['copyfile'] = [
                        CopyFileEntry(**copyfile) for copyfile in copyfiles
                    ]
                else:
                    project_data['copyfile'] = None

                projects[project].append(ProjectEntry(
                    **{field: project_data.get(field)
                       for field in ProjectEntry._fields}
                ))

        return projects

    def get_projects(self):
        """Retrieve the name of all projects for the manifest"""

        return self.projects.keys()

    def get_project_remote_info(self, project):
        """
        Retrieve the Git remote name and URL for a given project
        in the manifest
        """

        remote = self.projects[project][0].remote or self.defaults.remote
        remote_url = self.remotes[remote].fetch

        if remote_url.endswith('/'):
            repo_url = f'{remote_url}{project}.git'
        else:
            repo_url = f'{remote_url}/{project}.git'

        return remote, repo_url

    def get_project_shas(self, project):
        """Retrieve the SHA values for a given project in the manifest"""

        return [entry.revision for entry in self.projects[project]]

    def get_release_info(self):
        """
        Return release information from the build project in the manifest;
        currently uses random defaults to return if key annotations
        are not available
        """

        build_project = self.projects['build'][0]

        if build_project.annotation:
            annotations = {
                anno.name: anno.value for anno in build_project.annotation
            }
        else:
            annotations = dict()

        return (annotations.get('PRODUCT', 'unknown'),
                annotations.get('RELEASE', 'unknown'),
                annotations.get('VERSION', '0.0.0'),
                annotations.get('BLD_NUM', '9999'))
