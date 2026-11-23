# FortiGate Security Architecture & Policy Design

## 1. Zero Trust & Defense-in-Depth Model

The FortiGate Next-Generation Firewall serves as the core policy enforcement point (PEP). Unlike traditional packet filters that rely merely on stateless Layer 3/4 header evaluations, FortiOS inspects bidirectional flows across Layer 2 through Layer 7 with stateful session tracking, protocol verification, and integrated security profiles.

```
       [ Outside / Internet ]
                 │
                 ▼
           [ port4: WAN ]
                 │
        ┌────────┴────────┐
        │ FortiGate NGFW  │ ◄─────── [ port1: OOBM (192.168.254.0/24) ]
        └────────┬────────┘
                 │
        ┌────────┴────────┐
        ▼                 ▼
   [ port2: LAN ]    [ port3: DMZ ]
  (10.1.1.0/24)      (10.1.99.0/24)
        │                 │
  [ LAN-Switch ]    [ Web-Server ]
  - VLAN 10 (Users) (pinglabs.in:80)
  - VLAN 20 (Dev)
  - VLAN 30 (Admin)
```

---

## 2. Security Zone Classification

1. **Inside / LAN Zone (`port2`)**:
   - High trust relative to the Internet, but segmented into distinct VLANs.
   - Requires full outbound NAT (Port Address Translation) when reaching the WAN.
   - Strictly restricted when accessing the DMZ or Firewall Management.

2. **Demilitarized Zone (DMZ) (`port3`)**:
   - Neutral trust zone housing public-facing assets.
   - **Critical Rule**: Zero unsolicited inbound connectivity from DMZ into the Internal LAN is permitted. Even if the web server is compromised, lateral movement into the corporate LAN is strictly blocked.
   - Outbound access to the WAN is limited to essential update services (NTP, DNS, HTTP/HTTPS repositories).

3. **Outside / WAN Zone (`port4`)**:
   - Zero trust (Public Internet).
   - All inbound unsolicited connections are dropped by default (Implicit Deny), except for specific Virtual IPs (VIPs) mapped to DMZ services.

4. **Out-of-Band Management (OOBM) (`port1`)**:
   - Host-only isolated network (`192.168.254.0/24`).
   - Accessible only from the designated local administrative workstation or authorized Admin VLAN (`VLAN 30`).

---

## 3. Firewall Security Policy Matrix

| Policy ID | Policy Name | Ingress Intf | Egress Intf | Source Address | Destination Address | Service / Ports | Action | NAT | Logging | Business Justification |
| :---: | :--- | :---: | :---: | :--- | :--- | :--- | :---: | :---: | :---: | :--- |
| **10** | `LAN_to_Internet_Outbound` | `port2` | `port4` | `NET_Branch1_Summary` | `all` | HTTP, HTTPS, DNS, PING | **ACCEPT** | SNAT (Interface IP) | All Sessions | Allows internal branch users secure access to the Internet with source NAT. |
| **20** | `LAN_to_DMZ_WebServer` | `port2` | `port3` | `GRP_Internal_User_Segments` | `HOST_DMZ_WebServer` | HTTP, HTTPS, SSH, PING | **ACCEPT** | Disabled | Internal corporate users and developers accessing the internal web portal and admin SSH. |
| **30** | `WAN_to_DMZ_WebServer_VIP` | `port4` | `port3` | `all` | `VIP_DMZ_Web_HTTP` (200.1.1.41:80) | HTTP (TCP/80) | **ACCEPT** | Disabled (DNAT mapped to 10.1.99.99) | All Sessions | Allows external clients to access the published web application `pinglabs.in`. |
| **40** | `DMZ_to_Internet_Outbound` | `port3` | `port4` | `NET_DMZ_Subnet` | `all` | DNS, NTP, HTTP, HTTPS | **ACCEPT** | SNAT (Interface IP) | All Sessions | Permits DMZ servers to synchronize time and download OS software patches. |
| **50** | `Admin_VLAN30_Management` | `port2` | `port1` | `NET_VLAN30_Admins` | `all` | HTTPS, SSH, PING | **ACCEPT** | Disabled | All Sessions | Restricts management plane access solely to authorized IT Administrators in VLAN 30. |
| **0** | `Implicit Deny` | Any | Any | `all` | `all` | ALL | **DENY** | N/A | Dropped Traffic | Default drop for any unclassified or unauthorized traffic flow. |

---

## 4. NAT Architecture & Traffic Mechanics

### 4.1 Source NAT (PAT / Dynamic Overload)
- **Problem**: Internal devices use RFC 1918 private IPv4 addresses (`10.1.0.0/16`) which cannot be routed across the public Internet.
- **Solution**: Outbound traffic exiting `port4` has its source IPv4 address rewritten to the FortiGate WAN interface IP (`200.1.1.41`), allocating ephemeral high-order TCP/UDP source ports.
- **Secondary Edge NAT**: The ISP edge router performs an additional layer of NAT overload onto its DHCP-assigned outside IP, simulating carrier-grade transit.

### 4.2 Destination NAT (Virtual IP / Port Forwarding)
- **External Public IP**: `200.1.1.41` on TCP Port 80
- **Internal Translated Target**: `10.1.99.99` on TCP Port 80
- **Flow**:
  1. External user transmits TCP SYN to `200.1.1.41:80`.
  2. FortiGate intercepts on `port4`, matches VIP `VIP_DMZ_Web_HTTP`.
  3. Destination IP header is translated from `200.1.1.41` to `10.1.99.99`.
  4. Packet is forwarded out `port3` into the DMZ.
  5. The return SYN-ACK from `10.1.99.99` is un-NATed back to source `200.1.1.41` before egressing to the external client.

---

## 5. Security Profiles & Threat Mitigation

1. **Intrusion Prevention System (IPS)**:
   - Deep inspection of ingress and egress traffic for known exploit signatures (e.g., CVE exploits, buffer overflows, malicious payloads).
   - Applied to the DMZ VIP policy to shield the web server against Layer 7 application exploits.
2. **Web Filtering & DNS Filtering**:
   - Enforces acceptable use policies for corporate users in VLAN 10 and 20.
   - Blocks malware distribution domains, phishing vectors, and command-and-control (C2) callbacks.
3. **Application Control**:
   - Identifies and throttles or blocks shadow IT protocols (e.g. BitTorrent, unauthorized tunneling tools) irrespective of the port used.
