# Network Topology and Comprehensive IP Addressing Plan

## 1. Architectural Overview

The enterprise security architecture implemented in this lab replicates a multi-tiered corporate branch and perimeter deployment. It features a **FortiGate Next-Generation Firewall (NGFW)** at the perimeter, enforcing strict micro-segmentation, stateful inspection, and deep threat defense across segregated network domains:

- **Corporate LAN (Branch 1 - `10.1.0.0/16`)**: Segmented via 802.1Q VLANs and Layer 3 Switch Virtual Interfaces (SVIs) into User, Developer, and Administrator security enclaves.
- **Demilitarized Zone (DMZ - `10.1.99.0/24`)**: Isolated server zone housing public-facing web applications (`pinglabs.in`) and management services.
- **Out-of-Band Management (OOBM - `192.168.254.0/24`)**: Dedicated host-only network providing isolated out-of-band administrative access to the FortiGate GUI and console.
- **WAN & Internet Transit (`200.1.1.0/24` and `192.168.90.0/24`)**: ISP edge routing simulation with dynamic PAT to replicate real-world public cloud/internet egress.

---

## 2. Master IP Addressing Schema

| Device | Interface | IP Address | Subnet Mask | CIDR | Network / Zone | Purpose / Description |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **FortiGate NGFW** | `port1` | 192.168.254.41 | 255.255.255.0 | /24 | Management (OOBM) | Host-Only GUI/SSH Management (`MGMT-Cloud0`) |
| **FortiGate NGFW** | `port2` | 10.1.1.41 | 255.255.255.0 | /24 | Inside / LAN Transit | Point-to-point link to Core `LAN-Switch` |
| **FortiGate NGFW** | `port3` | 10.1.99.41 | 255.255.255.0 | /24 | DMZ Segment | Gateway for DMZ Server Segment (VLAN 99) |
| **FortiGate NGFW** | `port4` | 200.1.1.41 | 255.255.255.0 | /24 | Outside / WAN | Public transit IP towards ISP Router |
| **LAN-Switch** | `Vlan 1` (SVI) | 10.1.1.254 | 255.255.255.0 | /24 | Inside Transit | Switch gateway on transit segment to Firewall |
| **LAN-Switch** | `Vlan 10` (SVI)| 10.1.10.254 | 255.255.255.0 | /24 | Corporate Users | Default gateway for User Workstations |
| **LAN-Switch** | `Vlan 20` (SVI)| 10.1.20.254 | 255.255.255.0 | /24 | Developers | Default gateway for Developer Workstations |
| **LAN-Switch** | `Vlan 30` (SVI)| 10.1.30.254 | 255.255.255.0 | /24 | IT Administrators | Default gateway for Admin Systems |
| **LAN-Switch** | `Loopback 0` | 10.1.0.254 | 255.255.255.255 | /32 | Management/OSPF | Stable OSPF Router ID & Switch Management |
| **LAN-Switch** | `Gi1/2` | Unnumbered (L2) | N/A | N/A | VLAN 1 Access | Physical uplink to FortiGate `port2` |
| **ISP Router** | `Gi0/1` (or 0/3) | 200.1.1.1 | 255.255.255.0 | /24 | WAN Transit (Inside) | Gateway for FortiGate WAN `port4` |
| **ISP Router** | `Gi0/0` | DHCP Assigned | 255.255.255.0 | /24 | Outside Internet | Uplink to `Internet-Cloud1` (`192.168.90.0/24`) |
| **Web-Server** | `Gi0/0` | 10.1.99.99 | 255.255.255.0 | /24 | DMZ Segment | Production Web Server (`pinglabs.in`) |
| **VPC2** | `eth0` | 10.1.10.2 | 255.255.255.0 | /24 | VLAN 10 (User) | Virtual PC User Endpoint |
| **Linux5** | `eth0` | 10.1.10.5 | 255.255.255.0 | /24 | VLAN 10 (User) | Linux End User Workstation |
| **PC3** | `eth0` | 10.1.20.3 | 255.255.255.0 | /24 | VLAN 20 (Dev) | Virtual PC Developer Endpoint |
| **Linux6** | `eth0` | 10.1.20.6 | 255.255.255.0 | /24 | VLAN 20 (Dev) | Linux Developer Workstation |
| **PC4** | `eth0` | 10.1.30.3 | 255.255.255.0 | /24 | VLAN 30 (Admin) | Virtual PC Admin Endpoint |
| **Linux7** | `eth0` | 10.1.30.7 | 255.255.255.0 | /24 | VLAN 30 (Admin) | Linux Security / Systems Admin Workstation |

---

## 3. Subnetting & Supernetting Design

### Branch 1 Supernet (`10.1.0.0/16`)
To maintain high routing efficiency, the internal network utilizes hierarchical CIDR aggregation:
- **Allocated Supernet**: `10.1.0.0/16` (`65,536` total addresses).
- **Subnet Allocations**:
  - `10.1.0.0/24`: Infrastructure and loopbacks (e.g. `10.1.0.254/32`).
  - `10.1.1.0/24`: Core Transit segment (`LAN-Switch` to FortiGate).
  - `10.1.10.0/24`: VLAN 10 (User Segment - Sales, HR, Marketing).
  - `10.1.20.0/24`: VLAN 20 (Developer Segment - CI/CD, Dev hosts).
  - `10.1.30.0/24`: VLAN 30 (Admin Segment - IT management, Jump boxes).
  - `10.1.99.0/24`: DMZ Subnet (Segmented independently on FortiGate `port3`).

### Public / Transit Subnets
- **WAN P2P Network**: `200.1.1.0/24` (Subnet connecting Firewall `port4` to ISP `Gi0/1`).
- **Outside Carrier Cloud**: `192.168.90.0/24` (DHCP pool simulating public Internet egress).
