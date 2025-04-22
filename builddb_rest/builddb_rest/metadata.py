"""
Module for metadata endpoints
"""

from cornice.resource import resource
from pyramid.httpexceptions import HTTPNotFound

import cbbuild.database.db as cbutil_db

from .cors import CORS_POLICY
from .urls import ALL_URLS
from .util.db import BuildInfo


class InvalidRequestError(Exception):
    """Custom exception for handling bad requests"""

    pass


class MetadataBase:
    """Core class with several common methods for use for build endpoints"""

    @staticmethod
    def validate_metadata(metadata, product, metadata_keys):
        """Ensure list of keys for metadata update are allowed"""

        valid_keys = set()

        data = metadata.get('All-Products')
        if data is not None:
            valid_keys.update(
                [d['key'] for d in data['whitelist'] if 'key' in d]
            )

        data = metadata.get(product)
        if data is not None:
            valid_keys.update(
                [d['key'] for d in data['whitelist'] if 'key' in d]
            )

        for md_key in metadata_keys:
            if md_key not in valid_keys:
                raise InvalidRequestError(
                    f'Key {md_key} not an allowed metadata key '
                    f'for product {product}'
                )

    @staticmethod
    def get_build_data(db_conn, build_doc):
        """
        Acquire a build document from the database

        This method purposefully doesn't throw an exception for missing
        documents, but returns None
        """

        try:
            result = db_conn.get_document(build_doc)
        except cbutil_db.NotFoundError:
            return None
        else:
            return result

    def update_metadata(self, db_conn, build_doc, new_data):
        """
        Update a given build document's metadata with new/updated values

        For when the document is not found, return None
        """

        build_data = self.get_build_data(db_conn, build_doc)

        if build_data is None:
            return None

        if build_data.get('metadata') is None:
            build_data['metadata'] = new_data
        else:
            build_data['metadata'].update(new_data)

        return build_data

    def remove_metadata(self, db_conn, build_doc, entries):
        """
        Update a given build document's metadata so that certain entries
        have been removed

        For when the document is not found, return None

        Ignore any requested entries that aren't in the metadata
        """

        build_data = self.get_build_data(db_conn, build_doc)

        if build_data is None:
            return None

        if build_data.get('metadata') is not None:
            for entry in entries:
                build_data['metadata'].pop(entry, None)

        return build_data


@resource(collection_path=ALL_URLS['metadata_collection'],
          path=ALL_URLS['metadata'],
          cors_policy=CORS_POLICY)
class Metadata(MetadataBase):
    """
    Handle the 'metadata' endpoints (fully qualified REST path)
    """

    def __init__(self, request, context=None):
        """Basic initialization"""

        self.request = request
        self.build_info = BuildInfo(self.request.db)

    def collection_get(self):
        """
        Acquire all existing metadata of a given build
        """

        md = self.request.matchdict
        build_doc = \
            f"{md['product_name']}-{md['product_version']}-{md['build_num']}"

        result = self.get_build_data(self.request.db, build_doc)

        if result is None:
            return HTTPNotFound(f'Document {build_doc} not found')

        return {'data': result.get('metadata', {})}

    def get(self):
        """
        Acquire specific entry from metadata for a given build
        """

        md = self.request.matchdict
        build_doc = \
            f"{md['product_name']}-{md['product_version']}-{md['build_num']}"

        result = self.get_build_data(self.request.db, build_doc)

        if result is None:
            return HTTPNotFound(f'Document {build_doc} not found')

        return {
            'data': result.get('metadata', {}).get(md['metadata_entry'], None)
        }

    def collection_post(self):
        """
        Update the metadata for a given build with the requested new entries
        """

        data = self.request.json_body

        md = self.request.matchdict

        # Ensure only 'whitelisted' keys for the metadata
        # are being used
        try:
            self.validate_metadata(
                self.request.prod_metadata, md['product_name'], data.keys()
            )
        except InvalidRequestError as exc:
            return HTTPNotFound(exc)

        build_doc = \
            f"{md['product_name']}-{md['product_version']}-{md['build_num']}"

        build_data = self.update_metadata(self.request.db, build_doc, data)

        if build_data is None:
            return HTTPNotFound(f'Document {build_doc} not found')

        self.build_info.db.upsert_documents({build_doc: build_data})

        return {'status': 'ok'}

    def collection_delete(self):
        """
        Remove requested entries from the metadata of a given build
        """

        data = self.request.json_body

        md = self.request.matchdict
        build_doc = \
            f"{md['product_name']}-{md['product_version']}-{md['build_num']}"

        build_data = self.remove_metadata(self.request.db, build_doc, data)

        if build_data is None:
            return HTTPNotFound(f'Document {build_doc} not found')

        self.build_info.db.upsert_documents({build_doc: build_data})

        return {'status': 'ok'}

    def delete(self):
        """
        Remove entry given in endpoint from the metadata of a given build
        """

        md = self.request.matchdict
        build_doc = \
            f"{md['product_name']}-{md['product_version']}-{md['build_num']}"

        build_data = self.remove_metadata(
            self.request.db, build_doc, [md['metadata_entry']]
        )

        if build_data is None:
            return HTTPNotFound(f'Document {build_doc} not found')

        self.build_info.db.upsert_documents({build_doc: build_data})

        return {'status': 'ok'}


@resource(collection_path=ALL_URLS['metadata_alt_collection'],
          path=ALL_URLS['metadata_alt'],
          cors_policy=CORS_POLICY)
class MetadataAlt(MetadataBase):
    """
    Handle the 'metadata' endpoints (concise REST path)
    """

    def __init__(self, request, context=None):
        """Basic initialization"""

        self.request = request
        self.build_info = BuildInfo(self.request.db)

    def collection_get(self):
        """
        Acquire all existing metadata of a given build
        """

        md = self.request.matchdict
        build_doc = md['build_key']

        result = self.get_build_data(self.request.db, build_doc)

        if result is None:
            return HTTPNotFound(f'Document {build_doc} not found')

        return {'data': result.get('metadata', {})}

    def get(self):
        """
        Acquire specific entry from metadata for a given build
        """

        md = self.request.matchdict
        build_doc = md['build_key']

        result = self.get_build_data(self.request.db, build_doc)

        if result is None:
            return HTTPNotFound(f'Document {build_doc} not found')

        return {
            'data': result.get('metadata', {}).get(md['metadata_entry'], None)
        }

    def collection_post(self):
        """
        Update the metadata for a given build with the requested new entries
        """

        data = self.request.json_body

        md = self.request.matchdict
        build_doc = md['build_key']

        # Ensure only 'whitelisted' keys for the metadata
        # are being used
        try:
            self.validate_metadata(
                self.request.prod_metadata, build_doc.rsplit('-', 2)[0],
                data.keys()
            )
        except InvalidRequestError as exc:
            return HTTPNotFound(exc)

        build_data = self.update_metadata(self.request.db, build_doc, data)

        if build_data is None:
            return HTTPNotFound(f'Document {build_doc} not found')

        self.build_info.db.upsert_documents({build_doc: build_data})

        return {'status': 'ok'}

    def collection_delete(self):
        """
        Remove requested entries from the metadata of a given build
        """

        data = self.request.json_body

        md = self.request.matchdict
        build_doc = md['build_key']

        build_data = self.remove_metadata(self.request.db, build_doc, data)

        if build_data is None:
            return HTTPNotFound(f'Document {build_doc} not found')

        self.build_info.db.upsert_documents({build_doc: build_data})

        return {'status': 'ok'}

    def delete(self):
        """
        Remove entry given in endpoint from the metadata of a given build
        """

        md = self.request.matchdict
        build_doc = md['build_key']

        build_data = self.remove_metadata(
            self.request.db, build_doc, [md['metadata_entry']]
        )

        if build_data is None:
            return HTTPNotFound(f'Document {build_doc} not found')

        self.build_info.db.upsert_documents({build_doc: build_data})

        return {'status': 'ok'}
