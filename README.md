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

### Basic Attacks
1. **Port Scanning**: Identify reconnaissance activities using different scan techniques
   - TCP SYN scans
   - Service detection
   - OS fingerprinting
   - Compare how Suricata and Zeek detect different scanning techniques

2. **SSH Brute Force**: Detect and analyze authentication attacks
   - Password guessing attacks
   - Login attempt pattern recognition
   - Threshold-based alerts in both tools

3. **Data Exfiltration**: Detect sensitive data leaving the network
   - File transfers over various protocols
   - Data volume anomalies
   - Content inspection capabilities

### Advanced Attacks
4. **TCP Segmentation Attack**: Test how monitoring tools handle fragmented packets
   - Fragmentation-based IDS evasion
   - Session reassembly capabilities
   - Protocol normalization tests

5. **HTTP Obfuscation**: Examine detection of obfuscated web attacks
   - URL encoding evasion
   - Header manipulation
   - Protocol violation detection

6. **Log4Shell (CVE-2021-44228)**: Demonstrate detection of this critical vulnerability
   - JNDI injection patterns
   - Callback detection
   - Exploitation attempt indicators

7. **SMB Relay Attack**: Practice monitoring Windows file sharing protocol attacks
   - Authentication capture and relay
   - Protocol-specific detection rules
   - Behavioral indicators of compromise

8. **SQL Injection with Evasion**: Test detection of database attacks with evasion techniques
   - Comment injection
   - Encoding variations
   - Timing-based evasions
   - Pattern recognition challenges

9. **Command Injection with Encoding**: Observe how encoding affects detection
   - Base64 encoding
   - Hex encoding
   - Character substitution techniques
   - Command execution indicators

10. **DNS Tunneling/Exfiltration**: Monitor data exfiltration via DNS
    - Domain generation analysis
    - Query size anomalies
    - Frequency pattern detection
    - DNS traffic analysis

11. **Encrypted Traffic Analysis**: Practice monitoring encrypted communications
    - TLS fingerprinting
    - Certificate analysis
    - Encrypted traffic behavior patterns
    - Side-channel information analysis

12. **Lateral Movement Detection**: Identify suspicious internal network movement
    - Post-exploitation activities
    - Credential reuse detection
    - Connection graph analysis
    - Privileged account monitoring

## Features
- Interactive menu-driven interface with the `manage-lab.sh` script
- Live monitoring of attack execution with split-screen views
- Side-by-side comparison of Suricata and Zeek detection capabilities
- Detailed documentation for each attack scenario
- Comprehensive analysis tools for exploring detection data

## Detection Tools Comparison
This lab demonstrates the complementary strengths of two different detection approaches:

### Suricata
- Signature-based detection with precise pattern matching
- Protocol analysis and validation
- File extraction and analysis
- Performance optimized for high-throughput environments

### Zeek (formerly Bro)
- Behavioral analysis focusing on network activity patterns
- Protocol analyzers with deep packet inspection
- Stateful connection tracking
- Customizable policy scripts and detection logic
- Rich logging for forensic analysis

## Prerequisites
- Docker v2 and Docker Compose
- `tmux` for multi-pane monitoring display

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
For a deeper understanding of the detection mechanisms, you can manually test each attack:

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
   suricata -c /etc/suricata/suricata.yaml -i eth0 --init-errors-fatal -D
   zeekctl deploy
   ```

4. Monitor the logs in real-time:
   ```bash
   tail -f /var/log/suricata/fast.log
   tail -f /opt/zeek/logs/current/notice.log
   ```

5. From another terminal, access the attacker:
   ```bash
   docker exec -it attacker bash
   ```

6. Perform attacks and observe the detection differences

## Contributing
Contributions are welcome! Feel free to add new attack scenarios, improve detection rules, or enhance the lab infrastructure.

## License
This project is licensed under the MIT License - see the LICENSE file for details.
