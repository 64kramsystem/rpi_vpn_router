#!/bin/bash

iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE

sysctl -w net.ipv4.ip_forward=1

# iptables -F
