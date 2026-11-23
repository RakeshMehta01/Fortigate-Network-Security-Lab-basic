#!/bin/bash
# ==============================================================================
# Linux Test Clients Network Configuration Script
# Used for Linux5 (VLAN 10), Linux6 (VLAN 20), Linux7 (VLAN 30)
# ==============================================================================

# --- Linux 5 (User VLAN 10) ---
# sudo ip addr add 10.1.10.5/24 dev eth0
# sudo ip link set eth0 up
# sudo ip route add default via 10.1.10.254

# --- Linux 6 (Developer VLAN 20) ---
# sudo ip addr add 10.1.20.6/24 dev eth0
# sudo ip link set eth0 up
# sudo ip route add default via 10.1.20.254

# --- Linux 7 (Admin VLAN 30) ---
# sudo ip addr add 10.1.30.7/24 dev eth0
# sudo ip link set eth0 up
# sudo ip route add default via 10.1.30.254

echo "To configure your Linux endpoint, uncomment the appropriate section above or set netplan."
