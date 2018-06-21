"""
Basic script to ensure the health of various components of a Jenkins setup;
currently handled:

  - Jenkins slaves (online or offline)
  - Jenkins jobs (hung jobs)

More capability will be added as needed.
"""

import argparse
import json
import logging
import smtplib
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


class JenkinsMonitor:
    """"""

    def __init__(self, email_info, server_info):
        """
        Basic initialization and loading of key information for all builds
        from Jenkins
        """

        self.smtp_server = email_info['smtp_server']
        self.receivers = email_info['receivers']

        self.server_name = server_info['name']
        self.server_url = f'http://{self.server_name}'
        self.user = server_info['user']
        self.passwd = server_info['passwd']

        self.session = requests_xml.XMLSession()
        self.builds, self.running = self.get_full_build_info()

    @staticmethod
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

    def get_jenkins_data(self, url_path):
        """
        Acquire data from Jenkins for a given REST API request,
        returning data in JSON format
        """

        req = self.session.get(f'{self.server_url}{url_path}')

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
            f'/api/xml?tree=jobs[displayName,builds[building,timestamp,'
            f'estimatedDuration,duration,url,result]]'
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

    def get_max_time(self, job_name):
        """
        Return a time (in seconds) of the maximum "acceptable" time
        for job to run, based on the standard deviation of previous
        run times

        The value is calculated by adding an additional standard
        deviation over the largest one from the historical values
        to find the maximum time to allow
        """

        times = list()

        for build_info in self.builds[job_name]:
            if build_info['duration']:
                times.append(build_info['duration'])

        t_mean = int(statistics.mean(times))
        std_dev = int(statistics.stdev(times))
        max_deviation = max(abs(t - t_mean) // std_dev + 1 for t in times)

        return (t_mean + (max_deviation + 1) * std_dev) / 1000

    def check_nodes(self):
        """Ensure all nodes are online, alert via email if any are down"""

        results = self.get_jenkins_data(
            f'/computer/api/xml?tree=computer[displayName,offline,'
            f'temporarilyOffline]&xpath=//computer[offline=%22true'
            f'%22%20and%20temporarilyOffline=%22false%22]&wrapper=computers'
        )['computers']

        if not results:
            return

        systems = results['computer']

        if isinstance(systems, dict):
            systems = [systems]

        offline = [system['displayName']['$'] for system in systems]

        if offline:
            for node in offline:
                message = {
                    'subject': f'Node {node} on Jenkins server '
                               f'{self.server_name} is OFFLINE',
                    'body': f'Please investigate issue'
                }
                self.send_email(
                    self.smtp_server, self.receivers, message
                )

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

                if curr_build_time > max_time:
                    message = {
                        'subject': f'Job {job_name} on Jenkins server '
                                   f'{self.server_name} is STALLED',
                        'body': f'Job has taken {curr_build_time} seconds '
                                f'to run so far.\nPlease investigate issue'
                    }
                    self.send_email(
                        self.smtp_server, self.receivers, message
                    )


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

    if any(key not in conf_data['email'] for key in email_required_keys):
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

        monitor = JenkinsMonitor(conf_data['email'], server_info)

        monitor.check_nodes()
        monitor.check_running_builds()


if __name__ == '__main__':
    main()
