#!/bin/bash
cloud-init-per always iptables1 iptables --insert FORWARD 1 --in-interface docker+ --destination 169.254.169.254/32 --jump DROP
cloud-init-per always iptables2 iptables-save > /etc/sysconfig/iptables &>> /x
cloud-init-per always iptables3 systemctl enable --now iptables
