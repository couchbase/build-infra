"""
Module for reservation endpoints
"""

import time

from cornice.resource import resource

from .cors import CORS_POLICY
from .urls import ALL_URLS
from .util.db import BuildInfo


@resource(collection_path=ALL_URLS['reservations_collection'],
          path=ALL_URLS['reservations'],
          cors_policy=CORS_POLICY)
class Reservations:
    """
    Handle the 'reservations' endpoints
    """

    def __init__(self, request, context=None):
        """Basic initialization"""

        self.request = request
        self.build_info = BuildInfo(self.request.db)

    def collection_post(self):
        """Create a new reservation"""

        params = self.request.json_body
        reserve_os = params.get('os')

        if reserve_os is None or reserve_os not in self.build_info.get_oses():
            return {'error': f'OS {reserve_os} not found'}

        try:
            total = int(params.get('total', 'missing'))
        except ValueError:
            total = 1

        vms = self.build_info.get_reservable_vms(reserve_os, total)

        if len(vms) != total:
            return {'vms': []}

        try:
            hours = int(params.get('hours', 'missing'))
        except ValueError:
            hours = 3

        for vm in vms:
            vm['state'] = 'reserved'
            vm['who'] = params.get('who', 'unknown')
            vm['expires'] = (time.time() + 3600 * hours) * 1000
            self.build_info.db.upsert_documents({vm['ip']: vm})

        return {'vms': [vm['ip'] for vm in vms]}

    def collection_delete(self):
        """Un-reserves VM by IP address"""

        params = self.request.json_body
        ips = params.get('vms')

        for ip in ips:
            vm = self.build_info.get_vm_by_ip(ip)
            vm['state'] = 'available'
            vm['who'] = ''
            vm['expires'] = 0.0
            self.build_info.db.upsert_documents({vm['ip']: vm})

        return {"status": "ok"}
