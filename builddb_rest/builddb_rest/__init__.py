"""
Main entry point
"""

from pyramid.config import Configurator


def main(global_config, **settings):
    """Basic settings, including route prefix and database access"""

    config = Configurator(settings=settings)
    config.route_prefix = 'v1'
    config.include('cornice')
    config.include('builddb_rest.couch_db')
    config.scan()

    return config.make_wsgi_app()
