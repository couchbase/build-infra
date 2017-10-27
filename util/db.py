"""
Collection of classes and methods to work with Couchbase Server via
the Python API
"""

import couchbase.bucket
import couchbase.exceptions


class NotFoundError(Exception):
    """Module-level exception for missing keys in database"""

    pass


class CouchbaseDB:
    """
    Manage connection and access to a Couchbase Server database,
    with some specific methods for the build database (dealing
    with the product-version index key)
    """

    def __init__(self, db_info):
        """Set up connection to desired Couchbase Server bucket"""

        self.bucket = couchbase.bucket.Bucket(
            db_info['db_uri'], username=db_info['username'],
            password=db_info['password']
        )

    def get_document(self, key):
        """Retrieve the document with the given key"""

        try:
            return self.bucket.get(key).value
        except couchbase.exceptions.NotFoundError:
            raise NotFoundError(f'Unable to find key "{key}" in database')

    def get_product_version_index(self):
        """
        Retrieve the product-version index, returning an empty dict
        if it doesn't already exist
        """

        try:
            return self.bucket.get('product-version-index').value
        except couchbase.exceptions.NotFoundError:
            return dict()

    def upsert_documents(self, data):
        """Do bulk insert/update of a set of documents"""

        try:
            self.bucket.upsert_multi(data)
        except couchbase.exceptions.CouchbaseError as exc:
            print(f'Unable to insert/update data: {exc.message}')

    def key_in_db(self, key):
        """Simple test for checking if a given key is in the database"""

        try:
            self.bucket.get(key)
            return True
        except couchbase.exceptions.NotFoundError:
            return False

    def update_product_version_index(self, prod_ver_index):
        """Update the product-version index entry"""

        self.upsert_documents({'product-version-index': prod_ver_index})
