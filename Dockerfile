# AlpiNet - Lightweight Alpine-based networking toolbox for GNS3
FROM alpine:latest

# Metadata
LABEL maintainer="nazDridoy <nazdridoy399@gmail.com>"
LABEL description="Lightweight Alpine-based networking toolbox for GNS3"
LABEL version="1.1.0"

# Install essential networking and system utilities
RUN apk --no-cache add \
    # Core networking tools
    iproute2 \
    iputils \
    bind-tools \
    tcpdump \
    nmap \
    nmap-scripts \
    curl \
    wget \
    openssh-client \
    net-tools \
    iperf3 \
    mtr \
    socat \
    netcat-openbsd \
    traceroute \
    bridge-utils \
    vlan \
    ethtool \
    # Firewall tools
    iptables \
    ip6tables \
    nftables \
    # File transfer clients
    lftp \
    tftp-hpa \
    samba-client \
    # System utilities
    bash \
    bash-completion \
    vim \
    nano \
    less \
    git \
    tmux \
    screen \
    htop \
    procps \
    util-linux \
    coreutils \
    grep \
    sed \
    gawk \
    findutils \
    # Network testing
    iperf \
    # Python and tools
    python3 \
    py3-pip \
    # Additional utilities
    ca-certificates \
    openssl \
    tzdata \
    jq \
    tree \
    file \
    rsync \
    tar \
    gzip \
    bzip2 \
    xz \
    dumb-init \
    busybox-extras \
    && rm -rf /var/cache/apk/*

# Install Python networking tools
RUN pip3 install --no-cache-dir --break-system-packages \
    scapy \
    netaddr \
    ipython \
    requests

# Set bash as default shell
RUN sed -i 's|/bin/ash|/bin/bash|g' /etc/passwd

# Set up bash configuration
RUN echo 'PS1="\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]# "' >> /root/.bashrc && \
    echo 'alias ll="ls -lah"' >> /root/.bashrc && \
    echo 'alias la="ls -A"' >> /root/.bashrc && \
    echo 'alias l="ls -CF"' >> /root/.bashrc && \
    echo 'export EDITOR=vim' >> /root/.bashrc

# Create a welcome message
RUN echo '#!/bin/bash' > /etc/profile.d/motd.sh && \
    echo 'cat << "EOF"' >> /etc/profile.d/motd.sh && \
    echo '      .o.       oooo              o8o  ooooo      ooo               .   ' >> /etc/profile.d/motd.sh && \
    echo '     .888.      `888              `"'\''  `888b.     `8'\''             .o8   ' >> /etc/profile.d/motd.sh && \
    echo '    .8"888.      888  oo.ooooo.  oooo   8 `88b.    8   .ooooo.  .o888oo ' >> /etc/profile.d/motd.sh && \
    echo '   .8'\'' `888.     888   888'\'' `88b `888   8   `88b.  8  d88'\'' `88b   888   ' >> /etc/profile.d/motd.sh && \
    echo '  .88ooo8888.    888   888   888  888   8     `88b.8  888ooo888   888   ' >> /etc/profile.d/motd.sh && \
    echo ' .8'\''     `888.   888   888   888  888   8       `888  888    .o   888 . ' >> /etc/profile.d/motd.sh && \
    echo 'o88o     o8888o o888o  888bod8P'\'' o888o o8o        `8  `Y8bod8P'\''   "888" ' >> /etc/profile.d/motd.sh && \
    echo '                       888                                              ' >> /etc/profile.d/motd.sh && \
    echo '                      o888o                                             ' >> /etc/profile.d/motd.sh && \
    echo '                                                                        .' >> /etc/profile.d/motd.sh && \
    echo '' >> /etc/profile.d/motd.sh && \
    echo '  AlpiNet - Lightweight Alpine-based Networking Toolbox' >> /etc/profile.d/motd.sh && \
    echo '  Type "alpinet-tools" for available utilities' >> /etc/profile.d/motd.sh && \
    echo 'EOF' >> /etc/profile.d/motd.sh && \
    chmod +x /etc/profile.d/motd.sh

# Create a helper script to list available tools
RUN echo '#!/bin/bash' > /usr/local/bin/alpinet-tools && \
    echo 'echo "=== AlpiNet Available Tools ==="' >> /usr/local/bin/alpinet-tools && \
    echo 'echo ""' >> /usr/local/bin/alpinet-tools && \
    echo 'echo "Network Utilities:"' >> /usr/local/bin/alpinet-tools && \
    echo 'echo "  ip, ifconfig, route, ping, traceroute, mtr, telnet"' >> /usr/local/bin/alpinet-tools && \
    echo 'echo "  tcpdump, nmap, curl, wget, netcat, socat"' >> /usr/local/bin/alpinet-tools && \
    echo 'echo "  iperf, iperf3, arping (from iputils), ethtool"' >> /usr/local/bin/alpinet-tools && \
    echo 'echo ""' >> /usr/local/bin/alpinet-tools && \
    echo 'echo "Firewall Tools:"' >> /usr/local/bin/alpinet-tools && \
    echo 'echo "  iptables, ip6tables, nftables"' >> /usr/local/bin/alpinet-tools && \
    echo 'echo ""' >> /usr/local/bin/alpinet-tools && \
    echo 'echo "File Transfer:"' >> /usr/local/bin/alpinet-tools && \
    echo 'echo "  ftp (lftp), tftp, smbclient"' >> /usr/local/bin/alpinet-tools && \
    echo 'echo ""' >> /usr/local/bin/alpinet-tools && \
    echo 'echo "DNS Tools:"' >> /usr/local/bin/alpinet-tools && \
    echo 'echo "  host, nslookup, dig"' >> /usr/local/bin/alpinet-tools && \
    echo 'echo ""' >> /usr/local/bin/alpinet-tools && \
    echo 'echo "System Tools:"' >> /usr/local/bin/alpinet-tools && \
    echo 'echo "  vim, nano, git, tmux, screen, htop"' >> /usr/local/bin/alpinet-tools && \
    echo 'echo ""' >> /usr/local/bin/alpinet-tools && \
    echo 'echo "Python Tools:"' >> /usr/local/bin/alpinet-tools && \
    echo 'echo "  python3, ipython, scapy"' >> /usr/local/bin/alpinet-tools && \
    echo 'echo ""' >> /usr/local/bin/alpinet-tools && \
    chmod +x /usr/local/bin/alpinet-tools

# Set working directory
WORKDIR /root

# Create startup script with custom initialization support
# Users can create /root/init.sh for custom startup tasks
RUN printf '#!/bin/sh\n\
    # Re-exec with dumb-init if PID 1\n\
    [ $$ -eq 1 ] && exec dumb-init -- "$0" "$@"\n\
    \n\
    # Run user init script if it exists\n\
    [ -f /root/init.sh ] && [ -x /root/init.sh ] && /root/init.sh\n\
    \n\
    # Change to home directory\n\
    cd\n\
    \n\
    # Execute command or start interactive bash\n\
    if [ $# -gt 0 ]; then\n\
    \t"$@"\n\
    else\n\
    \tbash -i -l\n\
    fi\n' > /etc/alpinet-init.sh && chmod +x /etc/alpinet-init.sh

# Declare /root as a volume for persistence in GNS3
VOLUME ["/root"]

# Use ENTRYPOINT for proper init handling
ENTRYPOINT ["/etc/alpinet-init.sh"]
