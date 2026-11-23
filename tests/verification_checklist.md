# Pre-Flight and Post-Deployment Testing Checklist

- [x] **Management Plane (OOBM)**
  - [x] Configure static IP `192.168.254.41/24` on FortiGate `port1`.
  - [x] Enable HTTP, HTTPS, SSH, Telnet, and PING on `port1`.
  - [x] Verify local host ping to `192.168.254.41`.
  - [x] Access FortiOS Web GUI via `https://192.168.254.41`.

- [x] **Core Layer 3 LAN Switching**
  - [x] Define VLANs: 10 (User), 20 (Developer), 30 (Admin).
  - [x] Configure SVIs with `.254` gateway addresses.
  - [x] Configure Loopback 0 (`10.1.0.254/32`) as stable router-ID.
  - [x] Verify local inter-VLAN routing (ping from VPC2 to PC3/PC4).
  - [x] Configure static default route `0.0.0.0/0` via FortiGate `10.1.1.41`.

- [x] **Dynamic Routing (OSPF Area 0)**
  - [x] Enable OSPF process 1 on LAN-Switch across VLANs and transit link.
  - [x] Set host access ports as OSPF passive-interfaces.
  - [x] Configure FortiGate OSPF Area 0 on `port2` with Router ID `10.1.1.41`.
  - [x] Verify OSPF 2-Way / Full adjacency between FortiGate and LAN-Switch.
  - [x] Confirm FortiGate routing table contains internal routes (`10.1.10.0/24`, `10.1.20.0/24`, `10.1.30.0/24`).

- [x] **Edge WAN & ISP NAT Overload**
  - [x] Configure ISP Edge Router interface `Gi0/0` with DHCP and `ip nat outside`.
  - [x] Configure ISP Edge Router interface `Gi0/1` with `200.1.1.1/24` and `ip nat inside`.
  - [x] Apply standard ACL `FW-WAN-IP-LIST` permitting `200.1.1.0/24`.
  - [x] Enable NAT overload on ISP `Gi0/0`.
  - [x] Configure FortiGate default static route to `200.1.1.1` via `port4`.

- [x] **FortiGate Security Policies & NAT**
  - [x] Create Address Objects for subnets and DMZ hosts.
  - [x] Implement Policy 10 (`LAN_to_Internet_Outbound`) with dynamic PAT.
  - [x] Verify internet access from LAN endpoints (`ping 8.8.8.8`).
  - [x] Implement Policy 20 (`LAN_to_DMZ_WebServer`) permitting HTTP/SSH.
  - [x] Configure Virtual IP (VIP) for DMZ Web Server (`200.1.1.41:80` -> `10.1.99.99:80`).
  - [x] Implement Policy 30 (`WAN_to_DMZ_WebServer_VIP`).
  - [x] Test inbound HTTP connection to public VIP.

- [x] **DMZ Isolation & Zero Trust Validation**
  - [x] Attempt outbound connection from DMZ Web-Server to LAN hosts (`10.1.10.2`).
  - [x] Confirm traffic is dropped by FortiGate Implicit Deny policy.
  - [x] Review firewall drop logs in FortiOS GUI / CLI.
