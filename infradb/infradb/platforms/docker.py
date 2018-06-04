"""
Module for Docker inventory - CURRENTLY UNUSED
"""

import contextlib

import docker


class System:
    def __init__(self, name=None, ip_addr=None, port=2375):
        """Basic initialization"""

        self.host = name
        self.ip_addr = ip_addr
        self.port = port
        self.session = None

    @contextlib.contextmanager
    def connect(self):
        """
        Context manager to handle connecting to and disconnecting
        from a docker instance
        """

        self.session = docker.DockerClient(
            base_url=f'tcp://{self.ip_addr}:{self.port}'
        )
        yield
        self.session.api.close()  # Not sure this really does anything

    def find_systems(self):
        """
        Determine all existing Docker containers and acquire
        desired information needed for recreating them if needed
        """

        with self.connect():
            # Extract name, container ID, image, host, labels/tags, state
            for container in self.session.containers.list():
                print(f'{getattr(container, "name")}')
                fields = ['short_id', 'image', 'status']

                for field in fields:
                    print(f'  {getattr(container, field)}')
