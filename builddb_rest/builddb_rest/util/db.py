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
                        distinct=False, order_by=None, desc=False, limit=None,
                        **kwargs):
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

        if order_by is not None:
            q_string += f' ORDER BY {order_by}'

        if desc:
            q_string += f' DESC'

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

    def get_versions(self, product, release=None):
        """
        Get a list of all available versions for a given release
        of a product

        release is an optional argument, all versions of a product are returned
        if it is not provided
        """

        release_clause = f" and release='{release}'" if release else ""
        results = self.query_documents(
            'build',
            where_clause=f"product='{product}' {release_clause} and version IS NOT NULL",
            doc_keys=['version'], distinct=True
        )

        return [result['version'] for result in results]

    def get_builds(self, product, release=None, version=None):
        """
        Get a list of all available builds for a given version
        of a product (potentially release-specific)

        All versions of a product are returned if a release is not specified.
        Version should always be provided, but is given a default value of None
        to avoid the syntax error of a non-default arg following a default arg
        """

        assert version != None, "Version must be specified"

        release_clause = f" and release='{release}'" if release else ""
        results = self.query_documents(
            'build',
            where_clause=f"product='{product}' {release_clause} and version='{version}' and build_num IS NOT NULL",
            doc_keys=['build_num'], distinct=True
        )

        return [result['build_num'] for result in results]

    def get_highest_release_build(self, product, release):
        """
        Get the build with the highest build number for a given release
        of a product
        """

        results = self.query_documents(
            'build',
            where_clause=f"product='{product}' and release='{release}' "
                         f"and build_num IS NOT NULL",
            doc_keys=['build_num'], order_by='build_num', desc=True, limit=1
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

    @staticmethod
    def check_missing(param):
        """Simple wrapper to check for a non-set parameter in database"""

        return f"ifmissingornull({param}, 'n/a')"

    def get_last_unit_sanity(self, product, release, version):
        """
        Find the most recent build from a given version of a product
        that unit tests were run on (regardless of success or failure)
        and where the sanity tests were successful
        """

        q_str = (f"product='{product}' and release='{release}' "
                 f"and version='{version}' "
                 f"and {self.check_missing('metadata.unit_test')}!='n/a' "
                 f"and {self.check_missing('metadata.builds_complete')}='complete' "
                 f"and {self.check_missing('metadata.sanity')}='pass'")

        results = self.query_documents(
            'build', where_clause=q_str, doc_keys=['build_num'],
            order_by='build_num', desc=True, limit=1
        )

        # Just return the build number, or 0 if none was found
        try:
            return list(results)[0]['build_num']
        except IndexError:
            return 0

    def get_last_complete(self, product, release, version):
        """
        Find the most recent build from a given version of a product
        that is "complete" (as per http://server.jenkins.couchbase.com/job/check_builds/)
        """

        q_str = (f"product='{product}' and release='{release}' "
                 f"and version='{version}' "
                 f"and {self.check_missing('metadata.builds_complete')}='complete'")

        results = self.query_documents(
            'build', where_clause=q_str, doc_keys=['build_num'],
            order_by='build_num', desc=True, limit=1
        )

        # Just return the build number, or 0 if none was found
        try:
            return list(results)[0]['build_num']
        except IndexError:
            return 0

    def get_last_qe(self, product, release, version):
        """
        Find the most recent build from a given version of a product
        that QE tests were run on (regardless of success or failure)
        """

        q_str = (f"product='{product}' and release='{release}' "
                 f"and version='{version}' "
                 f"and {self.check_missing('metadata.kickoff_qe')}!='n/a'")

        results = self.query_documents(
            'build', where_clause=q_str, doc_keys=['build_num'],
            order_by='build_num', desc=True, limit=1
        )

        # Just return the build number, or 0 if none was found
        try:
            return list(results)[0]['build_num']
        except IndexError:
            return 0
