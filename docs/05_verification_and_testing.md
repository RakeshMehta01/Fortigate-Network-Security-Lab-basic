# Verification, Testing, and Operational Runbook

## 1. Testing Methodology Matrix

| Test Case | Description | Source Node | Destination Node | Expected Result | Pass/Fail Criteria |
| :---: | :--- | :--- | :--- | :--- | :--- |
| **TC-01** | Out-of-Band Management Connectivity | Host PC (`192.168.254.x`) | FortiGate `port1` (`192.168.254.41`) | ICMP Echo reply & HTTPS GUI accessible | 0% packet loss, GUI login prompt displayed |
| **TC-02** | Inter-VLAN Routing on Core Switch | VPC2 (VLAN 10 - `10.1.10.2`) | PC3 (VLAN 20 - `10.1.20.3`) | Direct hardware routing via LAN-Switch SVIs | Round trip time < 1ms, 5/5 packets answered |
| **TC-03** | OSPF Adjacency Formation | FortiGate `port2` | LAN-Switch `Vlan 1` | Full 2-Way Adjacency (State: FULL/DR or FULL/BDR) | `get router info ospf neighbor` shows `Full` |
| **TC-04** | Outbound Internet Egress & Dynamic PAT | VPC2 (`10.1.10.2`) | External DNS / ISP (`8.8.8.8` / `200.1.1.1`) | Traffic translated to FortiGate WAN IP | Source IP translated, packets returned successfully |
| **TC-05** | Inbound DMZ Virtual IP (DNAT) | External Client / ISP | Public VIP (`200.1.1.41:80`) | Translated to Web-Server (`10.1.99.99:80`) | HTTP 200 OK / Cisco web banner returned |
| **TC-06** | DMZ to LAN Isolation (Zero Trust) | Web-Server (`10.1.99.99`) | VPC2 (`10.1.10.2`) / Admin (`10.1.30.3`) | Dropped by Implicit Deny Policy | 100% packet loss (Request timed out) |

---

## 2. Command-Line Verification Runbook

### Phase 1: FortiGate Interface & System Status
```bash
# Verify all interface IP addresses and link states
show system interface

# Check interface link status and packet counters
diagnose hardware deviceinfo nic port1
diagnose hardware deviceinfo nic port2
diagnose hardware deviceinfo nic port3
diagnose hardware deviceinfo nic port4
```

### Phase 2: Dynamic Routing & OSPF Neighbor State
```bash
# Verify OSPF neighbor adjacency on FortiGate
get router info ospf neighbor

# Output should show:
# Neighbor ID     Pri   State           Dead Time   Address         Interface
# 10.1.0.254        1   Full/DR         00:00:34    10.1.1.254      port2

# Check FortiGate Routing Table
get router info routing-table all

# On Cisco LAN-Switch:
show ip ospf neighbor
show ip route ospf
```

### Phase 3: Active Firewall Sessions & NAT Translations
```bash
# Monitor real-time active firewall sessions
diagnose sys session filter src 10.1.10.2
diagnose sys session list

# View FortiGate NAT translations
diagnose sys session filter dport 80
diagnose sys session list | grep -E "proto|state|hook"

# On Cisco ISP Router: Check NAT Overload Table
show ip nat translations
show ip nat statistics
```

### Phase 4: Live Packet Capture & Sniffing
```bash
# Trace ICMP traffic on FortiGate across all ports
diagnose sniffer packet any "icmp" 4 0 l

# Trace HTTP traffic to DMZ Web Server
diagnose sniffer packet port3 "tcp port 80" 4 0 l
diagnose sniffer packet port4 "tcp port 80" 4 0 l
```

---

## 3. Sample Verification Outputs

### OSPF Neighbor Validation on Cisco LAN-Switch
```
LAN-Switch# show ip ospf neighbor

Neighbor ID     Pri   State           Dead Time   Address         Interface
10.1.1.41         1   FULL/BDR        00:00:36    10.1.1.41       Vlan1
```

### End-to-End Ping from End User PC to Internet
```
VPC2> ping 8.8.8.8
8.8.8.8 icmp_seq=1 timeout
8.8.8.8 icmp_seq=2 ttl=114 time=24.128 ms
8.8.8.8 icmp_seq=3 ttl=114 time=23.892 ms
8.8.8.8 icmp_seq=4 ttl=114 time=24.015 ms
8.8.8.8 icmp_seq=5 ttl=114 time=23.754 ms
```

### External HTTP Probe to DMZ Virtual IP
```
ISP# telnet 200.1.1.41 80
Trying 200.1.1.41, 80 ... Open
GET / HTTP/1.0

HTTP/1.1 200 OK
Server: cisco-IOS
Content-Type: text/html
...
```
