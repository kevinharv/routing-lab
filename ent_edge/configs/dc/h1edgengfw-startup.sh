#!/bin/bash

set -e

echo "Enable IP forwarding..."
sysctl -w net.ipv4.ip_forward=1

echo "Creating Linux VRFs..."

ip link add NGFW-DEV type vrf table 100

ip link set NGFW-DEV up

echo "Assigning interfaces to VRFs..."

ip link set eth1 master NGFW-DEV
ip link set eth2 master NGFW-DEV

ip link set eth1 up
ip link set eth2 up

echo "Setup NAT..."

iptables -t nat -A POSTROUTING \
    -s 10.200.0.0/24 \
    -o eth2 \
    -j NETMAP --to 192.168.200.0/24

iptables -t nat -A PREROUTING \
    -d 192.168.200.0/24 \
    -i eth2 \
    -j NETMAP --to 10.200.0.0/24

echo "Starting FRR..."

exec /usr/lib/frr/frrinit.sh start
