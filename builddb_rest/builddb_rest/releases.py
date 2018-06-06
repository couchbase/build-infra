"""
Module for release endpoints
"""

from cornice.resource import resource

from .cors import CORS_POLICY
from .urls import ALL_URLS
from .util.db import BuildInfo


@resource(collection_path=ALL_URLS['release_collection'],
          path=ALL_URLS['release'],
          cors_policy=CORS_POLICY)
class Releases:
    """
    Handle the 'releases' endpoints
    """

    def __init__(self, request, context=None):
        """Basic initialization"""

        self.request = request
        self.build_info = BuildInfo(self.request.db)

    def collection_get(self):
        """Acquire all existing releases for a given product"""

        return {
            'releases': self.build_info.get_releases(
                self.request.matchdict['product_name']
            )
        }

    def get(self):
        """
        Acquire specific release for a given product; currently
        just returns the names of the product and the release
        """

        return {
            'product': self.request.matchdict['product_name'],
            'release': self.request.matchdict['release_name'],
        }
