"""
Basic script to ensure the health of various components of a Jenkins setup;
currently handled:

  - Jenkins slaves (online or offline)
  - Jenkins slaves (free diskspace)
  - Jenkins jobs (hung jobs)

More capability will be added as needed.
"""

import argparse
import datetime
import json
import logging
import pathlib
import smtplib
import sqlite3
import statistics
import sys
import time

from collections import defaultdict
from email.mime.text import MIMEText

import requests_xml


# Set up logging and handler
logger = logging.getLogger('jenkins_monitor.scripts.monitor_jenkins')
logger.setLevel(logging.INFO)

ch = logging.StreamHandler()
logger.addHandler(ch)


def adapt_datetime(ts):
    return time.mktime(ts.timetuple())


def send_email(smtp_server, receivers, message):
    """Simple method to send email"""

    msg = MIMEText(message['body'])

    msg['Subject'] = message['subject']
    msg['From'] = 'build-team@couchbase.com'
    msg['To'] = ', '.join(receivers)

    smtp = smtplib.SMTP(smtp_server, 25)

    try:
        smtp.sendmail(
            'build-team@couchbase.com', receivers, msg.as_string()
        )
    except smtplib.SMTPException as exc:
        logger.error('Mail server failure: %s', exc)
    finally:
        smtp.quit()


class JenkinsMonitor:
    """Handle basic Jenkins monitoring"""

    def __init__(self, email_info, server_info):
        """
        Basic initialization and loading of key information for all builds
        from Jenkins, along with preparing state database
        """

        self.smtp_server = email_info['smtp_server']
        self.receivers = email_info['receivers']

        self.server_name = server_info['name']
        self.server_url = f'http://{self.server_name}'
        self.user = server_info['user']
        self.passwd = server_info['passwd']

        self.session = requests_xml.XMLSession()

        sqlite3.register_adapter(datetime.datetime, adapt_datetime)
        db_file = pathlib.Path.home() / 'db' / 'monitoring.db'
        self.conn = sqlite3.connect(str(db_file))
        self.cursor = self.conn.cursor()
        self.initialize_db()

        try:
            self.builds, self.running = self.get_full_build_info()
        except (ConnectionError, ValueError) as exc:
            raise RuntimeError(exc)

    def initialize_db(self):
        """
        Create the 'slaves' and 'jobs' tables if they don't already
        exist in the database
        """

        self.cursor.execute(
            "select name from sqlite_master where type = 'table';"
        )
        tables = [row[0] for row in self.cursor.fetchall()]

        if 'slaves' not in tables:
            self.conn.execute(
                "create table slaves (server text, name text, type text, "
                "alert_since timestamp, checked int)"
            )

        if 'jobs' not in tables:
            self.conn.execute(
                "create table jobs (server text, name text, "
                "num int, checked int)"
            )

    def get_jenkins_data(self, url_path):
        """
        Acquire data from Jenkins for a given REST API request,
        returning data in JSON format
        """

        req = self.session.get(
            f'{self.server_url}{url_path}', auth=(self.user, self.passwd)
        )

        if not req.ok:
            raise ConnectionError(
                f'Request failure to {self.server_url} for the following '
                f'query path: {url_path}'
            )

        try:
            return json.loads(req.xml.json())
        except json.decoder.JSONDecodeError:
            raise ValueError(
                f'Bad input into JSON: {req.xml.json()}'
            )

    def get_full_build_info(self):
        """
        Acquire key build information for every build available
        in the Jenkins server's history, keeping track of current
        running jobs as well
        """

        job_list = self.get_jenkins_data(
            f'/api/xml?tree=jobs[displayName,builds[number,building,'
            f'timestamp,estimatedDuration,duration,url,result]]'
        )['hudson']['job']

        builds = dict()
        running = defaultdict(list)

        for job in job_list:
            job_name = job['displayName']['$']
            builds[job_name] = list()

            job_builds = job.get('build', [])

            if isinstance(job_builds, dict):
                job_builds = [job_builds]

            for job_build in job_builds:
                build_info = {
                    key: val['$'] for key, val in job_build.items()
                    if key != '@_class'
                }
                builds[job_name].append(build_info)

                if build_info['building']:
                    running[job_name].append(build_info)

        return builds, running

    def check_node_alert_time(self, node, alert_type):
        """
        Return time and number of checks for an node alert;
        return None if node was not alerted for alert_type before
        """

        self.cursor.execute(
            "select alert_since, checked from slaves where name=? "
            "and server=? and type=?", (node, self.server_name, alert_type)
        )
        res = self.cursor.fetchone()

        if res is None:
            return None

        now = datetime.datetime.now()

        return int(time.mktime(now.timetuple()) - res[0]), res[1]

    def add_node_alert(self, node, alert_type):
        """
        Add new node alert, setting number of times
        checked to 0 (not checked yet)
        """

        now = datetime.datetime.now()

        try:
            with self.conn:
                self.cursor.execute(
                    "insert into slaves values(?, ?, ?, ?, ?)",
                    (self.server_name, node, alert_type, now, 0)
                )
        except sqlite3.IntegrityError:
            raise RuntimeError(f'Node {node} already in slaves table')

    def update_node_alert(self, node, alert_type, checked):
        """
        Update an node alert with a new number of times checked
        """

        try:
            with self.conn:
                self.cursor.execute(
                    "update slaves set checked=? where name=? and server=? and type=?",
                    (checked, node, self.server_name, alert_type)
                )
        except sqlite3.IntegrityError as exc:
            raise RuntimeError(exc)

    def clear_node_alert(self, nodes, alert_type):
        """Remove any nodes that are no longer in alert state"""

        self.cursor.execute("select name from slaves where server=? and type=?",
                            (self.server_name, alert_type))

        for row in self.cursor.fetchall():
            node = row[0]

            if node not in nodes:
                logger.debug(
                    f'Remove node {node} from database'
                )

                try:
                    with self.conn:
                        self.cursor.execute(
                            "delete from slaves where name=? and server=? and type=?",
                            (node, self.server_name, alert_type)
                        )
                except sqlite3.IntegrityError as exc:
                    raise RuntimeError(exc)

    def find_job(self, name, build_num):
        """
        Find given job and build number in database, return None
        if not found
        """

        self.cursor.execute(
            "select checked from jobs where name=? and num=? and server=?",
            (name, build_num, self.server_name)
        )
        res = self.cursor.fetchone()

        return None if res is None else res[0]

    def add_stuck_job(self, name, build_num):
        """
        Add job that has just gotten stuck, setting number of times
        checked to 0 (not checked yet)
        """

        logger.debug(f'Adding stuck job {name}, build {build_num} '
                     f'to database')
        try:
            with self.conn:
                self.cursor.execute(
                    "insert into jobs values(?, ?, ?, ?)",
                    (self.server_name, name, build_num, 0)
                )
        except sqlite3.IntegrityError as exc:
            raise RuntimeError(exc)

    def update_stuck_job(self, name, build_num, checked):
        """
        Update a stuck job with a new number of times checked
        """

        try:
            with self.conn:
                self.cursor.execute(
                    "update jobs set checked=? where name=? and num=? "
                    "and server=?",
                    (checked, name, build_num, self.server_name)
                )
        except sqlite3.IntegrityError as exc:
            raise RuntimeError(exc)

    def clear_stuck_jobs(self):
        """Remove any jobs no longer in the stuck state"""

        self.cursor.execute("select name, num from jobs where server=?",
                            (self.server_name,))

        for row in self.cursor.fetchall():
            name, build_num = row
            builds = self.running.get(name)
            logging.debug(f'{name}: {builds}')
            delete = False

            if builds is None:
                delete = True
            else:
                job_nums = [build['number'] for build in builds]

                if build_num not in job_nums:
                    delete = True

            if delete:
                logger.debug(f'Job {name}, build {build_num} completed, '
                             f'removing from database')
                try:
                    with self.conn:
                        self.cursor.execute(
                            "delete from jobs where name=? and num=? "
                            "and server=?",
                            (name, build_num, self.server_name)
                        )
                except sqlite3.IntegrityError as exc:
                    raise RuntimeError(exc)

    def get_max_time(self, job_name):
        """
        Return a time (in seconds) of the maximum "acceptable" time
        for job to run, based on the standard deviation of previous
        run times

        The value is calculated by adding two additional standard
        deviations over the largest one from the historical values
        to find the maximum time to allow; if this is not at least
        300 seconds, return that instead
        """

        times = list()

        for build_info in self.builds[job_name]:
            if build_info['duration']:
                times.append(build_info['duration'])

        t_mean = int(statistics.mean(times))
        std_dev = int(statistics.stdev(times))
        max_deviation = max(abs(t - t_mean) // std_dev + 1 for t in times)

        return max((t_mean + (max_deviation + 2) * std_dev) / 1000, 300)

    def check_nodes_online(self):
        """Ensure all nodes are online, alert via email if any are down
           two types of nodes are ignored:
             1. node that is temporarily taken offline
             2. has unmonitored in its label
        """

        try:
            results = self.get_jenkins_data(
                f'/computer/api/xml?tree=computer[displayName,assignedLabels[name],'
                f'offline,temporarilyOffline]&xpath=//computer[not%28assignedLabel[name]'
                f'=%22unmonitored%22%29%20and%20offline=%22true%22%20and%20'
                f'temporarilyOffline=%22false%22]&wrapper=computers'
            )['computers']
        except (ConnectionError, ValueError) as exc:
            raise RuntimeError(exc)

        # If no results, clear all nodes for server from database
        # (passing empty list to ensure this) and stop processing
        if not results:
            logger.debug(f'No nodes offline, clearing all nodes for '
                         f'{self.server_name} in database')
            self.clear_node_alert(list(), "offline")

            return

        systems = results['computer']

        if isinstance(systems, dict):
            systems = [systems]

        nodes = [system['displayName']['$'] for system in systems]
        logger.debug(f'Systems offline on {self.server_name}: '
                     f'{", ".join(nodes)}')

        # For each offline node, check to see if it's been offline
        # and for how long; if it wasn't already marked as offline,
        # add it to the database and continue, else look for a checked
        # count of a multiple of 20 (one hour based on current run
        # spacing) and an offline time of more than 5 minutes and
        # email as necessary, then update node info in database (if
        # offline for more than 5 minutes)
        for node in nodes:
            results = self.check_node_alert_time(node, "offline")

            if results is None:
                logger.debug(f'Adding offline node {node} to database')
                self.add_node_alert(node, "offline")

                continue

            off_time, checked = results
            logger.debug(f'Down time: {off_time}s, Checked: {checked}')

            if checked % 20 == 0 and off_time > 300:
                node_url = f'{self.server_url}/computer/{node}/'
                message = {
                    'subject': f'Node {node} on Jenkins server '
                               f'{self.server_name} is OFFLINE',
                    'body': f'Node found at {node_url}\nPlease '
                            f'investigate issue'
                }
                send_email(
                    self.smtp_server, self.receivers, message
                )

            if off_time > 300:
                self.update_node_alert(node, "offline", checked + 1)

        # Remove from database any nodes no longer offline
        self.clear_node_alert(nodes, "offline")

    def check_nodes_diskspace(self):
        """ Use xpath to search for nodes that are low on diskspace.
            At the moment, set the threshold at 2GB.  Nodes with 
            unmonitored label is ignored
        """

        try:
            results = self.get_jenkins_data(
                f'/computer/api/xml?xpath=//computer[not%28assignedLabel[name]'
                f'=%22unmonitored%22%29%20and%20monitorData'
                f'[hudson.node_monitors.DiskSpaceMonitor[size[.%3C2147483648]]]]&wrapper=computers'
            )['computers']
        except (ConnectionError, ValueError) as exc:
            raise RuntimeError(exc)

        # If no results, clear all nodes from database
        if not results:
            logger.debug(f'Remove alert records for all nodes for '
                         f'{self.server_name} in database')
            self.clear_node_alert(list(), "diskspace")

            return

        # Start processing returned nodes
        systems = results['computer']

        if isinstance(systems, dict):
            systems = [systems]

        nodes = [system['displayName']['$'] for system in systems]

        for node in nodes:
            results = self.check_node_alert_time(node, "diskspace")

            #Add node to database for new alert
            if results is None:
                logger.debug(f'Adding node {node} to database for diskspace alert')
                self.add_node_alert(node, "diskspace")

                continue

            # Email the team about the diskspace shortage.  Use a counter, "checked"
            # to determine when to send the email.  Current cron job runs every 3
            # minutes; hence, email is sent every hour ( 3 x 20 minutes).

            alerted_time, checked = results
            logger.debug(f'Alerted time: {alerted_time}s, Checked: {checked}')
            if checked % 20 == 0:
                node_url = f'{self.server_url}/computer/{node}/'
                message = {
                    'subject': f'Node {node} on Jenkins server '
                               f'{self.server_name} is low on diskspace',
                    'body': f'{node_url} has less than 2GB of free space.\nPlease '
                            f'investigate issue'
                }
                send_email(
                    self.smtp_server, self.receivers, message
                )

            if alerted_time > 0:
                self.update_node_alert(node, "diskspace", checked + 1)

        # Remove nodes that are not low in diskspace from database
        self.clear_node_alert(nodes, "diskspace")

    def check_running_builds(self):
        """
        Ensure there are no 'stuck' builds, based on a heuristic around
        previous historical times for the relevant job, alert via email
        if any have exceeded acceptable maximum time
        """

        running_jobs = [f'{name}/{data["number"]}'
                        for name, info in self.running.items()
                        for data in info]
        logger.debug(f'Current running jobs: {", ".join(running_jobs)}')

        for job_name in self.running:
            max_time = self.get_max_time(job_name)

            for build in self.running[job_name]:
                curr_build_time = int(
                    time.time() - build['timestamp'] / 1000
                )

                # If the build time is more than the maximum allowed time,
                # look for the job in the database, adding it if it's not
                # there, then look for a checked count of a multiple of 20
                # (one hour based on current run spacing) and email as
                # necessary, then update stuck job in the database
                if curr_build_time > max_time:
                    build_num = int(build['number'])
                    checked = self.find_job(job_name, build_num)

                    if checked is None:
                        self.add_stuck_job(job_name, build_num)
                        checked = 0
                    else:
                        checked += 1
                        self.update_stuck_job(job_name, build_num, checked)

                    if checked % 20 == 0:
                        message = {
                            'subject': f'Build {build_num} for job '
                                       f'{job_name} on Jenkins server '
                                       f'{self.server_name} is STALLED',
                            'body': f'Job {build["url"]} has taken '
                                    f'{curr_build_time} seconds to run '
                                    f'so far.\nPlease investigate issue'
                        }
                        send_email(
                            self.smtp_server, self.receivers, message
                        )

        # Remove from database any jobs no longer stuck
        self.clear_stuck_jobs()


def main():
    """
    Parse the command line arguments, handle configuration setup,
    do validation of base configuration, then run checks on each
    defined Jenkins server
    """

    parser = argparse.ArgumentParser(
        description='Basic monitoring for Jenkins servers'
    )
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Enable debugging output')
    parser.add_argument('-c', '--config', dest='jenkins_config',
                        help='Configuration file for Jenkins monitor',
                        default='jenkins_monitor.json')

    args = parser.parse_args()

    # Set logging to debug level on stream handler if --debug was set
    if args.debug:
        logger.setLevel(logging.DEBUG)

    # Load in configuration data
    conf_data = dict()

    try:
        conf_data.update(json.load(open(args.jenkins_config)))
    except FileNotFoundError:
        logger.error(f"Configuration file '{args.jenkins_config}' missing")
        sys.exit(1)

    # Verify basic configuration
    if 'email' not in conf_data:
        logger.error(f'The "email" key is missing from the config file')
        sys.exit(1)

    email_required_keys = ['smtp_server', 'receivers']
    email_info = conf_data['email']

    if any(key not in email_info for key in email_required_keys):
        logger.error(
            f'One of the following email keys is missing in the config '
            f'file:\n    {", ".join(email_required_keys)}'
        )
        sys.exit(1)

    if 'servers' not in conf_data:
        logger.error(f'The "servers" key is missing from the config file')
        sys.exit(1)

    for server, server_info in conf_data['servers'].items():
        server_required_keys = ['name', 'user', 'passwd']

        if any(key not in server_info for key in server_required_keys):
            logger.error(
                f'One of the following server info keys is missing '
                f'in the config file:\n    {", ".join(server_required_keys)}'
            )
            continue

        try:
            monitor = JenkinsMonitor(email_info, server_info)
            monitor.check_nodes_online()
            monitor.check_nodes_diskspace()
            monitor.check_running_builds()
        except RuntimeError as exc:
            logger.error(f'Monitoring of server {server_info["name"]} '
                         f'failed: {exc}\nContinuing..')
            message = {
                'subject': f'Monitoring of Jenkins server '
                           f'{server_info["name"]} FAILED',
                'body': f'Reason: {exc}\n\nPossibly due to server being down '
                        f'or bad authentication, please investigate issue'
            }
            send_email(
                email_info['smtp_server'], email_info['receivers'], message
            )


if __name__ == '__main__':
    main()
