"""
Module for project endpoints
"""

from cornice.resource import resource

from .cors import CORS_POLICY
from .urls import ALL_URLS
from .util.db import BuildInfo


@resource(collection_path=ALL_URLS['project_collection'],
          path=ALL_URLS['project'],
          cors_policy=CORS_POLICY)
class Projects:
    """
    Handle the 'projects' endpoints
    """

    def __init__(self, request, context=None):
        """Basic initialization"""

        self.request = request
        self.build_info = BuildInfo(self.request.db)

    def collection_get(self):
        """Acquire all existing projects"""

        return {'projects': self.build_info.get_projects()}

    def get(self):
        """
        Acquire specific project; currently just returns
        the name of the project
        """

        return {'project': self.request.matchdict['project_name']}
