import argparse
import configparser
import json
import logging
import sys

from flask import Flask, request
from flask.json import jsonify

from build_database.tools.build_diff import BuildDiff

# Necessary globals
app = Flask(__name__)
db_info = None
repos_info = None

@app.route('/changelog', methods=['GET'])
def changelog():
    product = request.args.get('product', 'couchbase-server')
    frm = request.args.get('from')
    to = request.args.get('to')
    differ = BuildDiff(db_info, product, frm, to, repos_info['repo_basedir'])
    return jsonify(differ.get_diff())

def main():
    parser = argparse.ArgumentParser(
        description='REST API server for Build Database'
    )
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Enable debugging output')
    parser.add_argument('-c', '--config', dest='db_repo_configfile',
                        help='Configuration file for build database',
                        default='build_db_conf.ini')
    args = parser.parse_args()

    # Set logging to debug level on stream handler if --debug was set
    if args.debug:
        app.logger.setLevel(logging.DEBUG)

    # Read database config file
    db_repo_config = configparser.ConfigParser()
    db_repo_config.read(args.db_repo_configfile)

    if 'build_db' not in db_repo_config:
        logger.error(
            f'Invalid or unable to read config file {args.db_repo_configfile}'
        )
        sys.exit(1)

    global db_info, repos_info
    db_info = db_repo_config['build_db']
    repos_info = db_repo_config['repos']

    app.run(debug=True, host='0.0.0.0', port=8383)

if __name__ == '__main__':
    main()
