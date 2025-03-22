# Network Security Monitoring Lab
A hands-on environment for practicing network security monitoring tools and techniques using Docker containers.

## Introduction
This lab creates a controlled environment where you can practice security monitoring by simulating attacks and observing how different tools detect them. It's designed to demonstrate the strengths and weaknesses of different monitoring approaches, specifically comparing Suricata (signature-based detection) with Zeek (behavior-based analysis).

## Lab Architecture
The lab sets up two main containers in an isolated Docker network (172.18.0.0/24):
* **Defender (172.18.0.2)**: Rocky Linux-based system with monitoring tools (Suricata, Zeek)
* **Attacker (172.18.0.3)**: Kali Linux-based system with penetration testing tools

## Attack Scenarios
The lab includes various attack scenarios to demonstrate different detection capabilities:

1. **Port Scanning**: Identify reconnaissance activities using different scan techniques
   - TCP SYN scans
   - Service detection
   - OS fingerprinting
   - Compare how Suricata and Zeek detect different scanning techniques

2. **SSH Brute Force**: Detect and analyze authentication attacks (wip)
   - Password guessing attacks
   - Login attempt pattern recognition
   - Threshold-based alerts in both tools

3. **Data Exfiltration**: Detect sensitive data leaving the network (wip)
   - File transfers over various protocols
   - Data volume anomalies
   - Content inspection capabilities

4. **TCP Segmentation Attack**: Test how monitoring tools handle fragmented (wip) packets
   - Fragmentation-based IDS evasion
   - Session reassembly capabilities
   - Protocol normalization tests

5. **DNS Tunneling/Exfiltration**: Monitor data exfiltration via DNS (wip)
    - Domain generation analysis
    - Query size anomalies
    - Frequency pattern detection
    - DNS traffic analysis

## Features
- Interactive menu-driven interface with the `main.sh` script
- Live monitoring of attack execution

## Detection Tools Comparison
This lab demonstrates the complementary strengths of two different detection approaches:

## Prerequisites
- Docker v2 and Docker Compose

## Getting Started
```bash
# Clone the repository
git clone https://github.com/hicozyty/network-security-monitoring-lab.git
cd network-security-monitoring-lab

# Make the script executable
chmod +x main.sh

# Run the lab management script
./main.sh
```

## Manual Testing Mode

1. Start the containers:
   ```bash
   docker compose up -d
   ```

2. Access the defender terminal:
   ```bash
   docker exec -it defender bash
   ```

3. Start monitoring services on the defender:
   ```bash
   ./defender/scripts/start-suricata.sh
   ./defender/scripts/stop-suricata.sh
   ./defender/scripts/start-zeek.sh
   ./denfeder/scripts/stop-zeek.sh
   ```


4. From another terminal, access the attacker:
   ```bash
   docker exec -it attacker bash
   ```

5. Perform attacks and observe the detection differences
