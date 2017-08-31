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
        self.remotes, self.default_remote = self.store_remotes()
        self.projects = self.store_projects()

    def store_remotes(self):
        """
        Organize remotes information, creating a special entry
        for the default remote. Uses namedtuples for easy access
        """

        remotes = dict()
        default_remote = None

        RemoteEntry = namedtuple('RemoteEntry', ['name', 'fetch', 'review'])
        DefaultRemoteEntry = namedtuple(
            'DefaultRemoteEntry', ['remote', 'revision']
        )

        remote_info = self.manifest_data['remotes']

        for remote, remote_data in remote_info.items():
            if remote == 'default':
                default_remote = DefaultRemoteEntry(
                    remote_data['remote'], remote_data['revision']
                )
            else:
                remotes[remote] = RemoteEntry(
                    remote, remote_data['fetch'], remote_data.get('review')
                )

        return remotes, default_remote

    def store_projects(self):
        """
        Organize projects information, handling partial information
        properly.  Uses namedtuples for easy access
        """

        projects = defaultdict(list)

        ProjectEntry = namedtuple(
            'ProjectEntry', ['name', 'path', 'remote', 'revision', 'group',
                             'upstream','annotation', 'copyfile']
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


def get_previous_build_num(build_num):
    """CURRENTLY NOT USED, DO NOT USE"""

    # NOTE: This is *so* not right, but will do for testing
    # purposes
    return build_num - 1
