"""
Basic script to ensure the health of various components of a Jenkins setup;
currently handled:

  - Jenkins slaves (online or offline)
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
                "create table slaves "
                "(name text, offline_since timestamp, checked int)"
            )

        if 'jobs' not in tables:
            self.conn.execute(
                "create table jobs (name text, num int, checked int)"
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

    def check_offline_time(self, node):
        """
        Return time and number of checks for an offline node;
        return None if node was not previously offline
        """

        self.cursor.execute(
            "select offline_since, checked from slaves where name=?", (node,)
        )
        res = self.cursor.fetchone()

        if res is None:
            return None

        now = datetime.datetime.now()

        return time.mktime(now.timetuple()) - res[0], res[1]

    def add_offline_node(self, node):
        """
        Add node that has just gone offline, setting number of times
        checked to 0 (not checked yet)
        """

        now = datetime.datetime.now()

        try:
            with self.cursor:
                self.cursor.execute(
                    "insert into slaves values(?, ?, ?)", (node, now, 0)
                )
        except sqlite3.IntegrityError:
            raise RuntimeError(f'Node {node} already in slaves table')

    def update_offline_node(self, node, checked):
        """
        Update an offline node with a new number of times checked
        """

        try:
            with self.cursor:
                self.cursor.execute(
                    "update slaves set checked=? where name=?",
                    (checked, node)
                )
        except sqlite3.IntegrityError as exc:
            raise RuntimeError(exc)

    def clear_offline_nodes(self, offline):
        """Remove any nodes that are no longer offline"""

        self.cursor.execute("select name from slaves")

        for row in self.cursor.fetchall():
            node = row[0]

            if node not in offline:
                try:
                    with self.cursor:
                        self.cursor.execute(
                            "delete from slaves where name=?", (node,)
                        )
                except sqlite3.IntegrityError as exc:
                    raise RuntimeError(exc)

    def find_job(self, name, build_num):
        """
        Find given job and build number in database, return None
        if not found
        """

        self.cursor.execute(
            "select checked from jobs where name=? and num=?",
            (name, build_num)
        )
        res = self.cursor.fetchone()

        return None if res is None else res[0]

    def add_stuck_job(self, name, build_num):
        """
        Add job that has just gotten stuck, setting number of times
        checked to 0 (not checked yet)
        """

        try:
            with self.cursor:
                self.cursor.execute(
                    "insert into jobs values(?, ?, ?)", (name, build_num, 0)
                )
        except sqlite3.IntegrityError as exc:
            raise RuntimeError(exc)

    def update_stuck_job(self, name, build_num, checked):
        """
        Update a stuck job with a new number of times checked
        """

        try:
            with self.cursor:
                self.cursor.execute(
                    "update jobs set checked=? where name=? and num=?",
                    (checked, name, build_num)
                )
        except sqlite3.IntegrityError as exc:
            raise RuntimeError(exc)

    def clear_stuck_jobs(self):
        """Remove any jobs no longer in the stuck state"""

        self.cursor.execute("select name, num from jobs")

        for row in self.cursor.fetchall():
            name, build_num = row
            builds = self.running.get(name)
            delete = False

            if builds is None:
                delete = True

            job_nums = [build['number'] for build in builds]

            if build_num in job_nums:
                delete = True

            if delete:
                try:
                    with self.cursor:
                        self.cursor.execute(
                            "delete from jobs where name=? and num=?",
                            (name, build_num)
                        )
                except sqlite3.IntegrityError as exc:
                    raise RuntimeError(exc)

    def get_max_time(self, job_name):
        """
        Return a time (in seconds) of the maximum "acceptable" time
        for job to run, based on the standard deviation of previous
        run times

        The value is calculated by adding an additional standard
        deviation over the largest one from the historical values
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

        return max((t_mean + (max_deviation + 1) * std_dev) / 1000, 300)

    def check_nodes(self):
        """Ensure all nodes are online, alert via email if any are down"""

        try:
            results = self.get_jenkins_data(
                f'/computer/api/xml?tree=computer[displayName,offline,'
                f'temporarilyOffline]&xpath=//computer[offline=%22true'
                f'%22%20and%20temporarilyOffline=%22false%22]&wrapper='
                f'computers'
            )['computers']
        except (ConnectionError, ValueError) as exc:
            raise RuntimeError(exc)

        if not results:
            return

        systems = results['computer']

        if isinstance(systems, dict):
            systems = [systems]

        offline = [system['displayName']['$'] for system in systems]

        # For each offline node, check to see if it's been offline
        # and for how long; if it wasn't already marked as offline,
        # add it to the database and continue, else look for a checked
        # count of a multiple of 20 (one hour based on current run
        # spacing) and an offline time of more than 5 minutes and
        # email as necessary, then update node info in database (if
        # offline for more than 5 minutes)
        for node in offline:
            off_time, checked = self.check_offline_time(node)

            if off_time is None:
                self.add_offline_node(node)
                continue

            if checked % 20 == 0 and off_time > 300:
                message = {
                    'subject': f'Node {node} on Jenkins server '
                               f'{self.server_name} is OFFLINE',
                    'body': f'Please investigate issue'
                }
                send_email(
                    self.smtp_server, self.receivers, message
                )

            if off_time > 300:
                self.update_offline_node(node, checked + 1)

        # Remove from database any nodes no longer offline
        self.clear_offline_nodes(offline)

    def check_running_builds(self):
        """
        Ensure there are no 'stuck' builds, based on a heuristic around
        previous historical times for the relevant job, alert via email
        if any have exceeded acceptable maximum time
        """

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

                    if checked % 20 == 0:
                        message = {
                            'subject': f'Build {build_num} for job '
                                       f'{job_name} on Jenkins server '
                                       f'{self.server_name} is STALLED',
                            'body': f'Job has taken {curr_build_time} '
                                    f'seconds to run so far.\nPlease '
                                    f'investigate issue'
                        }
                        send_email(
                            self.smtp_server, self.receivers, message
                        )

                    self.update_stuck_job(job_name, build_num, checked + 1)

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
    parser.add_argument('-c', '--config', dest='jenkins_config',
                        help='Configuration file for Jenkins monitor',
                        default='jenkins_monitor.json')

    args = parser.parse_args()

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
            monitor.check_nodes()
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
