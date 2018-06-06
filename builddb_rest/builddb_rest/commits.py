"""
Module for commit endpoints
"""

from cornice.resource import resource

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
    'project': {},
    'sha': {},
    'new_in_build': {'src': 'in_build', 'href': 'generate_builds'},
    'author': {},
    'committer': {},
    'summary': {},
    'timestamp': {},
    'remote': {},
}


class CommitBase:
    """Core class with several common methods for use for commit endpoints"""

    @staticmethod
    def generate_href(ref_type, key):
        """
        Generate REST endpoint for a given key; currently only handles
        the 'short' (concise) version of the endpoint
        """

        return f'/v1/{ref_type}s/{key}'

    def generate_key(self, key):
        """Generate REST endpoint for a given commit key"""

        return self.generate_href('commit', key)

    def generate_builds(self, builds):
        """
        Generate expanded build set that includes REST endpoints
        for each of the builds given
        """

        return [
            dict(key=build, href=self.generate_href('build', build))
            for build in builds
        ]

    def filter_data(self, result):
        """
        Generate new data set for a given commit endpoint which
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


@resource(collection_path=ALL_URLS['commit_collection'],
          path=ALL_URLS['commit'],
          cors_policy=CORS_POLICY)
class Commit(CommitBase):
    """
    Handle the 'commits' endpoints (fully qualified REST path)
    """

    def __init__(self, request, context=None):
        """Basic initialization"""

        self.request = request
        self.build_info = BuildInfo(self.request.db)

    def collection_get(self):
        """
        Acquire all existing commits for a given project -
        currently NOT supported as it would return ALL commit
        information for the project from the database (which
        isn't useful)
        """

        return {'commits': 'Endpoint not supported'}

    def get(self):
        """
        Acquire specific commit; returns a modified set of the data
        from the database
        """

        md = self.request.matchdict
        commit_doc = f"{md['project_name']}-{md['commit_sha']}"
        result = self.request.db.get_document(commit_doc)

        return self.filter_data(result)


@resource(collection_path=ALL_URLS['commit_alt_collection'],
          path=ALL_URLS['commit_alt'],
          cors_policy=CORS_POLICY)
class CommitAlt(CommitBase):
    """
    Handle the 'commits' endpoints (concise REST path)
    """

    def __init__(self, request, context=None):
        """Basic initialization"""

        self.request = request
        self.build_info = BuildInfo(self.request.db)

    @staticmethod
    def collection_get():
        """
        Acquire all existing commits - currently NOT supported
        as it would return ALL commit information from the
        database (which isn't useful)
        """

        return {'commits': 'Endpoint not supported'}

    def get(self):
        """
        Acquire specific commit; returns a modified set of the data
        from the database
        """

        commit_doc = self.request.matchdict['commit_key']
        result = self.request.db.get_document(commit_doc)

        return self.filter_data(result)
