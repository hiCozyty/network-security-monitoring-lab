FROM rockylinux/rockylinux:8

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Create a standard user for more realistic environment - with debug output
RUN useradd -m -s /bin/bash user1 && \
    id user1 && \
    echo "user1:password123" | chpasswd && \
    mkdir -p /home/user1/Documents && \
    echo "This is sensitive company data" > /home/user1/Documents/confidential.txt && \
    chown -R user1:user1 /home/user1 && \
    ls -la /home/

# Add user1 to sudoers
RUN echo "user1 ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Install required packages
RUN dnf update -y && \
    dnf install -y epel-release && \
    dnf install -y dnf-plugins-core && \
    dnf config-manager --set-enabled powertools && \
    dnf install -y \
    wget \
    git \
    gcc \
    gcc-c++ \
    make \
    cmake \
    flex \
    bison \
    libpcap-devel \
    openssl-devel \
    python3 \
    python3-devel \
    python3-pip \
    swig \
    zlib-devel \
    tcpdump \
    net-tools \
    iproute \
    procps-ng \
    vim \
    nano \
    tmux \
    diffutils \
    bind-utils \
    iputils \
    openssh-server \
    httpd \
    mariadb-server \
    jq \
    sudo

# Set custom bash prompt for the defender
RUN echo 'export PS1="\[\033[1;32m\][defender]\[\033[0m\] \u@\h:\w\\$ "' >> /root/.bashrc && \
    echo 'export PS1="\[\033[1;32m\][defender]\[\033[0m\] \u@\h:\w\\$ "' >> /home/user1/.bashrc

# Configure web server and create a basic site
RUN mkdir -p /var/www/html && \
    echo "<html><body><h1>Internal Company Website</h1><p>Welcome to our secure server.</p></body></html>" > /var/www/html/index.html && \
    echo "<?php phpinfo(); ?>" > /var/www/html/info.php

# Install Suricata
RUN dnf install -y dnf-plugins-core && \
    dnf copr enable -y @oisf/suricata-6.0 && \
    dnf install -y suricata && \
    suricata-update update-sources && \
    suricata-update

# Install Zeek from EPEL
RUN dnf install -y zeek-core zeekctl zeek-devel zeek-zkg && \
    echo 'export PATH=/usr/bin:$PATH' >> /root/.bashrc && \
    echo 'export PATH=/usr/bin:$PATH' >> /home/user1/.bashrc

# Create directories for logs and data
RUN mkdir -p /data/logs /data/pcaps /scripts /var/log/suricata /opt/zeek/logs/current && \
    chmod -R 777 /var/log/suricata /opt/zeek/logs && \
    chown -R user1:user1 /data

# Link Zeek directories for compatibility with the script
RUN mkdir -p /opt/zeek/bin /opt/zeek/etc /opt/zeek/share/zeek/site /opt/zeek/scripts && \
    ln -sf /usr/bin/zeek /opt/zeek/bin/ && \
    ln -sf /usr/bin/zeekctl /opt/zeek/bin/ && \
    ln -sf /etc/zeek /opt/zeek/etc && \
    mkdir -p /opt/zeek/share/zeek/site && \
    ln -sf /usr/share/zeek/site/local.zeek /opt/zeek/share/zeek/site/

# Set up some vulnerable services for testing
# Simple FTP server with anonymous access
RUN dnf install -y vsftpd && \
    echo "anonymous_enable=YES" >> /etc/vsftpd/vsftpd.conf && \
    echo "anon_upload_enable=YES" >> /etc/vsftpd/vsftpd.conf && \
    echo "anon_mkdir_write_enable=YES" >> /etc/vsftpd/vsftpd.conf && \
    mkdir -p /var/ftp/pub && \
    echo "Welcome to our FTP server" > /var/ftp/pub/welcome.txt && \
    chmod 777 /var/ftp/pub

# Add a simple SSH configuration
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

# Create sample database for SQL injection testing
RUN dnf install -y mariadb-server && \
    systemctl enable mariadb && \
    mkdir -p /docker-entrypoint-initdb.d && \
    echo "CREATE DATABASE webapp; USE webapp; CREATE TABLE users (id INT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(50), password VARCHAR(50), email VARCHAR(100)); INSERT INTO users VALUES (1, 'admin', 'secret123', 'admin@example.com'), (2, 'user1', 'password123', 'user1@example.com');" > /docker-entrypoint-initdb.d/init.sql

# Set up Log4j vulnerable service for demonstration
RUN mkdir -p /opt/vulnerable-app && \
    cd /opt/vulnerable-app && \
    echo '#!/bin/bash' > start-vulnerable-app.sh && \
    echo 'echo "This would start a Log4j vulnerable application (simulated for the lab)"' >> start-vulnerable-app.sh && \
    echo 'echo "Listening on port 8080..."' >> start-vulnerable-app.sh && \
    echo 'while true; do sleep 10; done' >> start-vulnerable-app.sh && \
    chmod +x start-vulnerable-app.sh

# Configure firewall - allow common ports
RUN dnf install -y firewalld && \
    systemctl enable firewalld && \
    mkdir -p /etc/firewalld/services && \
    for port in 22 80 443 21 3306 8080; do \
    firewall-offline-cmd --add-port=$port/tcp; \
    done

# Create a simple start monitoring script directly in the Dockerfile
RUN mkdir -p /scripts && \
    echo '#!/bin/bash' > /scripts/start-monitoring.sh && \
    echo 'echo "Starting Suricata manually..."' >> /scripts/start-monitoring.sh && \
    echo 'suricata -c /etc/suricata/suricata.yaml -i eth0 --init-errors-fatal -D' >> /scripts/start-monitoring.sh && \
    echo 'echo "Starting Zeek manually..."' >> /scripts/start-monitoring.sh && \
    echo 'zeekctl deploy' >> /scripts/start-monitoring.sh && \
    echo 'echo "All monitoring services started."' >> /scripts/start-monitoring.sh && \
    chmod +x /scripts/start-monitoring.sh

# Verify user exists at the end of build
RUN echo "Final verification:" && id user1 && ls -la /home/

# Create startup script with user verification
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'echo "Verifying user1 exists on startup:"' >> /start.sh && \
    echo 'id user1' >> /start.sh && \
    echo 'ls -la /home/' >> /start.sh && \
    echo 'echo "Starting services..."' >> /start.sh && \
    echo 'service sshd start' >> /start.sh && \
    echo 'service httpd start' >> /start.sh && \
    echo 'service mariadb start' >> /start.sh && \
    echo 'service vsftpd start' >> /start.sh && \
    echo 'echo "All services started."' >> /start.sh && \
    echo 'tail -f /dev/null' >> /start.sh && \
    chmod +x /start.sh

# Expose common ports
EXPOSE 22 80 443 21 8080 3306

# Start services on container launch
CMD ["/start.sh"]
