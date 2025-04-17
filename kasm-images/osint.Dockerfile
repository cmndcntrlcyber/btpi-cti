# Name: CTI OSINT Investigation Workspace
# Description: Specialized workspace for open-source intelligence gathering
# Category: Security

FROM kasmweb/core-ubuntu-focal:latest
USER root

ENV HOME /home/kasm-default-profile
ENV STARTUPDIR /dockerstartup
ENV INST_SCRIPTS $STARTUPDIR/install
WORKDIR $HOME

# Install common tools in a single layer to reduce image size
RUN apt-get update && apt-get install -y --no-install-recommends \
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
    net-tools \
    firefox \
    imagemagick \
    exiftool \
    ffmpeg \
    libxml2-utils \
    xmlstarlet \
    vim \
    tmux \
    unzip \
    gnupg \
    apt-transport-https \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Chrome
RUN curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    google-chrome-stable \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Tor Browser
RUN apt-get update && apt-get install -y --no-install-recommends \
    tor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /opt/tor-browser \
    && curl -sSL "https://www.torproject.org/dist/torbrowser/12.0.6/tor-browser-linux64-12.0.6_ALL.tar.xz" | tar -xJf - -C /opt/tor-browser --strip-components=1 \
    && ln -s /opt/tor-browser/start-tor-browser.desktop $HOME/Desktop/tor-browser.desktop \
    && chmod +x /opt/tor-browser/start-tor-browser

# Install OSINT tools
RUN pip3 install --no-cache-dir \
    shodan \
    censys \
    osrframework \
    holehe \
    maigret \
    twint \
    phoneinfoga \
    dnstwist \
    instaloader \
    pwnedpasswords \
    pyWhat \
    sherlock \
    whatsmyname \
    && pip3 cache purge

# Install SpiderFoot
RUN git clone --depth 1 https://github.com/smicallef/spiderfoot.git /opt/spiderfoot && \
    cd /opt/spiderfoot && \
    pip3 install -r requirements.txt

# Install Recon-ng
RUN git clone --depth 1 https://github.com/lanmaster53/recon-ng.git /opt/recon-ng && \
    cd /opt/recon-ng && \
    pip3 install -r REQUIREMENTS

# Install theHarvester
RUN git clone --depth 1 https://github.com/laramies/theHarvester.git /opt/theharvester && \
    cd /opt/theharvester && \
    pip3 install -r requirements/base.txt

# Install PhotonKit for web reconnaissance
RUN pip3 install --no-cache-dir photon && \
    pip3 cache purge

# Install Maltego Community Edition
RUN mkdir -p /opt/maltego && \
    curl -sSL https://maltego-downloads.s3.us-east-2.amazonaws.com/linux/Maltego.v4.3.1.linux.zip -o /tmp/maltego.zip && \
    unzip /tmp/maltego.zip -d /opt/maltego && \
    rm /tmp/maltego.zip && \
    ln -s /opt/maltego/maltego /usr/local/bin/maltego

# Install CyberChef
RUN mkdir -p /opt/cyberchef \
    && curl -sSL "https://github.com/gchq/CyberChef/releases/download/v10.5.2/CyberChef_v10.5.2.zip" -o /tmp/cyberchef.zip \
    && unzip /tmp/cyberchef.zip -d /opt/cyberchef \
    && rm /tmp/cyberchef.zip

# Create desktop shortcuts
RUN mkdir -p $HOME/Desktop \
    && echo "[Desktop Entry]\nVersion=1.0\nType=Application\nName=SpiderFoot\nComment=OSINT Reconnaissance Tool\nExec=bash -c 'cd /opt/spiderfoot && python3 sf.py -l 127.0.0.1:5001 & google-chrome-stable http://127.0.0.1:5001 --new-window'\nIcon=\nPath=/opt/spiderfoot\nTerminal=false\nStartupNotify=false" > $HOME/Desktop/spiderfoot.desktop \
    && echo "[Desktop Entry]\nVersion=1.0\nType=Application\nName=Maltego\nComment=OSINT and Graphical Link Analysis\nExec=maltego\nIcon=\nPath=/opt/maltego\nTerminal=false\nStartupNotify=false" > $HOME/Desktop/maltego.desktop \
    && echo "[Desktop Entry]\nVersion=1.0\nType=Application\nName=theHarvester\nComment=E-mail, subdomain and name harvester\nExec=gnome-terminal -- bash -c 'cd /opt/theharvester && python3 theHarvester.py -h; bash'\nIcon=\nPath=/opt/theharvester\nTerminal=true\nStartupNotify=false" > $HOME/Desktop/theharvester.desktop \
    && echo "[Desktop Entry]\nVersion=1.0\nType=Application\nName=Recon-ng\nComment=Web Reconnaissance Framework\nExec=gnome-terminal -- bash -c 'cd /opt/recon-ng && ./recon-ng; bash'\nIcon=\nPath=/opt/recon-ng\nTerminal=true\nStartupNotify=false" > $HOME/Desktop/reconng.desktop \
    && echo "[Desktop Entry]\nVersion=1.0\nType=Application\nName=CyberChef\nComment=Cyber Swiss Army Knife\nExec=google-chrome-stable /opt/cyberchef/CyberChef_v10.5.2.html\nIcon=\nPath=\nTerminal=false\nStartupNotify=false" > $HOME/Desktop/cyberchef.desktop

# Create OSINT Bookmarks
RUN mkdir -p $HOME/.mozilla/firefox/bookmarks && \
    echo '<?xml version="1.0" encoding="UTF-8"?>' > $HOME/.mozilla/firefox/bookmarks/osint-bookmarks.html && \
    echo '<!DOCTYPE NETSCAPE-Bookmark-file-1>' >> $HOME/.mozilla/firefox/bookmarks/osint-bookmarks.html && \
    echo '<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">' >> $HOME/.mozilla/firefox/bookmarks/osint-bookmarks.html && \
    echo '<TITLE>Bookmarks</TITLE>' >> $HOME/.mozilla/firefox/bookmarks/osint-bookmarks.html && \
    echo '<H1>Bookmarks Menu</H1>' >> $HOME/.mozilla/firefox/bookmarks/osint-bookmarks.html && \
    echo '<DL><p>' >> $HOME/.mozilla/firefox/bookmarks/osint-bookmarks.html && \
    echo '    <DT><H3>OSINT Tools</H3>' >> $HOME/.mozilla/firefox/bookmarks/osint-bookmarks.html && \
    echo '    <DL><p>' >> $HOME/.mozilla/firefox/bookmarks/osint-bookmarks.html && \
    echo '        <DT><A HREF="https://www.shodan.io/">Shodan</A>' >> $HOME/.mozilla/firefox/bookmarks/osint-bookmarks.html && \
    echo '        <DT><A HREF="https://censys.io/">Censys</A>' >> $HOME/.mozilla/firefox/bookmarks/osint-bookmarks.html && \
    echo '        <DT><A HREF="https://www.virustotal.com/">VirusTotal</A>' >> $HOME/.mozilla/firefox/bookmarks/osint-bookmarks.html && \
    echo '        <DT><A HREF="https://urlscan.io/">URLScan.io</A>' >> $HOME/.mozilla/firefox/bookmarks/osint-bookmarks.html && \
    echo '        <DT><A HREF="https://otx.alienvault.com/">AlienVault OTX</A>' >> $HOME/.mozilla/firefox/bookmarks/osint-bookmarks.html && \
    echo '        <DT><A HREF="https://www.hybrid-analysis.com/">Hybrid Analysis</A>' >> $HOME/.mozilla/firefox/bookmarks/osint-bookmarks.html && \
    echo '        <DT><A HREF="https://www.google.com/advanced_search">Google Advanced</A>' >> $HOME/.mozilla/firefox/bookmarks/osint-bookmarks.html && \
    echo '        <DT><A HREF="https://haveibeenpwned.com/">Have I Been Pwned</A>' >> $HOME/.mozilla/firefox/bookmarks/osint-bookmarks.html && \
    echo '        <DT><A HREF="https://archive.org/web/">Wayback Machine</A>' >> $HOME/.mozilla/firefox/bookmarks/osint-bookmarks.html && \
    echo '    </DL></p>' >> $HOME/.mozilla/firefox/bookmarks/osint-bookmarks.html && \
    echo '</DL></p>' >> $HOME/.mozilla/firefox/bookmarks/osint-bookmarks.html

# Create setup script to copy bookmarks when container starts
RUN echo '#!/bin/bash\n\
# Import bookmarks to Firefox\n\
FIREFOX_PROFILE=$(find $HOME/.mozilla/firefox -name "*.default-release")\n\
if [ -n "$FIREFOX_PROFILE" ]; then\n\
    cp $HOME/.mozilla/firefox/bookmarks/osint-bookmarks.html $FIREFOX_PROFILE/bookmarks.html\n\
fi\n\
# Launch default shell\n\
exec bash' > $HOME/setup.sh \
    && chmod +x $HOME/setup.sh

# Create useful bash aliases and functions
RUN echo '# OSINT Aliases and Functions' > $HOME/.osint_profile && \
    echo 'alias ll="ls -la"' >> $HOME/.osint_profile && \
    echo 'alias myip="curl -s https://ifconfig.me"' >> $HOME/.osint_profile && \
    echo 'alias dnsinfo="host -a"' >> $HOME/.osint_profile && \
    echo 'alias headers="curl -I"' >> $HOME/.osint_profile && \
    echo 'alias history_clean="history -c && history -w"' >> $HOME/.osint_profile && \
    echo '' >> $HOME/.osint_profile && \
    echo '# Function to check domain info' >> $HOME/.osint_profile && \
    echo 'domaininfo() {' >> $HOME/.osint_profile && \
    echo '    if [ -z "$1" ]; then' >> $HOME/.osint_profile && \
    echo '        echo "Usage: domaininfo <domain>"' >> $HOME/.osint_profile && \
    echo '        return 1' >> $HOME/.osint_profile && \
    echo '    fi' >> $HOME/.osint_profile && \
    echo '' >> $HOME/.osint_profile && \
    echo '    echo -e "\n=== WHOIS Information ===\n"' >> $HOME/.osint_profile && \
    echo '    whois "$1"' >> $HOME/.osint_profile && \
    echo '' >> $HOME/.osint_profile && \
    echo '    echo -e "\n=== DNS Information ===\n"' >> $HOME/.osint_profile && \
    echo '    host -a "$1"' >> $HOME/.osint_profile && \
    echo '' >> $HOME/.osint_profile && \
    echo '    echo -e "\n=== HTTP Headers ===\n"' >> $HOME/.osint_profile && \
    echo '    curl -I -s "http://$1"' >> $HOME/.osint_profile && \
    echo '' >> $HOME/.osint_profile && \
    echo '    echo -e "\n=== Website Screenshot ===\n"' >> $HOME/.osint_profile && \
    echo '    echo "Use '\''screenshot $1'\'' to take a screenshot"' >> $HOME/.osint_profile && \
    echo '}' >> $HOME/.osint_profile && \
    echo '' >> $HOME/.osint_profile && \
    echo '# Function to check email reputation' >> $HOME/.osint_profile && \
    echo 'emailcheck() {' >> $HOME/.osint_profile && \
    echo '    if [ -z "$1" ]; then' >> $HOME/.osint_profile && \
    echo '        echo "Usage: emailcheck <email>"' >> $HOME/.osint_profile && \
    echo '        return 1' >> $HOME/.osint_profile && \
    echo '    fi' >> $HOME/.osint_profile && \
    echo '' >> $HOME/.osint_profile && \
    echo '    echo -e "\n=== Checking Email: $1 ===\n"' >> $HOME/.osint_profile && \
    echo '    holehe "$1"' >> $HOME/.osint_profile && \
    echo '}' >> $HOME/.osint_profile && \
    echo '' >> $HOME/.osint_profile && \
    echo '# Function to take website screenshot' >> $HOME/.osint_profile && \
    echo 'screenshot() {' >> $HOME/.osint_profile && \
    echo '    if [ -z "$1" ]; then' >> $HOME/.osint_profile && \
    echo '        echo "Usage: screenshot <url>"' >> $HOME/.osint_profile && \
    echo '        return 1' >> $HOME/.osint_profile && \
    echo '    fi' >> $HOME/.osint_profile && \
    echo '' >> $HOME/.osint_profile && \
    echo '    TIMESTAMP=$(date +%Y%m%d-%H%M%S)' >> $HOME/.osint_profile && \
    echo '    URL=$1' >> $HOME/.osint_profile && \
    echo '    FILENAME="screenshot-${TIMESTAMP}.png"' >> $HOME/.osint_profile && \
    echo '' >> $HOME/.osint_profile && \
    echo '    echo "Taking screenshot of $URL..."' >> $HOME/.osint_profile && \
    echo '    google-chrome-stable --headless --disable-gpu --window-size=1280,1696 --screenshot="$HOME/screenshots/$FILENAME" "$URL"' >> $HOME/.osint_profile && \
    echo '    echo "Screenshot saved to $HOME/screenshots/$FILENAME"' >> $HOME/.osint_profile && \
    echo '}' >> $HOME/.osint_profile && \
    echo '' >> $HOME/.osint_profile && \
    echo '# Create screenshots directory' >> $HOME/.osint_profile && \
    echo 'mkdir -p "$HOME/screenshots"' >> $HOME/.osint_profile && \
    echo '' >> $HOME/.osint_profile && \
    echo '# Start SpiderFoot function' >> $HOME/.osint_profile && \
    echo 'spiderfoot() {' >> $HOME/.osint_profile && \
    echo '    cd /opt/spiderfoot' >> $HOME/.osint_profile && \
    echo '    python3 sf.py -l 127.0.0.1:5001 &' >> $HOME/.osint_profile && \
    echo '    google-chrome-stable http://127.0.0.1:5001 --new-window' >> $HOME/.osint_profile && \
    echo '}' >> $HOME/.osint_profile && \
    echo '' >> $HOME/.osint_profile && \
    echo '# Welcome Message' >> $HOME/.osint_profile && \
    echo 'echo -e "\n\e[1;36m=== OSINT INVESTIGATION WORKSPACE ===\e[0m"' >> $HOME/.osint_profile && \
    echo 'echo -e "Available tools:"' >> $HOME/.osint_profile && \
    echo 'echo -e " - SpiderFoot: Web reconnaissance framework"' >> $HOME/.osint_profile && \
    echo 'echo -e " - Maltego: Visual link analysis"' >> $HOME/.osint_profile && \
    echo 'echo -e " - theHarvester: Email and subdomain gathering"' >> $HOME/.osint_profile && \
    echo 'echo -e " - Recon-ng: Web reconnaissance framework"' >> $HOME/.osint_profile && \
    echo 'echo -e " - Holehe, Maigret, Sherlock: Username and email checkers"' >> $HOME/.osint_profile && \
    echo 'echo -e " - Multiple browsers with OSINT bookmarks"' >> $HOME/.osint_profile && \
    echo 'echo -e "\nUseful commands:"' >> $HOME/.osint_profile && \
    echo 'echo -e " - domaininfo <domain>: Get information about a domain"' >> $HOME/.osint_profile && \
    echo 'echo -e " - emailcheck <email>: Check email address information"' >> $HOME/.osint_profile && \
    echo 'echo -e " - screenshot <url>: Take screenshot of a website"' >> $HOME/.osint_profile && \
    echo 'echo -e " - spiderfoot: Start SpiderFoot web interface"' >> $HOME/.osint_profile && \
    echo 'echo -e "\e[1;33m\nHappy hunting!\e[0m\n"' >> $HOME/.osint_profile && \
    echo '' >> $HOME/.osint_profile && \
    echo 'source $HOME/.osint_profile' >> $HOME/.bashrc

# Set permissions
RUN chmod +x $HOME/Desktop/*.desktop \
    && chown -R 1000:1000 $HOME

# Switch back to default user
USER 1000

# Run setup script when container starts
ENTRYPOINT ["/bin/bash", "-c", "$HOME/setup.sh"]
