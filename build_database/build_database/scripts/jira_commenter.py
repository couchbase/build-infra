"""
Program to read new builds from the build database and place comments
on relevant JIRA tickets for commits in those builds.
"""

import argparse
import configparser
import json
import logging
import re
import sys

import cbbuild.database.db as cbdatabase_db

from jira import JIRA
from jira.exceptions import JIRAError

# Set up logging and handler
logger = logging.getLogger('jira_commenter')
logger.setLevel(logging.INFO)

ch = logging.StreamHandler()
logger.addHandler(ch)


class JiraCommenter:

    def __init__(self, db_info, dryrun, cloud_creds_file):
        cloud_jira_creds = json.loads(open(cloud_creds_file).read())

        self.cloud_jira = JIRA(cloud_jira_creds['url'],
                               basic_auth=(f"{cloud_jira_creds['username']}",
                                           f"{cloud_jira_creds['apitoken']}"
                                           )
                               )

        self.db = cbdatabase_db.CouchbaseDB(db_info)
        self.dryrun = dryrun
        self.ticket_re = re.compile(r'(\b[A-Z][A-Z0-9]+-\d+\b)')
        self.extref_re = re.compile(
            r'^Ext-ref:(.*)$', flags=re.MULTILINE | re.IGNORECASE
        )


    def make_ticket_comments(self, commit, build):
        """
        Posts Jira comments on any ticket IDs named by commit, either in the
        subject line or in Ext-ref footer
        """

        # Find tickets named by commit subject (first line of message)
        subject = commit.summary.split('\n', 1)[0]
        for ticket in self.ticket_re.findall(subject):
            self.make_comment(ticket, commit, subject, build)

        # Find tickets named on Ext-ref: lines
        for extref_line in self.extref_re.findall(commit.summary):
            for ticket in self.ticket_re.findall(extref_line):
                self.make_comment(ticket, commit, subject, build)


    def make_comment(self, ticket, commit, subject, build):
        """
        Makes a comment on the specified ticket about the commit/build
        """

        # Exception: Don't bother with ASTERIXDB tickets since
        # they're on a different JIRA
        if ticket.startswith("ASTERIXDB"):
            logger.debug(f'Skipping ticket {ticket}')
            return

        try:
            jticket = self.cloud_jira.issue(ticket)
        except JIRAError as e:
            if e.status_code == 404:
                logger.info(
                    f"commit references non-existent ticket {ticket}")
            else:
                logger.warning(
                    f"error loading JIRA issue ticket {ticket}: {e.text}"
                )
            return
        org = commit.remote.split('/')[3]
        url = f'https://github.com/{org}/{commit.project}/commit/{commit.sha}'
        message = (
            f"Build {build.key} contains {commit.project} "
            f"commit [{commit.sha[0:7]}|{url}] with commit message:\n"
            f"{subject}"
        )

        if self.dryrun:
            logger.info(f'(Not) posting Jira comment on {ticket}:\n{message}')
            return
        self.cloud_jira.add_comment(jticket, message)
        logger.info(
            f'Posting Jira comment on {ticket} on cloud jira:\n{message}')


    def scan_and_comment(self):
        """
        Main entrypoint function - does all work
        """

        builds = self.db.query_documents(
            'build',
            where_clause="ifmissingornull(metadata.jira_comments, false)=false"
        )

        for build in builds:
            # Exception: Don't comment on 0.0.0 builds
            if build.version == '0.0.0':
                logger.debug(f'Skipping master build {build.key}')

            else:
                for commit_key in build.commits:
                    commit = self.db.get_commit(commit_key)

                    # Exception: Don't commit on testrunner commits
                    if commit.project == 'testrunner':
                        logger.debug(
                            f"Skipping testrunner commit {commit.sha}"
                        )
                        continue

                    self.make_ticket_comments(commit, build)

            if not self.dryrun:
                build.set_metadata('jira_comments', True)


def main():
    parser = argparse.ArgumentParser(
        description='Reads new builds and adds Jira comments'
    )
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Enable debugging output')
    parser.add_argument('-c', '--config', dest='db_repo_configfile',
                        help='Configuration file for build database loader',
                        default='build_db_conf.ini')
    parser.add_argument('--cloud-creds', type=str, required=True,
                        help='Credentials file for Couchbase Cloud Jira')
    parser.add_argument('-n', '--dryrun', action='store_true',
                        help="Don't change JIRA or Database, just log what "
                             "would be done")
    args = parser.parse_args()

    # Set logging to debug level on stream handler if --debug was set
    if args.debug:
        logger.setLevel(logging.DEBUG)

    # Read database config file
    db_repo_config = configparser.ConfigParser()
    db_repo_config.read(args.db_repo_configfile)

    if 'build_db' not in db_repo_config:
        logger.error(
            f'Invalid or unable to read config file {args.db_repo_configfile}'
        )
        sys.exit(1)

    db_info = db_repo_config['build_db']
    commenter = JiraCommenter(
        db_info, args.dryrun, args.cloud_creds
    )
    commenter.scan_and_comment()
