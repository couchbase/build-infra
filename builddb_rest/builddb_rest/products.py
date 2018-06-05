"""
Module for product endpoints
"""

from cornice.resource import resource

from .urls import ALL_URLS
from .util.db import BuildInfo


@resource(collection_path=ALL_URLS['product_collection'],
          path=ALL_URLS['product'])
class Products:
    """
    Handle the 'products' endpoints
    """

    def __init__(self, request, context=None):
        """Basic initialization"""

        self.request = request
        self.build_info = BuildInfo(self.request.db)

    def collection_get(self):
        """Acquire all existing products"""

        return {'products': self.build_info.get_products()}

    def get(self):
        """
        Acquire specific product; currently just returns
        the name of the product
        """

        return {'product': self.request.matchdict['product_name']}
