"""
Module for vSphere inventory - CURRENTLY UNUSED AND COMMENTED OUT IN FULL
"""

# import contextlib
#
# import pyVim.connect
#
#
# class System:
#     def __init__(self, name=None, user=None, password=None):
#         self.host = name
#         self.user = user
#         self.password = password
#         self.session = None
#
#     @contextlib.contextmanager
#     def connect(self):
#         self.session = pyVim.connect.SmartConnect(
#             host=self.host, user=self.user, pwd=self.password, port=443
#         )
#         yield
#         pyVim.connect.Disconnect(self.session)
#
#     def find_systems(self):
#         print('vSphere!')
#         with self.connect():
#             # Extract name/label, host, state, OS, labels/tags
#             pass
