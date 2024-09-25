#!/usr/bin/env python3

'''When a gerrit change is created or updated, update referenced Jira ticket'''

import argparse
import json
import logging
import os
import re
from pathlib import Path
from atlassian import Jira

# Custom Field identifier on https://couchbasecloud.atlassian.net/
GERRIT_CUSTOM_FIELD = 'customfield_11243'

def init_jira():
    '''Initialize jira session'''
    creds_file = str(Path.home()) + '/.ssh/jira-creds.json'
    jira_creds = json.loads(open(creds_file).read())
    jira = Jira(
        url=jira_creds['url'],
        username=jira_creds['username'],
        password=jira_creds['apitoken'],
        cloud=True)
    return jira


def get_tickets(commit_summary):
    '''Returns list of ticket IDs in the commit summary.'''
    ticket_re = re.compile(r'(\b[A-Z][A-Z0-9]+-\d+\b)')
    return ticket_re.findall(commit_summary)


def update_gerrit_reviews(issue, commit_summary,
                          change_url, project_name, branch_name, event_type):
    '''
    Produce Jira's Gerrit Review field information based on Gerrit review information:
        * create a new entry for new gerrit review
        * mark merged review with a checkbox
        * mark abandon review with a cross
        * remove review if it is deleted.
        * rmove cross if an abandon review is restored
    '''
    gerrit_reviews = issue['fields'][GERRIT_CUSTOM_FIELD]
    review_list = gerrit_reviews.split('\\\\') if gerrit_reviews else []
    commit_title = ' '.join(commit_summary.split(' ', 5)[:5])
    marker = ''

    if event_type == "change-deleted":
        # Remove entry if change is deleted
        new_review_list = [
            entry for entry in review_list if change_url not in entry]
    else:
        # Set marker based on event type
        if event_type == "change-merged":
            marker = '(/) '
        if event_type == "change-abandoned":
            marker = '(x) '
        new_gerrit_entry = f'{marker}[{commit_title}|{change_url}]\trepo:{project_name}\tbranch:{branch_name}'
        # Remove duplicates
        new_review_list = [
            entry for entry in review_list if change_url not in entry]
        new_review_list.append(new_gerrit_entry)  # Add new entry

    if not new_review_list:
        return

    updated_reviews = '\\\\'.join(new_review_list)
    gerrit_issue_field = {GERRIT_CUSTOM_FIELD: updated_reviews}

    return gerrit_issue_field


# Main
parser = argparse.ArgumentParser()
parser.add_argument('-e', '--event_type',
                    help='Gerrit Event Type', required=True)
parser.add_argument('-c', '--commit_summary',
                    help='GIT Commit Summary', required=True)
parser.add_argument('-u', '--change_url', help='GIT Change URL', required=True)
parser.add_argument('-b', '--branch_name', help='GIT Branch', required=True)
parser.add_argument('-p', '--project_name',
                    help='GIT Repository', required=True)

args = parser.parse_args()

gerrit_site_path = os.getenv('GERRIT_SITE')
logger = logging.getLogger('jira_hook')
logger.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
file_handler = logging.FileHandler(
    f'{gerrit_site_path}/logs/{args.event_type}.log')
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)

tickets = get_tickets(args.commit_summary)

if tickets:
    jira = init_jira()
    for ticket in tickets:
        try:
            issue = jira.issue(ticket)
        except BaseException:
            logger.info(f'{ticket} does not exist.')
            continue

        gerrit_field = update_gerrit_reviews(
            issue,
            args.commit_summary,
            args.change_url,
            args.project_name,
            args.branch_name,
            args.event_type)

        if gerrit_field:
            logger.info(f'Updating issue {ticket} for {args.change_url}')
            jira.update_issue_field(ticket, gerrit_field)
else:
    logger.info('No ticket info on the commit summary')
