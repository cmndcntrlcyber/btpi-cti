# Name: CTI OSINT Investigation Workspace
# Description: Specialized workspace for open-source intelligence gathering
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
    jq \
    whois \
    dnsutils \
    iputils-ping \
    traceroute \
    && apt-get clean

# Install multiple browsers for OSINT
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    && curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update && apt-get install -y \
    google-chrome-stable \
    firefox \
    && apt-get clean

# Install Tor Browser
RUN apt-get update && apt-get install -y \
    tor \
    && apt-get clean

RUN wget -q -O /tmp/tor-browser.tar.xz https://www.torproject.org/dist/torbrowser/11.0.14/tor-browser-linux64-11.0.14_en-US.tar.xz && \
    mkdir -p /opt/tor-browser && \
    tar -xf /tmp/tor-browser.tar.xz -C /opt/tor-browser --strip-components=1 && \
    rm /tmp/tor-browser.tar.xz && \
    ln -s /opt/tor-browser/start-tor-browser.desktop $HOME/Desktop/tor-browser.desktop

# Install OSINT tools
RUN pip3 install --no-cache-dir \
    shodan \
    censys \
    theHarvester \
    dnstwist \
    osrframework \
    holehe \
    maigret \
    twint

# Install SpiderFoot
RUN git clone --depth 1 https://github.com/smicallef/spiderfoot.git /opt/spiderfoot && \
    cd /opt/spiderfoot && \
    pip3 install -r requirements.txt

# Install Maltego
RUN mkdir -p /opt/maltego && \
    wget -q -O /tmp/maltego.zip https://maltego-downloads.s3.us-east-2.amazonaws.com/linux/Maltego.v4.3.0.linux.zip && \
    unzip /tmp/maltego.zip -d /opt/maltego && \
    rm /tmp/maltego.zip && \
    ln -s /opt/maltego/maltego /usr/local/bin/maltego

# Create desktop shortcuts
RUN mkdir -p $HOME/Desktop
COPY ./resources/shortcuts/spiderfoot.desktop $HOME/Desktop/
COPY ./resources/shortcuts/maltego.desktop $HOME/Desktop/
COPY ./resources/shortcuts/shodan.desktop $HOME/Desktop/

# Add OSINT bookmarks
COPY ./resources/bookmarks/osint-bookmarks.html $HOME/bookmarks.html

# Set permissions
RUN chmod +x $HOME/Desktop/*.desktop && \
    chown -R 1000:1000 $HOME

# Switch back to default user
USER 1000
