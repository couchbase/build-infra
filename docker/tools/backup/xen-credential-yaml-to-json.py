#!/usr/bin/env python3
'''
Convert Xen's YAML credentials to JSON credential file
'''
import argparse
import json
import yaml
from collections import defaultdict
import sys


def load_yaml_data(args):
    '''
    Load Xen's server YAML file, save to data dictionary
    '''
    try:
        with open(args.file, 'r') as fl:
            try:
                data = yaml.load(fl, yaml.SafeLoader)
            except yaml.YAMLError as exc:
                print("Error parsing YAML file")
                sys.exit(1)
    except IOError:
        print("Could not open file: {}".format(args.file))
        sys.exit(1)
    return data


def write_json_data(data, args):
    '''
    Write data to JSON file
    '''
    try:
        with open(args.json_output, mode='w') as f:
            try:
                f.write(json.dumps(data, indent=4))
            except json.JSONDecodeError:
                print("Invalid JSON output!")
                sys.exit(1)
    except IOError:
        print("Cannot write to file: {}").format(args.json_output)
        sys.exit(1)


def convert_yaml_to_json_file(data_dict, args):
    json_dict = defaultdict()
    for platform in data_dict['platforms']:
        for host in platform['hosts']:
            json_dict[host['name']] = {'url': 'http://' + host['ip_addr'],
                                       'username': host['user'],
                                       'password': host['password'],
                                       'repository': args.repository}
    write_json_data(json_dict, args)


def parse_args():
    parser = argparse.ArgumentParser(description="Convert YAML file \
                                     to xenbackup's JSON config\n\n")
    parser.add_argument('--file', '-f', help='YAML File to convert',
                        default='/etc/servers.yaml', required=True)
    parser.add_argument('--repository', '-r', help='Directory for backup',
                        default='/buildteam/backups/xen', required=True)
    parser.add_argument('--json-output', '-o', help='JSON output file',
                        default='/etc/xenbackup.json', required=True)
    return parser.parse_args()


def main():
    args = parse_args()
    data = load_yaml_data(args)
    convert_yaml_to_json_file(data, args)


if __name__ == '__main__':
    main()
