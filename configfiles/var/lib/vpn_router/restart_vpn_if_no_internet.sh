#!/bin/bash

TIMEOUT=3
REFERENCE_IP=8.8.8.8

if ! ping -c 1 $REFERENCE_IP -w $TIMEOUT > /dev/null; then
  date >> /var/log/router/timeouts.log
  pkill -SIGHUP openvpn
fi
