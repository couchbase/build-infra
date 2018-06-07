"""
Module for Xen inventory
"""

import contextlib
import xmlrpc.client

from datetime import datetime

import infradb.XenAPI


class System:
    """Acquire information for all VMs on a given Xen host"""

    GB_BYTES = 1024 ** 3

    def __init__(self, name=None, ip_addr=None, user=None, password=None):
        """Basic initialization"""

        self.host = name
        self.ip_addr = ip_addr
        self.user = user
        self.password = password
        self.session = None

    @contextlib.contextmanager
    def connect(self):
        """
        Context manager to handle connecting to and disconnecting
        from a Xen host; raise connection error if unable to connect
        to host
        """

        try:
            self.session = infradb.XenAPI.Session(f'http://{self.ip_addr}/')
            self.session.xenapi.login_with_password(
                self.user, self.password, '1.0', 'update_system_info.py'
            )
        except (ConnectionRefusedError, TimeoutError, xmlrpc.client.Fault):
            raise ConnectionError(
                f'Timeout connecting to {self.host}, skipping...'
            )
        except infradb.XenAPI.Failure as exc:
            err_info = exc.args[0]
            raise ConnectionError(
                f'Login to {self.host} failed for user {self.user}: '
                f'{err_info[2]}, skipping...'
            )

        yield
        self.session.xenapi.logout()

    def get_disk_space(self, vm):
        """Acquire sizes for disk space used for given VM"""

        vbds = self.session.xenapi.VM.get_VBDs(vm)
        disks = list()

        for vbd in vbds:
            vinfo = self.session.xenapi.VBD.get_record(vbd)

            # Only interested in disk, not CD/ramdisk/etc.
            if vinfo['type'] != 'Disk':
                continue

            vdi = self.session.xenapi.VBD.get_VDI(vbd)
            disk_size = self.session.xenapi.VDI.get_virtual_size(vdi)
            disks.append(int(disk_size) / self.GB_BYTES)

        return disks

    def get_os_and_network(self, vm):
        """
        Acquire OS name (and version) and IP address for given VM;
        'unknown' is returned if this can't be determined
        """

        guest_metrics = self.session.xenapi.VM.get_guest_metrics(vm)

        if guest_metrics != 'OpaqueRef:NULL':
            os_name = self.session.xenapi.VM_guest_metrics.get_os_version(
                guest_metrics
            ).get('name', 'unknown')
            ip_addr = self.session.xenapi.VM_guest_metrics.get_networks(
                guest_metrics
            ).get('0/ip', 'unknown')
        else:
            os_name = 'unknown'
            ip_addr = 'unknown'

        return os_name, ip_addr

    def find_systems(self):
        """
        Determine all existing VMs for a given host and acquire
        desired information needed for recreating them if needed
        """

        vm_info = dict()

        try:
            with self.connect():
                # Extract host name (used for document name in database)
                xen_host = self.session.xenapi.host.get_all()[0]
                xen_hostname = self.session.xenapi.host.get_hostname(xen_host)

                for vm in self.session.xenapi.VM.get_all():
                    record = self.session.xenapi.VM.get_record(vm)

                    # Don't include templates or domain controllers
                    if record['is_a_template'] or record['is_control_domain']:
                        continue

                    vm_data = dict(
                        type='xen',
                        key_=record['name_label'],
                        description=record['name_description'],
                        state=record['power_state'],
                        CPU_cores=record['VCPUs_max'],
                        memory_in_gb=(
                            int(record['memory_static_max']) / self.GB_BYTES
                        ),
                    )

                    vm_data['disk_space_in_gb'] = self.get_disk_space(vm)
                    os_name, ip_addr = self.get_os_and_network(vm)
                    vm_data['os'] = os_name.split('|')[0]
                    vm_data['ip_address'] = ip_addr
                    vm_info[vm_data['key_']] = vm_data
        except ConnectionError as exc:
            # If unable to connect to host, simply print reason
            # and return tuple of True (for failure) and an empty
            # dictionary (no data)
            print(exc)

            return True, dict()
        else:
            # Get current date / time to keep track of host updates
            curr_ts = str(datetime.now()).split('.')[0]

            # Tuple of False (no failure) and dictionary with data
            return (
                False, {xen_hostname: {
                    'last_updated': curr_ts, 'vms': vm_info}
                }
            )
