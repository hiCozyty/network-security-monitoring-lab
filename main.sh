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

# Function to check if Suricata is running
check_suricata_running() {
    docker exec defender pgrep -f suricata > /dev/null 2>&1
    return $?
}

# Function to check if Zeek is running
check_zeek_running() {
    docker exec defender pgrep -f zeek > /dev/null 2>&1
    return $?
}

# Function to start Suricata
start_suricata() {
    echo -e "${YELLOW}Starting Suricata...${NC}"
    # Stop Zeek if it's running
    if check_zeek_running; then
        echo -e "${YELLOW}Zeek is running. Stopping Zeek first...${NC}"
        docker exec -it defender /scripts/stop-zeek.sh > /dev/null 2>&1
        sleep 2
    fi

    # Start Suricata
    docker exec -it defender /scripts/start-suricata.sh > /dev/null 2>&1

    # Check if started successfully
    if check_suricata_running; then
        echo -e "${GREEN}Suricata started successfully.${NC}"
        return 0
    else
        echo -e "${RED}Failed to start Suricata.${NC}"
        return 1
    fi
}

# Function to start Zeek
start_zeek() {
    echo -e "${YELLOW}Starting Zeek...${NC}"
    # Stop Suricata if it's running
    if check_suricata_running; then
        echo -e "${YELLOW}Suricata is running. Stopping Suricata first...${NC}"
        docker exec -it defender /scripts/stop-suricata.sh > /dev/null 2>&1
        sleep 2
    fi

    # Start Zeek
    docker exec -it defender /scripts/start-zeek.sh > /dev/null 2>&1

    # Check if started successfully
    if check_zeek_running; then
        echo -e "${GREEN}Zeek started successfully.${NC}"
        return 0
    else
        echo -e "${RED}Failed to start Zeek.${NC}"
        return 1
    fi
}

# Function to run port scan
run_port_scan() {
    local scan_type=$1

    echo -e "${RED}Running $scan_type scan from attacker to defender...${NC}"

    case $scan_type in
        "syn")
            docker exec attacker nmap -sS -p 1-1000 172.18.0.2
            ;;
        "xmas")
            docker exec attacker nmap -sX -p 1-1000 172.18.0.2
            ;;
        "null")
            docker exec attacker nmap -sN -p 1-1000 172.18.0.2
            ;;
        "udp")
            docker exec attacker nmap -sU -p 53,67-69,123,161,162,1434 172.18.0.2
            ;;
        *)
            echo -e "${RED}Invalid scan type selected.${NC}"
            ;;
    esac
}

# Simple function to display the status banner
show_status_banner() {
    clear
    echo -e "${BLUE}${BOLD}=== Port Scanning Scenario ===${NC}"

    # Show tool status
    echo -e "\n${CYAN}Current Status:${NC}"
    if check_suricata_running; then
        echo -e "Suricata: ${GREEN}Running${NC}"
        echo -e "Zeek: ${RED}Stopped${NC}"
        ACTIVE_TOOL="suricata"
    elif check_zeek_running; then
        echo -e "Suricata: ${RED}Stopped${NC}"
        echo -e "Zeek: ${GREEN}Running${NC}"
        ACTIVE_TOOL="zeek"
    else
        echo -e "Suricata: ${RED}Stopped${NC}"
        echo -e "Zeek: ${RED}Stopped${NC}"
        ACTIVE_TOOL="none"
    fi

    echo -e "\n${CYAN}Detection Tools:${NC}"
    echo "1. Start Suricata"
    echo "2. Start Zeek"

    echo -e "\n${CYAN}Port Scan Options:${NC}"
    echo "3. Run SYN Scan"
    echo "4. Run XMAS Scan"
    echo "5. Run NULL Scan"
    echo "6. Run UDP Scan"

    echo -e "\n${CYAN}Log Management:${NC}"
    echo "7. Clear Logs"

    echo -e "\n${CYAN}Navigation:${NC}"
    echo "q. Return to Main Menu"

    echo -e "\n${YELLOW}Enter your choice [1-7 or q]:${NC}"
}

# Function to display logs based on active tool
display_logs() {
    local tool=$1
    local lines=10

    echo -e "\n${BLUE}${BOLD}=== Log Output ===${NC}"
    echo -e "${YELLOW}Showing last $lines lines.${NC}\n"

    if [[ "$tool" == "suricata" ]]; then
        docker exec defender tail -n $lines /var/log/suricata/fast.log
    elif [[ "$tool" == "zeek" ]]; then
        if docker exec defender test -f /var/log/zeek/spool/zeek/conn.log; then
            docker exec defender tail -n $lines /var/log/zeek/spool/zeek/conn.log
        else
            echo -e "${RED}Zeek conn.log not found. It may take a moment to be created.${NC}"
        fi
    else
        echo -e "${RED}No active monitoring tool detected.${NC}"
    fi
}

# Function to continuously update logs
update_logs() {
    local tool=$1

    # Use tput to save cursor position
    tput sc

    # Continuously update logs until user presses a key
    while true; do
        # Clear from saved position to end of screen
        tput rc
        tput ed

        # Display the logs
        display_logs "$tool"

        # Wait a short time before updating
        sleep 2

        # Check if user has pressed a key
        if read -t 0.1 -n 1; then
            # User pressed a key, break the loop
            read -n 1 -s key
            break
        fi
    done
}

# Port scan submenu with integrated log view
port_scan_scenario() {
    # Check if lab is running
    if ! check_lab_running; then
        echo -e "${RED}Lab is not running. Start it first with option 1.${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi

    local ACTIVE_TOOL="none"

    # Determine active tool at start
    if check_suricata_running; then
        ACTIVE_TOOL="suricata"
    elif check_zeek_running; then
        ACTIVE_TOOL="zeek"
    fi

    # Clear logs at start of scenario
    if [[ "$ACTIVE_TOOL" == "suricata" ]]; then
        echo -e "${YELLOW}Clearing Suricata logs...${NC}"
        docker exec defender bash -c "truncate -s 0 /var/log/suricata/fast.log"
        echo -e "${GREEN}Suricata logs cleared.${NC}"
    elif [[ "$ACTIVE_TOOL" == "zeek" ]]; then
        echo -e "${YELLOW}Clearing Zeek logs...${NC}"
        docker exec defender bash -c "if [ -f /var/log/zeek/spool/zeek/conn.log ]; then truncate -s 0 /var/log/zeek/spool/zeek/conn.log; fi"
        echo -e "${GREEN}Zeek logs cleared.${NC}"
    fi

    while true; do
        # Display status and menu
        show_status_banner

        # Display logs if a tool is active
        if [[ "$ACTIVE_TOOL" != "none" ]]; then
            display_logs "$ACTIVE_TOOL"
        else
            echo -e "\n${YELLOW}No monitoring tool is currently active. Start Suricata or Zeek to view logs.${NC}"
        fi

        # Read user choice
        read -r choice

        case $choice in
            1)
                start_suricata
                ACTIVE_TOOL="suricata"
                ;;
            2)
                start_zeek
                ACTIVE_TOOL="zeek"
                ;;
            3)
                if [[ "$ACTIVE_TOOL" == "none" ]]; then
                    echo -e "${RED}Please start a monitoring tool first.${NC}"
                    read -p "Press Enter to continue..."
                else
                    run_port_scan "syn"
                    if [[ "$ACTIVE_TOOL" == "zeek" ]]; then
                        echo -e "${YELLOW}Waiting for Zeek logs (5s)...${NC}"
                        sleep 5
                    else
                        echo -e "${YELLOW}Waiting for logs (2s)...${NC}"
                        sleep 2
                    fi
                fi
                ;;
            4)
                if [[ "$ACTIVE_TOOL" == "none" ]]; then
                    echo -e "${RED}Please start a monitoring tool first.${NC}"
                    read -p "Press Enter to continue..."
                else
                    run_port_scan "xmas"
                    if [[ "$ACTIVE_TOOL" == "zeek" ]]; then
                        echo -e "${YELLOW}Waiting for Zeek logs (5s)...${NC}"
                        sleep 5
                    else
                        echo -e "${YELLOW}Waiting for logs (2s)...${NC}"
                        sleep 2
                    fi
                fi
                ;;
            5)
                if [[ "$ACTIVE_TOOL" == "none" ]]; then
                    echo -e "${RED}Please start a monitoring tool first.${NC}"
                    read -p "Press Enter to continue..."
                else
                    run_port_scan "null"
                    if [[ "$ACTIVE_TOOL" == "zeek" ]]; then
                        echo -e "${YELLOW}Waiting for Zeek logs (5s)...${NC}"
                        sleep 5
                    else
                        echo -e "${YELLOW}Waiting for logs (2s)...${NC}"
                        sleep 2
                    fi
                fi
                ;;
            6)
                if [[ "$ACTIVE_TOOL" == "none" ]]; then
                    echo -e "${RED}Please start a monitoring tool first.${NC}"
                    read -p "Press Enter to continue..."
                else
                    run_port_scan "udp"
                    if [[ "$ACTIVE_TOOL" == "zeek" ]]; then
                        echo -e "${YELLOW}Waiting for Zeek logs (5s)...${NC}"
                        sleep 5
                    else
                        echo -e "${YELLOW}Waiting for logs (2s)...${NC}"
                        sleep 2
                    fi
                fi
                ;;
            7)
                # Clear logs based on active tool
                if [[ "$ACTIVE_TOOL" == "suricata" ]]; then
                    echo -e "${YELLOW}Clearing Suricata logs...${NC}"
                    docker exec defender bash -c "truncate -s 0 /var/log/suricata/fast.log"
                    echo -e "${GREEN}Suricata logs cleared.${NC}"
                    sleep 1
                elif [[ "$ACTIVE_TOOL" == "zeek" ]]; then
                    echo -e "${YELLOW}Clearing Zeek logs...${NC}"
                    docker exec defender bash -c "if [ -f /var/log/zeek/spool/zeek/conn.log ]; then truncate -s 0 /var/log/zeek/spool/zeek/conn.log; fi"
                    echo -e "${GREEN}Zeek logs cleared.${NC}"
                    sleep 1
                else
                    echo -e "${RED}No active monitoring tool detected.${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            "q"|"Q")
                return 0
                ;;
            *)
                echo -e "${RED}Invalid option selected.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Run a security analysis test
run_attack_scenario() {
    # Check if lab is running
    if ! check_lab_running; then
        echo -e "${RED}Lab is not running. Start it first with option 1.${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi

    # Available attack scenarios (just Port Scanning for now)
    echo -e "${BLUE}${BOLD}=== Available Attack Scenarios ===${NC}"
    echo -e "${CYAN}Basic Attacks:${NC}"
    echo "1. Port Scanning"
    echo "q. Return to Main Menu"

    echo -e "\n${YELLOW}Enter scenario number or 'q' to return to main menu:${NC}"
    read -r choice

    case $choice in
        1)
            port_scan_scenario
            ;;
        "q"|"Q")
            return 0
            ;;
        *)
            echo -e "${RED}Invalid option selected.${NC}"
            read -p "Press Enter to continue..."
            ;;
    esac

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
