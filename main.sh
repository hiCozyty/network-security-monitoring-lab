#!/bin/bash
# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Make all scripts executable
make_scripts_executable() {
    echo -e "${YELLOW}Making all scripts executable...${NC}"
    find . -name "*.sh" -type f -exec chmod +x {} \;
    echo -e "${GREEN}All scripts are now executable.${NC}"
}

# Check if required utilities are installed
check_requirements() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed!${NC}"
        echo "Please install Docker before running this lab."
        exit 1
    fi

    if ! command -v docker compose &> /dev/null; then
        echo -e "${RED}Error: Docker Compose is not installed!${NC}"
        echo "Please install Docker Compose before running this lab."
        exit 1
    fi

    if ! command -v tmux &> /dev/null; then
        echo -e "${RED}Error: tmux is not installed!${NC}"
        echo "Please install tmux for the split-screen log display:"
        echo "sudo apt install tmux  # For Debian/Ubuntu"
        echo "sudo yum install tmux  # For CentOS/RHEL"
        echo "brew install tmux      # For macOS"
        exit 1
    fi
}

# Check if lab is running
check_lab_running() {
    if [ "$(docker ps -q -f name=defender)" ] && [ "$(docker ps -q -f name=attacker)" ]; then
        return 0
    else
        return 1
    fi
}

# Start lab environment
start_lab() {
    echo -e "${BLUE}=== Starting Network Security Monitoring Lab ===${NC}"

    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}Error: Docker is not running!${NC}"
        echo "Please start Docker before running this lab."
        return 1
    fi

    # Check if lab is already running
    if check_lab_running; then
        echo -e "${YELLOW}Lab is already running.${NC}"
        return 0
    fi

    # Create necessary directories if they don't exist
    echo -e "${YELLOW}Creating necessary directories...${NC}"
    mkdir -p data/logs data/pcaps
    mkdir -p configs/suricata/rules configs/suricata/logs
    mkdir -p configs/zeek/logs configs/zeek/scripts

    # Build and start the containers
    echo -e "${YELLOW}Building and starting containers...${NC}"
    docker compose up -d --build

    # Wait for containers to start
    echo -e "${YELLOW}Waiting for containers to initialize...${NC}"
    sleep 5

    # Check if containers are running
    if [ "$(docker ps -q -f name=defender)" ] && [ "$(docker ps -q -f name=attacker)" ]; then
        echo -e "${GREEN}Lab started successfully!${NC}"

        # Display container information
        echo -e "\n${BLUE}Container Information:${NC}"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

        # Display network information
        echo -e "\n${BLUE}Network Information:${NC}"
        docker network inspect network-security-lab_default | grep -A 2 "IPv4Address" || docker network inspect $(docker network ls | grep -oP '(\w+_default)') | grep -A 2 "IPv4Address"

        echo -e "\n${GREEN}The lab is now ready to use.${NC}"
        echo -e "- Defender IP: 172.18.0.2"
        echo -e "- Attacker IP: 172.18.0.3"

        # Start monitoring services
        echo -e "${YELLOW}Starting monitoring services on defender...${NC}"
        docker exec -it defender /bin/bash -c "/scripts/start-monitoring.sh"

        return 0
    else
        echo -e "${RED}Error: Failed to start lab containers!${NC}"
        echo "Check Docker logs for more information:"
        echo "docker logs defender"
        echo "docker logs attacker"
        return 1
    fi
}

# Stop lab environment
stop_lab() {
    echo -e "${BLUE}=== Stopping Network Security Monitoring Lab ===${NC}"

    # Check if lab is running
    if ! check_lab_running; then
        echo -e "${YELLOW}Lab is not currently running.${NC}"
        return 0
    fi

    # Stop the containers
    echo -e "${YELLOW}Stopping lab containers...${NC}"
    docker compose down

    # Verify containers have stopped
    if [ ! "$(docker ps -q -f name=defender)" ] && [ ! "$(docker ps -q -f name=attacker)" ]; then
        echo -e "${GREEN}Lab stopped successfully!${NC}"
    else
        echo -e "${RED}Error: Failed to stop some containers.${NC}"
        echo "Remaining containers:"
        docker ps --format "table {{.Names}}\t{{.Status}}"

        echo -e "\nTrying to force stop containers..."
        docker stop defender attacker
        echo -e "${YELLOW}Done.${NC}"
    fi

    # Ask if user wants to clean up data
    echo -e "\n${BLUE}Would you like to clean up captured data? (y/N)${NC}"
    read -r clean_data

    if [[ "$clean_data" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Cleaning up data directories...${NC}"
        rm -rf data/logs/* data/pcaps/* 2>/dev/null
        echo -e "${GREEN}Data cleaned.${NC}"
    fi

    echo -e "\n${GREEN}Lab environment shutdown complete.${NC}"
    return 0
}

# Scenario controller script (runs inside the first tmux pane)
generate_controller_script() {
    local scenario="$1"
    local temp_script=$(mktemp)

    cat > "$temp_script" << EOF
#!/bin/bash
# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Display scenario description
echo -e "${BLUE}${BOLD}===== Scenario: $scenario =====${NC}"
echo
cat /scenarios/$scenario/description.md
echo

# Menu for actions
while true; do
    echo
    echo -e "${CYAN}${BOLD}Available Actions:${NC}"
    echo "1. Run Benign Control Activity"
    echo "2. Run Attack"
    echo "3. View Scenario Description"
    echo "4. Exit"
    echo
    echo -n "Enter choice [1-4]: "
    read choice

    case \$choice in
        1)
            if [ -f "/scenarios/$scenario/control.sh" ]; then
                echo -e "${BLUE}Running benign control activity...${NC}"
                cd /scenarios/$scenario && ./control.sh
            else
                echo -e "${RED}Control script not available for this scenario.${NC}"
            fi
            ;;
        2)
            if [ -f "/scenarios/$scenario/attack.sh" ]; then
                echo -e "${RED}Running attack...${NC}"
                cd /scenarios/$scenario && ./attack.sh
            else
                echo -e "${RED}Attack script not available.${NC}"
            fi
            ;;
        3)
            echo
            echo -e "${BLUE}${BOLD}===== Scenario Description =====${NC}"
            echo
            cat /scenarios/$scenario/description.md
            echo
            ;;
        4)
            echo -e "${YELLOW}Exiting scenario controller...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice!${NC}"
            ;;
    esac
done
EOF

    chmod +x "$temp_script"
    echo "$temp_script"
}

# Run a security analysis test with split screen display
run_attack_scenario() {
    # Check if lab is running
    if ! check_lab_running; then
        echo -e "${RED}Lab is not running. Start it first with option 1.${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi

    # Available attack scenarios
    echo -e "${BLUE}${BOLD}=== Available Attack Scenarios ===${NC}"
    echo -e "${CYAN}Basic Attacks:${NC}"
    echo "1. Port Scanning"
    echo "2. SSH Brute Force"
    echo "3. Data Exfiltration"

    echo -e "\n${CYAN}Advanced Attacks:${NC}"
    echo "4. TCP Segmentation Attack"
    echo "5. HTTP Obfuscation"
    echo "6. Log4Shell (CVE-2021-44228)"
    echo "7. SMB Relay Attack"
    echo "8. SQL Injection with Evasion"
    echo "9. Command Injection with Encoding"
    echo "10. DNS Tunneling/Exfiltration"
    echo "11. Encrypted Traffic Analysis"
    echo "12. Lateral Movement Detection"

    echo -e "\n${YELLOW}Enter scenario number or 'q' to return to main menu:${NC}"
    read -r choice

    if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
        return 0
    fi

    # Map choice to scenario directory
    case $choice in
        1) scenario="port-scan" ;;
        2) scenario="brute-force" ;;
        3) scenario="data-exfiltration" ;;
        4) scenario="tcp-segmentation" ;;
        5) scenario="http-obfuscation" ;;
        6) scenario="log4shell" ;;
        7) scenario="smb-relay" ;;
        8) scenario="sql-injection" ;;
        9) scenario="command-injection" ;;
        10) scenario="dns-tunneling" ;;
        11) scenario="encrypted-traffic" ;;
        12) scenario="lateral-movement" ;;
        *)
            echo -e "${RED}Invalid option selected.${NC}"
            read -p "Press Enter to continue..."
            return 1
            ;;
    esac

    # Check if scenario directory exists
    if [ ! -d "scenarios/$scenario" ]; then
        echo -e "${RED}Scenario directory 'scenarios/$scenario' not found.${NC}"
        echo -e "${YELLOW}This scenario is not yet implemented.${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi

    # Create temporary controller script
    controller_script=$(generate_controller_script "$scenario")

    # Copy controller script to attacker container
    docker cp "$controller_script" attacker:/tmp/controller.sh

    # Set up tmux session for display
    echo -e "${YELLOW}Setting up monitoring display...${NC}"

    # Create a new tmux session
    tmux new-session -d -s nsm_lab

    # Split the window into panes
    tmux split-window -v -t nsm_lab:0
    tmux split-window -h -t nsm_lab:0.1
    tmux split-window -h -t nsm_lab:0.0

    # Resize panes
    tmux resize-pane -t nsm_lab:0.0 -y 10

    # Set up the panes with appropriate commands
    # Pane 0: Scenario controller (top left)
    tmux send-keys -t nsm_lab:0.0 "echo -e '${BLUE}${BOLD}=== Scenario Controller: ${scenario} ===${NC}'; docker exec -it attacker /tmp/controller.sh" C-m

    # Pane 1: Attacker logs (bottom left)
    tmux send-keys -t nsm_lab:0.1 "echo -e '${RED}${BOLD}=== Attacker Activity Log ===${NC}'; docker exec -it attacker /bin/bash -c \"tail -f /var/log/attacker.log 2>/dev/null || echo 'Waiting for activity...'\"" C-m

    # Pane 2: Suricata logs (top right)
    tmux send-keys -t nsm_lab:0.2 "echo -e '${GREEN}${BOLD}=== Suricata Detection Log ===${NC}'; docker exec -it defender /bin/bash -c \"tail -f /var/log/suricata/fast.log\"" C-m

    # Pane 3: Zeek logs (bottom right)
    tmux send-keys -t nsm_lab:0.3 "echo -e '${MAGENTA}${BOLD}=== Zeek Detection Log ===${NC}'; docker exec -it defender /bin/bash -c \"tail -f /opt/zeek/logs/current/notice.log\"" C-m

    # Attach to the tmux session
    tmux attach-session -t nsm_lab

    # When user detaches, clean up the tmux session
    if tmux has-session -t nsm_lab 2>/dev/null; then
        tmux kill-session -t nsm_lab
    fi

    # Clean up temporary files
    rm -f "$controller_script"

    echo -e "${GREEN}Scenario session completed.${NC}"
    read -p "Press Enter to continue..."
    return 0
}

# Open shell in container
open_shell() {
    if ! check_lab_running; then
        echo -e "${RED}Lab is not running. Start it first with option 1.${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi

    echo -e "${BLUE}${BOLD}=== Open Shell in Container ===${NC}"
    echo "1. Defender Container"
    echo "2. Attacker Container"
    echo
    echo -n "Choose container [1-2]: "
    read -r container_choice

    case $container_choice in
        1)
            echo -e "${YELLOW}Opening shell in defender container...${NC}"
            docker exec -it defender bash
            ;;
        2)
            echo -e "${YELLOW}Opening shell in attacker container...${NC}"
            docker exec -it attacker bash
            ;;
        *)
            echo -e "${RED}Invalid choice!${NC}"
            ;;
    esac

    return 0
}

# Display tool information
show_tool_info() {
    echo -e "${BLUE}${BOLD}=== Network Security Monitoring Tools ===${NC}"

    echo -e "\n${CYAN}Suricata${NC}"
    echo "Suricata is an open source threat detection engine that combines intrusion"
    echo "detection (IDS), intrusion prevention (IPS), and network security monitoring."
    echo "It uses signature-based detection, protocol analysis, and anomaly detection."
    echo
    echo "Key strengths:"
    echo "- Fast pattern matching for known threats"
    echo "- Protocol decoding and validation"
    echo "- File extraction and identification"
    echo "- TLS certificate validation"

    echo -e "\n${MAGENTA}Zeek (formerly Bro)${NC}"
    echo "Zeek is a powerful network analysis framework different from traditional IDS."
    echo "It provides a comprehensive platform for network traffic analysis, focusing"
    echo "on network security monitoring beyond simple pattern matching."
    echo
    echo "Key strengths:"
    echo "- Deep protocol analysis"
    echo "- Connection tracking and session analysis"
    echo "- Behavioral anomaly detection"
    echo "- Scriptable detection logic"
    echo "- Detailed logging for forensics"

    read -p "Press Enter to continue..."
}

# Display the main menu
show_menu() {
    clear
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo -e "${BLUE}${BOLD}    Network Security Monitoring Lab      ${NC}"
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo

    if check_lab_running; then
        echo -e "${GREEN}Lab Status: Running${NC}"
    else
        echo -e "${RED}Lab Status: Stopped${NC}"
    fi

    echo
    echo -e "${CYAN}Lab Management:${NC}"
    echo "1. Start Lab Environment"
    echo "2. Stop Lab Environment"

    echo -e "\n${CYAN}Security Testing:${NC}"
    echo "3. Run Attack Scenario"

    echo -e "\n${CYAN}Advanced Options:${NC}"
    echo "4. Open Shell in Container"
    echo "5. Tool Information"
    echo "6. Exit"
    echo
    echo -n "Enter your choice [1-6]: "
}

# Main program
check_requirements
make_scripts_executable

# Main loop
while true; do
    show_menu
    read -r choice

    case $choice in
        1)
            start_lab
            read -p "Press Enter to continue..."
            ;;
        2)
            stop_lab
            read -p "Press Enter to continue..."
            ;;
        3)
            run_attack_scenario
            ;;
        4)
            open_shell
            ;;
        5)
            show_tool_info
            ;;
        6)
            echo -e "${GREEN}Exiting. Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            read -p "Press Enter to continue..."
            ;;
    esac
done
