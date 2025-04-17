# Name: CTI Threat Hunting Workspace
# Description: Specialized workspace for threat hunting operations
# Category: Security

FROM kasmweb/core-ubuntu-focal:latest
USER root

ENV HOME /home/kasm-default-profile
ENV STARTUPDIR /dockerstartup
ENV INST_SCRIPTS $STARTUPDIR/install
WORKDIR $HOME

# Install common tools as a single layer to reduce image size
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    python3-pip \
    python3-venv \
    nmap \
    whois \
    traceroute \
    dnsutils \
    netcat \
    apt-transport-https \
    ca-certificates \
    gnupg \
    firefox \
    jq \
    iputils-ping \
    unzip \
    openssh-client \
    vim \
    tmux \
    net-tools \
    tcpdump \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Chrome
RUN curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    google-chrome-stable \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install OSINT and Threat Hunting tools
RUN pip3 install --no-cache-dir \
    shodan \
    censys \
    maltego-trx \
    theHarvester \
    dnstwist \
    yara-python \
    pymisp \
    thehive4py \
    OTXv2 \
    requests \
    beautifulsoup4 \
    && pip3 cache purge

# Install Tor Browser
RUN apt-get update && apt-get install -y --no-install-recommends \
    tor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /opt/tor-browser \
    && curl -sSL "https://www.torproject.org/dist/torbrowser/12.0.6/tor-browser-linux64-12.0.6_ALL.tar.xz" | tar -xJf - -C /opt/tor-browser --strip-components=1 \
    && ln -s /opt/tor-browser/start-tor-browser.desktop $HOME/Desktop/tor-browser.desktop \
    && chmod +x /opt/tor-browser/start-tor-browser

# Install additional security tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    wireshark \
    tshark \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install CyberChef
RUN mkdir -p /opt/cyberchef \
    && curl -sSL "https://github.com/gchq/CyberChef/releases/download/v10.5.2/CyberChef_v10.5.2.zip" -o /tmp/cyberchef.zip \
    && unzip /tmp/cyberchef.zip -d /opt/cyberchef \
    && rm /tmp/cyberchef.zip

# Install Nuclei
RUN curl -sSL https://get.golang.org/go_installer | sh -s -- -v 1.20 \
    && export PATH=$PATH:/root/.go/bin \
    && go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest \
    && cp /root/go/bin/nuclei /usr/local/bin/ \
    && nuclei -update-templates

# Create desktop shortcuts for CTI tools
RUN mkdir -p $HOME/Desktop \
    && echo "[Desktop Entry]\nVersion=1.0\nType=Application\nName=TheHive\nComment=Security Incident Response Platform\nExec=google-chrome-stable http://localhost:9000\nIcon=\nPath=\nTerminal=false\nStartupNotify=false" > $HOME/Desktop/thehive.desktop \
    && echo "[Desktop Entry]\nVersion=1.0\nType=Application\nName=MISP\nComment=Threat Intelligence Platform\nExec=google-chrome-stable http://localhost:8080\nIcon=\nPath=\nTerminal=false\nStartupNotify=false" > $HOME/Desktop/misp.desktop \
    && echo "[Desktop Entry]\nVersion=1.0\nType=Application\nName=Cortex\nComment=Observable Analysis Engine\nExec=google-chrome-stable http://localhost:9001\nIcon=\nPath=\nTerminal=false\nStartupNotify=false" > $HOME/Desktop/cortex.desktop \
    && echo "[Desktop Entry]\nVersion=1.0\nType=Application\nName=GRR\nComment=Rapid Response Framework\nExec=google-chrome-stable http://localhost:8001\nIcon=\nPath=\nTerminal=false\nStartupNotify=false" > $HOME/Desktop/grr.desktop \
    && echo "[Desktop Entry]\nVersion=1.0\nType=Application\nName=CyberChef\nComment=Cyber Swiss Army Knife\nExec=google-chrome-stable /opt/cyberchef/CyberChef_v10.5.2.html\nIcon=\nPath=\nTerminal=false\nStartupNotify=false" > $HOME/Desktop/cyberchef.desktop

# Add custom bookmarks to browsers
RUN mkdir -p $HOME/.mozilla/firefox/bookmarks \
    && echo '<!DOCTYPE NETSCAPE-Bookmark-file-1>\n<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">\n<TITLE>Bookmarks</TITLE>\n<H1>Bookmarks Menu</H1>\n<DL><p>\n<DT><H3>Threat Intelligence</H3>\n<DL><p>\n<DT><A HREF="https://virustotal.com">VirusTotal</A>\n<DT><A HREF="https://www.shodan.io">Shodan</A>\n<DT><A HREF="https://otx.alienvault.com">AlienVault OTX</A>\n<DT><A HREF="https://exchange.xforce.ibmcloud.com">IBM X-Force Exchange</A>\n<DT><A HREF="https://urlscan.io">URLScan.io</A>\n<DT><A HREF="https://threatcrowd.org">ThreatCrowd</A>\n<DT><A HREF="https://threatminer.org">ThreatMiner</A>\n<DT><A HREF="https://malshare.com">MalShare</A>\n<DT><A HREF="https://hybrid-analysis.com">Hybrid Analysis</A>\n<DT><A HREF="https://app.any.run">Any.Run</A>\n<DT><A HREF="https://viz.greynoise.io">GreyNoise</A>\n<DT><A HREF="https://censys.io">Censys</A>\n</DL><p>\n</DL><p>' > $HOME/.mozilla/firefox/bookmarks/threat-hunting-bookmarks.html

# Create setup script to copy bookmarks when the container starts
RUN echo '#!/bin/bash\n\
# Import bookmarks to Firefox\n\
FIREFOX_PROFILE=$(find $HOME/.mozilla/firefox -name "*.default-release")\n\
if [ -n "$FIREFOX_PROFILE" ]; then\n\
    cp $HOME/.mozilla/firefox/bookmarks/threat-hunting-bookmarks.html $FIREFOX_PROFILE/bookmarks.html\n\
fi\n\
# Launch default shell\n\
exec bash' > $HOME/setup.sh \
    && chmod +x $HOME/setup.sh

# Set permissions
RUN chmod +x $HOME/Desktop/*.desktop \
    && chown -R 1000:1000 $HOME

# Create secure ~/.bashrc with useful aliases and functions
RUN echo 'alias ll="ls -la"\n\
alias nmap-quick="nmap -T4 -F"\n\
alias nmap-full="nmap -T4 -A -v"\n\
alias tcpdump-quick="tcpdump -n -i any -c 100"\n\
\n\
# Function to check IP reputation\n\
iprep() {\n\
    if [ -z "$1" ]; then\n\
        echo "Usage: iprep <ip-address>"\n\
        return 1\n\
    fi\n\
    echo "Checking IP reputation for: $1"\n\
    curl -s "https://ipinfo.io/$1" | jq\n\
}\n\
\n\
# Function to check domain reputation\n\
domainrep() {\n\
    if [ -z "$1" ]; then\n\
        echo "Usage: domainrep <domain>"\n\
        return 1\n\
    fi\n\
    echo "Checking domain information for: $1"\n\
    whois "$1"\n\
    echo -e "\nDNS records:"\n\
    host -t ANY "$1"\n\
}\n\
\n\
# Print welcome message\n\
echo -e "\n\e[1;32m=== CTI Threat Hunting Workspace ===\e[0m"\n\
echo -e "Available tools:"\n\
echo -e " - OSINT: Shodan, Censys, theHarvester, dnstwist"\n\
echo -e " - Analysis: CyberChef, Wireshark, tshark, nmap"\n\
echo -e " - Browsers: Chrome, Firefox, Tor"\n\
echo -e " - Custom shortcuts on Desktop"\n\
echo -e " - Custom functions: iprep, domainrep"\n\
echo -e "\n\e[1;33mHappy Hunting!\e[0m\n"' > $HOME/.bashrc

# Switch back to default user
USER 1000

# Run setup script when container starts
ENTRYPOINT ["/bin/bash", "-c", "$HOME/setup.sh"]
