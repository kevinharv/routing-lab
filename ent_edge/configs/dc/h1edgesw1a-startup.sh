#!/bin/bash

set -e

echo "Creating Linux VRFs..."

ip link add AWS-DEV type vrf table 100
ip link add B2B-DEV type vrf table 200

ip link set AWS-DEV up
ip link set B2B-DEV up

echo "Assigning interfaces to VRFs..."

ip link set eth1 master AWS-DEV     # DX to AWS
ip link set eth2 master B2B-DEV     # B2B partner
ip link set eth3 master AWS-DEV     # NGFW
ip link set eth4 master B2B-DEV     # NGFW

ip link set eth1 up
ip link set eth2 up
ip link set eth3 up
ip link set eth4 up

echo "Starting FRR..."

exec /usr/lib/frr/frrinit.sh start
