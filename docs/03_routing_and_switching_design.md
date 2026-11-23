# Routing & Switching Architectural Design

## 1. Enterprise LAN Architecture (Branch 1)

In high-performance corporate environments, routing between user VLANs at the core distribution layer eliminates performance bottlenecks on the perimeter firewall. This lab deploys a **Cisco Catalyst Layer 3 Switch (`LAN-Switch`)** handling Inter-VLAN wire-speed routing, coupled with dynamic routing peering to the FortiGate firewall.

```
       [ FortiGate NGFW ] (port2: 10.1.1.41/24)
              ▲
              │ Transit VLAN 1 Link (10.1.1.0/24)
              ▼
       [ Cisco LAN-Switch ] (SVI 1: 10.1.1.254/24 | Loopback0: 10.1.0.254/32)
       ┌──────────────┼──────────────┐
       │              │              │
    [ VLAN 10 ]    [ VLAN 20 ]    [ VLAN 30 ]
    (Users)        (Developers)   (Admins)
    10.1.10.0/24   10.1.20.0/24   10.1.30.0/24
```

---

## 2. Layer 3 Switching & Inter-VLAN Routing

### 2.1 Switch Virtual Interfaces (SVIs)
Instead of consuming physical router sub-interfaces (Router-on-a-Stick), the Layer 3 switch terminates VLAN boundaries locally:
- **`Vlan 1`**: Transit SVI to FortiGate (`10.1.1.254/24`)
- **`Vlan 10`**: Corporate Users Gateway (`10.1.10.254/24`)
- **`Vlan 20`**: Developer Segment Gateway (`10.1.20.254/24`)
- **`Vlan 30`**: Administrator Segment Gateway (`10.1.30.254/24`)

### 2.2 Wire-Speed Hardware Switching
Inter-VLAN traffic between local VLANs (such as VPC2 communicating with Linux6 or PC3) is routed directly in hardware by the switch ASIC, conserving FortiGate CPU cycles for true perimeter security inspection, threat mitigation, and NAT.

---

## 3. Dynamic Routing: OSPF Area 0 Integration

### 3.1 Why Dynamic Routing?
While static routes suffice for trivial lab topologies, enterprise networks require high availability and automated route advertisement. Dynamic OSPF (Open Shortest Path First) Area 0 peering between the FortiGate NGFW and the Core LAN-Switch ensures that:
1. Subnets added to the internal switch are automatically propagated to the firewall routing table.
2. The firewall injects the default route (`0.0.0.0/0`) dynamically into the internal routing domain.
3. Rapid link-state convergence occurs without administrative intervention.

### 3.2 OSPF Parameters
- **Routing Protocol**: OSPF Version 2 (IPv4)
- **Area**: `0.0.0.0` (Backbone Area)
- **LAN-Switch Router ID**: `10.1.0.254` (Configured explicitly via `Loopback 0`)
- **FortiGate Router ID**: `10.1.1.41` (Configured explicitly on FortiOS)
- **Peering Link**: Subnet `10.1.1.0/24` (FortiGate `port2` <--> Switch `Vlan 1`)
- **Hello / Dead Timer Intervals**: `10s` / `40s` (Standard Broadcast network type)

### 3.3 Passive-Interface Best Practice
To prevent rogue OSPF neighbor formation and unnecessary multicast traffic on access ports, all host-facing user interfaces (`Gi0/0` through `Gi1/1`) are designated as passive. Only the transit link to the FortiGate firewall actively participates in OSPF hello exchanges.

---

## 4. Routing Table State Comparison

### LAN-Switch Routing Table (`show ip route`)
```
Gateway of last resort is 10.1.1.41 to network 0.0.0.0

S*    0.0.0.0/0 [1/0] via 10.1.1.41
      10.0.0.0/8 is variably subnetted, 6 subnets, 2 masks
C        10.1.0.254/32 is directly connected, Loopback0
C        10.1.1.0/24 is directly connected, Vlan1
C        10.1.10.0/24 is directly connected, Vlan10
C        10.1.20.0/24 is directly connected, Vlan20
C        10.1.30.0/24 is directly connected, Vlan30
```

### FortiGate Routing Table (`get router info routing-table all`)
```
Routing table for VRF=0
S*      0.0.0.0/0 [10/0] via 200.1.1.1, port4
O       10.1.0.254/32 [110/11] via 10.1.1.254, port2, 00:15:32
C       10.1.1.0/24 is directly connected, port2
O       10.1.10.0/24 [110/11] via 10.1.1.254, port2, 00:15:32
O       10.1.20.0/24 [110/11] via 10.1.1.254, port2, 00:15:32
O       10.1.30.0/24 [110/11] via 10.1.1.254, port2, 00:15:32
C       10.1.99.0/24 is directly connected, port3
C       192.168.254.0/24 is directly connected, port1
C       200.1.1.0/24 is directly connected, port4
```
