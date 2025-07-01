#!/usr/bin/env bash
# ----------------------------------------------------------
# nat-rules.sh  —  Insert MASQUERADE rule once, not on every
# container restart.  Usage:
#
#   nat-rules.sh <LAN_IFACE> <SUBNET_CIDR> [WG_IFACE]
#
# Example:
#   nat-rules.sh wlp2s0 192.168.77.0/24 wg0
# ----------------------------------------------------------

LAN_IFACE=${1:?need wifi interface name (e.g. wlp2s0)}
SUBNET_CIDR=${2:?need subnet (e.g. 192.168.77.0/24)}
WG_IFACE=${3:-wg0}   # default WireGuard interface

# Only add the rule if it isn’t already present
iptables -t nat -C POSTROUTING -s "$SUBNET_CIDR" -o "$WG_IFACE" -j MASQUERADE 2>/dev/null \
  || iptables -t nat -A POSTROUTING -s "$SUBNET_CIDR" -o "$WG_IFACE" -j MASQUERADE

