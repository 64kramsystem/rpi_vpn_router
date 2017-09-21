#!/bin/bash

date >> /var/log/router/down.log

sysctl -w net.ipv4.ip_forward=0

iptables -t nat -F
