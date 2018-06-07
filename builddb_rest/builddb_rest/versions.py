"""
Module for version endpoints
"""

from cornice.resource import resource

from .cors import CORS_POLICY
from .urls import ALL_URLS
from .util.db import BuildInfo


@resource(collection_path=ALL_URLS['version_collection'],
          path=ALL_URLS['version'],
          cors_policy=CORS_POLICY)
class Version:
    """
    Handle the 'versions' endpoints
    """

    def __init__(self, request, context=None):
        """Basic initialization"""

        self.request = request
        self.build_info = BuildInfo(self.request.db)

    def collection_get(self):
        """
        Acquire all existing versions for given release
        of a product
        """

        return {
            'versions': self.build_info.get_versions(
                self.request.matchdict['product_name'],
                self.request.matchdict['release_name']
            )
        }

    def get(self):
        """
        Acquire specific version for a given release of
        a product; currently just returns the names of the
        product, release and version
        """

        return {
            'product': self.request.matchdict['product_name'],
            'release': self.request.matchdict['release_name'],
            'version': self.request.matchdict['product_version'],
        }
