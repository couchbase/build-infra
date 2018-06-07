"""
Module for build endpoints
"""

from cornice.resource import resource
from pyramid.httpexceptions import HTTPNotFound, HTTPMethodNotAllowed

import cbbuild.cbutil.db as cbutil_db

from .cors import CORS_POLICY
from .urls import ALL_URLS
from .util.db import BuildInfo

# Set of keys to return for build-specific endpoints;
# for each key, two optional settings can exist:
#   - 'src', which gives the name of the actual key in the database
#   - 'href', which refers to a method to generate target endpoints
#     to be used for further information
FILTER_KEYS = {
    'type': {},
    'key': {'src': 'key_'},
    'href': {'src': 'key_', 'href': 'generate_key'},
    'manifest': {'href': 'generate_manifest'},
    'product': {},
    'release': {},
    'version': {},
    'build_num': {},
    'prev_build_num': {},
    'new_commits': {'src': 'commits', 'href': 'generate_commits'},
    'timestamp': {},
    'download_url': {},
}


class BuildBase:
    """Core class with several common methods for use for build endpoints"""

    @staticmethod
    def generate_href(ref_type, key):
        """
        Generate REST endpoint for a given key; currently only handles
        the 'short' (concise) version of the endpoint
        """

        return f'/v1/{ref_type}s/{key}'

    def generate_key(self, key):
        """Generate REST endpoint for a given build key"""

        return self.generate_href('build', key)

    def generate_manifest(self, manifest):
        """
        Generate expanded manifest that includes REST endpoints
        for each of the SHAs for the projects
        """

        new_manifest = dict()

        for project, shas in manifest.items():
            new_manifest[project] = [
                dict(key=sha, href=self.generate_href('commit', sha))
                for sha in shas
            ]

        return new_manifest

    def generate_commits(self, commits):
        """
        Generate expanded commit key that includes REST endpoints
        for each commit
        """

        return [
            dict(key=commit, href=self.generate_href('commit', commit))
            for commit in commits
        ]

    def filter_data(self, result):
        """
        Generate new data set for a given build endpoint which
        consists of the keys in FILTER_KEYS along with any further
        information requested (additional endpoints from 'href'
        entries)
        """

        filtered_dict = dict()

        for new_key, opts in FILTER_KEYS.items():
            # New key might be a rename of an existing key, be sure
            # to access the correct key for information
            old_key = new_key if 'src' not in opts else opts['src']

            if 'href' in opts:
                # Additional information desired, run specific
                # base method to acquire
                filtered_dict[new_key] = (
                    getattr(self, opts['href'])(result[old_key])
                )
            else:
                filtered_dict[new_key] = result[old_key]

        return filtered_dict


@resource(collection_path=ALL_URLS['build_collection'],
          path=ALL_URLS['build'],
          cors_policy=CORS_POLICY)
class Build(BuildBase):
    """
    Handle the 'builds' endpoints (fully qualified REST path)
    """

    def __init__(self, request, context=None):
        """Basic initialization"""

        self.request = request
        self.build_info = BuildInfo(self.request.db)

    def collection_get(self):
        """
        Acquire all existing builds of a given version/release
        of a product
        """

        return {
            'builds': self.build_info.get_builds(
                self.request.matchdict['product_name'],
                self.request.matchdict['release_name'],
                self.request.matchdict['product_version']
            )
        }

    def get(self):
        """
        Acquire specific build; returns a modified set of the data
        from the database
        """

        md = self.request.matchdict
        build_doc = \
            f"{md['product_name']}-{md['product_version']}-{md['build_num']}"

        try:
            result = self.request.db.get_document(build_doc)
        except cbutil_db.NotFoundError:
            return HTTPNotFound(f'Document {build_doc} not found')

        return self.filter_data(result)


@resource(collection_path=ALL_URLS['build_alt_collection'],
          path=ALL_URLS['build_alt'],
          cors_policy=CORS_POLICY)
class BuildAlt(BuildBase):
    """
    Handle the 'builds' endpoints (concise REST path)
    """

    def __init__(self, request, context=None):
        """Basic initialization"""

        self.request = request
        self.build_info = BuildInfo(self.request.db)

    def collection_get(self):
        """
        Acquire all existing builds - currently NOT supported
        as it would return ALL build information from the
        database (which isn't useful)
        """

        return HTTPMethodNotAllowed(
            f'Endpoint {self.request.path} not supported'
        )

    def get(self):
        """
        Acquire specific build; returns a modified set of the data
        from the database
        """

        build_doc = self.request.matchdict['build_key']

        try:
            result = self.request.db.get_document(build_doc)
        except cbutil_db.NotFoundError:
            return HTTPNotFound(f'Document {build_doc} not found')

        return self.filter_data(result)
