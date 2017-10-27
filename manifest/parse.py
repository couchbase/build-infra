"""
Parse a given manifest file and return the full contents in a well
structured dictionary.
"""

from collections import defaultdict

from lxml import etree


class InvalidManifest(Exception):
    pass


class Manifest:
    """
    Methods for parsing manifests as well as being able to validate
    manifests and return a structured dictionary of the data contained
    within one
    """

    def __init__(self, manifest, is_bytes=False, fail_on_invalid=True):
        """Basic initialization"""

        self.manifest = manifest
        self.is_bytes = is_bytes
        self.fail_on_invalid = fail_on_invalid

        self.data = None
        self.tree = None

        self.remotes = None
        self.projects = None
        self.defaults = None

    @staticmethod
    def generate_data_dict(element_dict):
        """
        Generate dictionary for a given element based on attributes
        gathered from the element
        """

        return {
            attr: value for attr, value in element_dict.items()
            if value is not None
        }

    @staticmethod
    def create_annotation_dict(child):
        """Generate dictionary from an annotation element"""

        attrs = ['name', 'value', 'keep']
        values = [child.get(attr) for attr in attrs]

        if values[1].startswith('@'):
            return None   # Ignore template value elements

        # Minor hack to ensure keep is set in build manifests
        if values[-1] is None:
            values[-1] = 'true'

        if None in values:
            raise InvalidManifest(
                'Missing required attribute in annotation element'
            )

        return dict(zip(attrs, values))

    @staticmethod
    def create_copyfile_dict(child):
        """Generate dictionary from a copyfile element"""

        attrs = ['src', 'dest']
        values = [child.get(attr) for attr in attrs]

        if None in values:
            raise InvalidManifest(
                'Missing required attribute in copyfile element'
            )

        return dict(zip(attrs, values))

    def find_remotes(self):
        """
        Determine the Git remotes used by the projects defined within
        the manifest

        Remote entries are of the form:
            <remote name="rem" fetch="<git or ssh URL>" \
                [review="<review URL>"] />

        Remotes may not be duplicated (based on name)
        """

        attrs = ['name', 'fetch', 'review']
        remotes = dict()

        for remote in self.tree.findall('remote'):
            values = [remote.get(attr) for attr in attrs]
            remote_dict = dict(zip(attrs, values))
            remote_name = remote_dict.pop('name')

            if remote_name is None or remote_dict['fetch'] is None:
                if self.fail_on_invalid:
                    raise InvalidManifest(
                        'Remote entry missing "name" or "fetch" attribute'
                    )
                else:
                    continue

            if remote_name in remotes:
                raise InvalidManifest(
                    'Remote entry duplicates previous remote entry'
                )

            remotes[remote_name] = self.generate_data_dict(remote_dict)

        self.remotes = remotes

    def find_defaults(self):
        """
        Determine the defaults to be used by the projects defined
        within the manifest

        The default entry is of the form:
            <default [remote="<existing remote name>"]
                     [revision="<branch>"]
                     [...]
            />

        We currently only are concerned with the 'remote' and 'revision'
        entries.  There should be only one 'default' element.
        """

        defaults = self.tree.findall('default')
        default_remote = None
        default_revision = None

        if len(defaults) > 1 and self.fail_on_invalid:
            raise InvalidManifest(
                'More than one default entry, must be unique'
            )

        try:
            default_remote = defaults[-1].get('remote')
            default_revision = defaults[-1].get('revision', 'master')
        except IndexError:
            pass   # Leave defaults to None

        self.defaults = {
            'remote': default_remote, 'revision': default_revision
        }

    def find_projects(self):
        """
        Determine the projects defined for the product represented
        within the manifest

        Usual project entries are of the form:
            <project name="proj" [remote="<remote>"] [revision="<revision>"] \
                [path="<path>"] [groups="<group1[,group2[...]]>" />

        with extended entries that currently contain several of either
        of the two following forms:
            <annotation name="anno" value="<value>" keep="true" />
            <copyfile src="<source file>" dest="<destination file>" />

        Multiple occurrences of projects may occur as long as the 'path'
        element is different for each occurrence
        """

        attrs = ['name', 'remote', 'revision', 'path', 'groups', 'upstream']
        projects = defaultdict(list)

        for project in self.tree.findall('project'):
            values = [project.get(attr) for attr in attrs]
            project_dict = dict(zip(attrs, values))
            project_name = project_dict.pop('name')

            if project_dict['groups'] is not None:
                project_dict['groups'] = project_dict['groups'].split(',')

            if project_name is None:
                if self.fail_on_invalid:
                    raise InvalidManifest(
                        'Project entry missing "name" attribute'
                    )
                else:
                    continue

            if project_name in projects:
                paths = [
                    p_attr['path'] for name, p_attrs in projects.items()
                    for p_attr in p_attrs if name == project_name
                ]

                if project_dict['path'] in paths:
                    raise InvalidManifest(
                        'Duplicate project entry with matching "name" '
                        'and "path" attributes'
                    )

            children = project.getchildren()
            if children:
                for child in children:
                    subelement = child.tag

                    # Only run the following if the element tag
                    # is a string (avoids comments)
                    if isinstance(subelement, str):
                        subdict = getattr(
                            self, 'create_{}_dict'.format(subelement)
                        )(child)

                        if subdict is not None:
                            project_dict.setdefault(subelement, []).append(
                                subdict
                            )

            projects[project_name].append(
                self.generate_data_dict(project_dict)
            )

        self.projects = projects

    def generate_manifest_dict(self):
        """
        Generate dictionary that represents the manifest

        The single key at the top is a generated string of the form
            PRODUCT-VERSION-BLD_NUM
        and the value is a dictionary containing the collected data
        from the manifest
        """

        annotations = dict()

        if 'build' in self.projects:
            for annotation in self.projects['build'][0].get('annotation', []):
                annotations[annotation['name']] = annotation['value']

        product = annotations.get('PRODUCT', 'unknown')
        version = annotations.get('VERSION', 'unknown')
        bld_num = annotations.get('BLD_NUM', '9999')
        manifest_name = '{}-{}-{}'.format(product, version, bld_num)

        return {
            manifest_name: {
                'remotes': self.remotes,
                'defaults': self.defaults,
                'projects': self.projects
            }
        }

    def parse_data(self):
        """
        Extract the key information from the manifest and return
        a dictionary containing the data in a useful, structured
        format
        """

        if self.is_bytes:
            self.data = etree.XML(self.manifest)
        else:
            with open(self.manifest) as fh:
                self.data = etree.XML(fh.read().encode())

        self.tree = etree.ElementTree(self.data)

        self.find_remotes()
        self.find_defaults()
        self.find_projects()

        return self.generate_manifest_dict()
