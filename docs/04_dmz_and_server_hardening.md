# Demilitarized Zone (DMZ) & Server Hardening Design

## 1. DMZ Security Principles

A Demilitarized Zone (DMZ) is a dedicated perimeter network segment created to host external-facing services while isolating them from the private internal corporate network.

### Key Threat Vectors Addressed:
1. **Public Attack Surface Containment**: Public services (HTTP, HTTPS, Mail, DNS) are vulnerable to web application exploits (SQL injection, XSS, RCE). By placing the web server in VLAN 99 (`10.1.99.0/24`) attached directly to FortiGate `port3`, any potential compromise is constrained within this isolated zone.
2. **Elimination of Lateral Movement**:
   - The FortiGate firewall explicitly blocks any unsolicited sessions initiated from the DMZ towards the internal LAN (`port3` -> `port2` = **DENY**).
   - If a malicious actor gains root/admin on the DMZ Web Server, they cannot probe, scan, or pivot into user or administrator subnets.

---

## 2. Server Configuration & Hardening Profile

The DMZ Web Server (`Web-Server`) is implemented as an authenticated Cisco IOS service host:

- **Hostname**: `Web-Server`
- **Domain**: `pinglabs.in`
- **Interface**: `GigabitEthernet0/0` (`10.1.99.99/24`)
- **Gateway**: `10.1.99.41` (FortiGate `port3`)
- **Published Port**: TCP 80 (HTTP Server)
- **Administrative Port**: TCP 22 (SSH v2) & TCP 23 (Telnet - lab testing only)

### Hardening Measures Applied:
- **Local User AAA**: Separate administrative roles (`admin` privilege 15) and standard test user accounts.
- **Crypto Key Generation**: 1024-bit RSA keys generated (`crypto key generate rsa modulus 1024`) enabling secure SSHv2 encrypted management.
- **Controlled VTY Access**: `transport input telnet ssh` with local authentication enforcement (`login local`).
- **TFTP Server Isolation**: TFTP NVRAM exposure restricted strictly for backup routines.

---

## 3. Bidirectional Flow Walkthrough

### Scenario A: External Client Accessing Web Server
1. External user accesses `http://200.1.1.41`.
2. FortiGate `port4` intercepts traffic.
3. Destination NAT translates `200.1.1.41:80` -> `10.1.99.99:80`.
4. Firewall policy `WAN_to_DMZ_WebServer_VIP` inspects traffic, logs connection, and passes packet to `port3`.
5. Web Server processes request and responds back through default gateway `10.1.99.41`.
6. Firewall restores external public IP header and sends response to client.

### Scenario B: Compromised DMZ Host Attempting Internal Pivot
1. An attacker executes a script on `10.1.99.99` attempting to ping or SSH to Admin switch SVI `10.1.30.254` or user machine `10.1.10.2`.
2. Packet arrives at FortiGate `port3` destined for `10.1.30.254` (`port2`).
3. FortiGate evaluates security policies:
   - Policy 10 (LAN to WAN): No match.
   - Policy 20 (LAN to DMZ): No match (ingress is `port3`, not `port2`).
   - Policy 30 (WAN to DMZ): No match.
   - Policy 40 (DMZ to WAN): No match (egress is `port2`, not `port4`).
   - Implicit Deny: **MATCH -> DROP & LOG**.
4. Result: Lateral movement attempt is neutralized, and a security alert is recorded in FortiOS logs.
