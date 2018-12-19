"""
Module for changeset endpoint
"""

import json

from cornice.resource import resource
from pyramid.httpexceptions import (
    HTTPBadRequest, HTTPNotFound, HTTPMethodNotAllowed
)

from .cors import CORS_POLICY
from .urls import ALL_URLS
from .util.db import BuildInfo
from .util.build_diff import BuildDiff


@resource(collection_path=ALL_URLS['changeset_collection'],
          path=ALL_URLS['changeset'],
          cors_policy=CORS_POLICY)
class ChangeSet:
    """
    Handle the 'changeset' endpoint
    """

    def __init__(self, request, context=None):
        """Basic initialization"""

        self.request = request
        self.build_info = BuildInfo(self.request.db)

    def collection_get(self):
        """
        Acquire all existing changesets, which doesn't have
        any useful logical definition, so we don't support it
        """

        return HTTPMethodNotAllowed(
            f'Endpoint {self.request.path} not supported'
        )

    def get(self):
        """
        Acquire specific changeset
        """

        md = self.request.matchdict

        if self.request.params:
            param_keys = list(self.request.params.keys())

            if 'from' not in param_keys or 'to' not in param_keys:
                return HTTPBadRequest(
                    f'Endpoint {self.request.path} must contain both '
                    f'"from" and "to" parameters in the query string'
                )

            try:
                differ = BuildDiff(
                    self.request.db, md['product_name'],
                    self.request.params['from'], self.request.params['to'],
                    self.request.repo_dir
                )
            except:  # TODO: give specific exceptions here
                return HTTPNotFound(
                    f'Invalid query string "{self.request.query_string}"'
                )
        else:
            return HTTPBadRequest(
                f'Endpoint {self.request.path} requires a query string'
            )

        return differ.get_diff()
