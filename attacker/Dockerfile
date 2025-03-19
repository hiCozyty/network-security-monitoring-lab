FROM kalilinux/kali-rolling:latest

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Create a standard user account
RUN useradd -m -s /bin/bash hacker && \
    echo "hacker:password123" | chpasswd && \
    mkdir -p /home/hacker && \
    chown -R hacker:hacker /home/hacker

# Update and install basic tools
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    nmap \
    hydra \
    netcat-traditional \
    metasploit-framework \
    curl \
    wget \
    git \
    python3 \
    python3-pip \
    dnsutils \
    whois \
    vim \
    nano \
    tmux \
    iputils-ping \
    iproute2 \
    procps \
    tcpdump \
    ncat \
    john \
    nikto \
    dirb \
    sqlmap \
    gobuster \
    wfuzz \
    net-tools \
    ssh \
    jq \
    man-db \
    dnsmasq \
    hashcat \
    zsh \
    proxychains4 \
    smbclient \
    impacket-scripts \
    responder \
    && rm -rf /var/lib/apt/lists/*

# Install Python tools
RUN apt-get update && \
    apt-get install -y python3-scapy python3-requests python3-dnspython python3-pexpect python3-paramiko

# Add custom tools for specific attack scenarios
# Install iodine for DNS tunneling
RUN apt-get update && apt-get install -y iodine && rm -rf /var/lib/apt/lists/*

# Set up directory for attack scripts and logs
RUN mkdir -p /scenarios /scripts /var/log

# Create log file
RUN touch /var/log/attacker.log && chmod 666 /var/log/attacker.log

# Set up a ZSH shell with a custom prompt to show we're in the attacker machine
RUN sed -i 's/ZSH_THEME="kali"/ZSH_THEME="bira"/' /root/.zshrc && \
    echo 'PROMPT="%{$fg[red]%}[attacker]%{$reset_color%} $PROMPT"' >> /root/.zshrc

# Configure ZSH for the hacker user as well
RUN cp -r /root/.oh-my-zsh /home/hacker/ && \
    cp /root/.zshrc /home/hacker/ && \
    sed -i 's/ZSH_THEME="kali"/ZSH_THEME="bira"/' /home/hacker/.zshrc && \
    echo 'PROMPT="%{$fg[red]%}[attacker]%{$reset_color%} $PROMPT"' >> /home/hacker/.zshrc && \
    chown -R hacker:hacker /home/hacker/.oh-my-zsh /home/hacker/.zshrc

# Add hacker to sudoers
RUN echo "hacker ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Create a simple command logger
RUN echo 'function log_command() { echo "$(date +"%Y-%m-%d %H:%M:%S") - $BASH_COMMAND" >> /var/log/attacker.log; }' >> /root/.bashrc && \
    echo 'trap log_command DEBUG' >> /root/.bashrc

# Copy any additional scripts
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh 2>/dev/null || true

# Expose common ports
EXPOSE 22 80 443 8080

# Keep container running
CMD ["/bin/bash", "-c", "sleep infinity"]
