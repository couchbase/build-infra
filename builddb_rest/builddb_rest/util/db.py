"""
Utility methods to access build database for REST API
"""

from couchbase.n1ql import N1QLQuery


class BuildInfo:
    """
    Common set of methods with access to database connection to acquire
    key information from the build database
    """

    def __init__(self, db_conn):
        """Set up access for database connection"""

        self.db = db_conn

    def query_documents(self, doctype, where_clause=None, doc_keys=None,
                        distinct=False, limit=None, **kwargs):
        """
        Acquire all documents of a given type and create a generator
        to loop through them

        Allow for only specific keys to be retrieved from each document,
        along with a 'DISTINCT' option to be used (useful for getting a
        unique set of values for a given key)

        Pass everything *after* the DISTINCT, along with any additional
        optional named parameters which will be associated with $variables
        in the query string
        """

        select_str = 'DISTINCT' if distinct else ''

        if doc_keys is not None:
            select_str += (' ' + ', '.join(doc_keys))
        else:
            select_str += " *"

        q_string = (f"SELECT {select_str} FROM {self.db.bucket_name} "
                    f"where type='{doctype}'")

        if where_clause is not None:
            q_string += f' AND {where_clause}'

        if limit is not None:
            q_string += f' LIMIT {limit}'

        query = N1QLQuery(q_string, **kwargs)

        for row in self.db.bucket.n1ql_query(query):
            yield row

    def get_products(self):
        """Get a list of all available products"""

        results = self.query_documents(
            'build', where_clause='product IS NOT NULL',
            doc_keys=['product'], distinct=True
        )

        return [result['product'] for result in results]

    def get_releases(self, product):
        """Get a list of all available releases for a given product"""

        results = self.query_documents(
            'build',
            where_clause=f"product='{product}' and release IS NOT NULL",
            doc_keys=['release'], distinct=True
        )

        return [result['release'] for result in results]

    def get_versions(self, product, release):
        """
        Get a list of all available version for a given release
        of a product
        """

        results = self.query_documents(
            'build',
            where_clause=f"product='{product}' and release='{release}' "
                         f"and version IS NOT NULL",
            doc_keys=['version'], distinct=True
        )

        return [result['version'] for result in results]

    def get_builds(self, product, release, version):
        """
        Get a list of all available builds for a given version
        of a product (potentially release-specific)
        """

        results = self.query_documents(
            'build',
            where_clause=f"product='{product}' and release='{release}' "
                         f"and version='{version}' and build_num IS NOT NULL",
            doc_keys=['build_num'], distinct=True
        )

        return [result['build_num'] for result in results]

    def get_projects(self):
        """Get a list of all available projects"""

        results = self.query_documents(
            'commit', where_clause='project IS NOT NULL',
            doc_keys=['project'], distinct=True
        )

        return [result['project'] for result in results]

    def get_oses(self):
        """Get a list of all OSes in use for VMs"""

        results = self.query_documents(
            'vm', where_clause=f'os IS NOT NULL',
            doc_keys=['os'], distinct=True
        )

        return [result['os'] for result in results]

    def get_reservable_vms(self, reserve_os, count):
        """
        Get a list of VMs available for reservation for a given OS and count
        """

        results = self.query_documents(
            'vm', where_clause=f"os='{reserve_os}' AND (state='available' "
                               f"OR expires < CLOCK_MILLIS())",
            limit=count
        )

        return [result['build_info'] for result in results]

    def get_vm_by_ip(self, ip):
        """
        Get a VM entry keyed by IP
        """

        return self.db.get_document(ip)
