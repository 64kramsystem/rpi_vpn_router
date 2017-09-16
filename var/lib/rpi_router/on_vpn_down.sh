#!/bin/bash

date >> /var/log/router/down.log

# iptables -A FORWARD -i wlan0 -o eth0 -j REJECT
# iptables -A FORWARD -i eth0 -o wlan0 -j REJECT

sysctl -w net.ipv4.ip_forward=0

iptables -t nat -F
