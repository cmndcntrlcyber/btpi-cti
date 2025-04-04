Name:           btpi-cti
Version:        1.0.0
Release:        1%{?dist}
Summary:        Blue Team Portable Infrastructure - Cyber Threat Intelligence

License:        MIT
URL:            https://github.com/cmndcntrlcyber/btpi-cti
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
Requires:       docker-ce >= 20.10.0, docker-compose >= 1.29.0, curl, wget, jq

%description
A comprehensive, ready-to-deploy Cyber Threat Intelligence (CTI) 
infrastructure using Docker containers. It integrates multiple 
industry-standard tools to enable effective threat hunting, 
incident response, and threat intelligence operations.

Components include:
* GRR Rapid Response: Live forensics and incident response framework
* TheHive: Security incident response platform
* Cortex: Observable analysis engine
* MISP: Threat intelligence platform
* Kasm Workspaces: Browser isolation and virtual desktop environment
* Portainer: Container management interface

%prep
%setup -q

%build
# Nothing to build

%install
mkdir -p %{buildroot}/opt/btpi-cti
mkdir -p %{buildroot}/var/log/btpi-cti
mkdir -p %{buildroot}/etc/btpi-cti
mkdir -p %{buildroot}%{_bindir}

# Copy files
cp -a * %{buildroot}/opt/btpi-cti/

# Create symlinks
ln -sf /opt/btpi-cti/deploy.sh %{buildroot}%{_bindir}/deploy-cti
ln -sf /opt/btpi-cti/cti-manage.sh %{buildroot}%{_bindir}/cti-manage
ln -sf /opt/btpi-cti/scripts/backup.sh %{buildroot}%{_bindir}/cti-backup
ln -sf /opt/btpi-cti/scripts/restore.sh %{buildroot}%{_bindir}/cti-restore
ln -sf /opt/btpi-cti/scripts/health-check.sh %{buildroot}%{_bindir}/cti-health-check
ln -sf /opt/btpi-cti/scripts/update.sh %{buildroot}%{_bindir}/cti-update

%files
%license LICENSE
%doc README.md docs/*
/opt/btpi-cti
/var/log/btpi-cti
/etc/btpi-cti
%{_bindir}/deploy-cti
%{_bindir}/cti-manage
%{_bindir}/cti-backup
%{_bindir}/cti-restore
%{_bindir}/cti-health-check
%{_bindir}/cti-update

%config(noreplace) /opt/btpi-cti/docker-compose.yml
%config(noreplace) /opt/btpi-cti/config.env
%config(noreplace) /opt/btpi-cti/configs/cortex/application.conf
%config(noreplace) /opt/btpi-cti/configs/thehive/application.conf
%config(noreplace) /opt/btpi-cti/configs/misp/config.php
%config(noreplace) /opt/btpi-cti/configs/grr/server.local.yaml
%config(noreplace) /opt/btpi-cti/configs/portainer/portainer.yml

%post
# Make scripts executable
chmod +x /opt/btpi-cti/deploy.sh
chmod +x /opt/btpi-cti/cti-manage.sh
chmod +x /opt/btpi-cti/scripts/*.sh
chmod +x /opt/btpi-cti/kasm-scripts/*.sh

# Display installation message
echo "BTPI-CTI has been installed successfully."
echo "To deploy the CTI infrastructure, run: deploy-cti"
echo "To manage the CTI infrastructure, run: cti-manage"
echo "For more information, see the documentation in /opt/btpi-cti/docs/"

%preun
# Stop all containers if running
if command -v docker-compose &> /dev/null && [ -f /opt/btpi-cti/docker-compose.yml ]; then
    cd /opt/btpi-cti && docker-compose down || true
fi

# Display removal message
echo "BTPI-CTI is being removed."
echo "Note: Docker volumes and data are not automatically removed."
echo "To remove all data, run: docker volume rm $(docker volume ls -q | grep cti) (after package removal)"

%changelog
* Thu Apr 04 2025 Command & Control Cyber <info@cmndcntrlcyber.com> - 1.0.0-1
- Initial package release
