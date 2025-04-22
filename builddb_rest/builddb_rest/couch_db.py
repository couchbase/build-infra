"""
Module to give access to build database connection via requests
in Cornice; yes, the method MUST be called 'includeme'
"""

import cbbuild.database.db as cbutil_db


def includeme(config):
    """
    Set up database connection and make it accessible to all
    requests generated via Cornice
    """

    settings = config.registry.settings

    # Store DB connection in registry
    db_info = {
        'db_uri': settings['builddb_uri'],
        'bucket': settings['builddb_bucket'],
        'username': settings['builddb_user'],
        'password': settings['builddb_pass'],
    }
    conn = cbutil_db.CouchbaseDB(db_info)
    settings['db_conn'] = conn

    # Make DB connection accessible as a request property
    def _get_db(request):
        _settings = request.registry.settings
        db = _settings['db_conn']

        return db

    config.add_request_method(_get_db, 'db', reify=True)
