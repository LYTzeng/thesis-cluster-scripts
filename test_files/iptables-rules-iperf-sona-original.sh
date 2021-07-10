#!/bin/bash
# iptables rules for SNAT ip from client to K8S nodeport on external OvS
# Use this rule for iperf testing when benchmarking the un-modified version of SONA CNI
# 
# Info:
# client IP address 192.168.60.10 -> external ovs eth7
# external ovs bridge IP 192.168.60.254
# target k8s node ip 192.168.60.2 (ip of K8S service) -> extovs eth5
# K8S service nodePort 30000
#
# Usage:
# Set this iptables rule on external ovs, then use iperf-client on client:
# iperf3 -c 192.168.60.2 -p 5201 -f k -t 610 -O 10

sudo iptables -A FORWARD -d 192.168.60.254/32 -p tcp -m tcp --dport 30000 -j ACCEPT
sudo iptables -A FORWARD -s 192.168.60.254/32 -p tcp -m tcp --dport 30000 -j ACCEPT

sudo iptables -t nat -A POSTROUTING -s 192.168.60.10/32 -o eth5 -j SNAT --to-source 192.168.60.254
sudo iptables -t nat -A POSTROUTING -d 192.168.60.254/32 -p tcp -m tcp --dport 30000 -j SNAT --to-source 192.168.60.10