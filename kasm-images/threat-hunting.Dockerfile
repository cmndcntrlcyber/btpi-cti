# Name: CTI Threat Hunting Workspace
# Description: Specialized workspace for threat hunting operations
# Category: Security

FROM kasmweb/core-ubuntu-focal:1.12.0
USER root

ENV HOME /home/kasm-default-profile
ENV STARTUPDIR /dockerstartup
ENV INST_SCRIPTS $STARTUPDIR/install
WORKDIR $HOME

# Install common tools
RUN apt-get update && apt-get install -y \
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
    && apt-get clean

# Install Chrome
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    && curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update && apt-get install -y \
    google-chrome-stable \
    && apt-get clean

# Install Firefox
RUN apt-get update && apt-get install -y \
    firefox \
    && apt-get clean

# Install OSINT tools
RUN pip3 install --no-cache-dir \
    shodan \
    censys \
    maltego-trx \
    theHarvester \
    dnstwist

# Install TheHive and MISP clients
RUN pip3 install --no-cache-dir \
    thehive4py \
    pymisp

# Create desktop shortcuts for CTI tools
RUN mkdir -p $HOME/Desktop
COPY ./resources/shortcuts/thehive.desktop $HOME/Desktop/
COPY ./resources/shortcuts/misp.desktop $HOME/Desktop/
COPY ./resources/shortcuts/cortex.desktop $HOME/Desktop/
COPY ./resources/shortcuts/grr.desktop $HOME/Desktop/

# Add custom bookmarks to browsers
COPY ./resources/bookmarks/threat-hunting-bookmarks.html $HOME/bookmarks.html

# Set permissions
RUN chmod +x $HOME/Desktop/*.desktop && \
    chown -R 1000:1000 $HOME

# Switch back to default user
USER 1000
