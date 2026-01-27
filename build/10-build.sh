#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Main Build Script
###############################################################################
# This script follows the @ublue-os/bluefin pattern for build scripts.
# It uses set -eoux pipefail for strict error handling and debugging.
###############################################################################

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

# Enable nullglob for all glob operations to prevent failures on empty matches
shopt -s nullglob

echo "::group:: Copy Custom Files"

cp -r /ctx/custom/bin/bluefin-dx-groups /usr/bin/
chmod +x /usr/bin/bluefin-dx-groups


# Copy Brewfiles to standard location
mkdir -p /usr/share/ublue-os/homebrew/
cp /ctx/custom/brew/*.Brewfile /usr/share/ublue-os/homebrew/

# Consolidate Just Files
cp /ctx/oci/common/bluefin/usr/share/ublue-os/just/system.just /ctx/custom/ujust/
find /ctx/custom/ujust -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /usr/share/ublue-os/just/60-custom.just

# Copy Flatpak preinstall files
mkdir -p /etc/flatpak/preinstall.d/
cp /ctx/custom/flatpaks/*.preinstall /etc/flatpak/preinstall.d/

echo "::endgroup::"

echo "::group:: Install Gnome Extensions"

/ctx/build/build-gnome-extensions.sh

echo "::endgroup::"

echo "::group:: Install Packages"

# Install packages using dnf5
# Example: dnf5 install -y tmux

# Base packages
FEDORA_PACKAGES=(
    android-tools
    cockpit-bridge
    cockpit-machines
    cockpit-networkmanager
    cockpit-ostree
    cockpit-podman
    cockpit-selinux
    cockpit-storaged
    cockpit-system
    dbus-x11
    gum
    nautilus-gsconnect
    podman-compose
    podman-machine
    podman-tui
)

# Install all Fedora packages (bulk - safe from COPR injection)
echo "Installing ${#FEDORA_PACKAGES[@]} packages from Fedora repos..."
dnf5 -y install "${FEDORA_PACKAGES[@]}"

# Clipboard Manager
curl -1sLf 'https://dl.cloudsmith.io/public/gustavosett/clipboard-manager/setup.rpm.sh' | bash
dnf5 install -y win11-clipboard-history

# Docker
dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
sed -i "s/enabled=.*/enabled=0/g" /etc/yum.repos.d/docker-ce.repo
dnf -y install --enablerepo=docker-ce-stable \
    containerd.io \
    docker-buildx-plugin \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin \
    docker-model-plugin

# Firefox Developer Edition
## Download
curl -L -o /tmp/firefox.tar.xz 'https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=linux64&lang=en-US'
## Extract
tar -xf /tmp/firefox.tar.xz -C /opt
## 'firefox-developer' command available
ln -s /opt/firefox/firefox /usr/bin/firefox-developer
## cleanup
rm /tmp/firefox.tar.xz
## desktop entry
cp /ctx/custom/desktop/firefox-developer.desktop /usr/share/applications/

# GitKraken
wget https://api.gitkraken.dev/releases/production/linux/x64/active/gitkraken-amd64.rpm && dnf5 install -y gitkraken-amd64.rpm
rm gitkraken-amd64.rpm

# Example using COPR with isolated pattern:
# copr_install_isolated "ublue-os/staging" package-name

# Ghostty
copr_install_isolated "scottames/ghostty" ghostty

echo "::endgroup::"

echo "::group:: ublue-os packages and patches"

# Fix for ID in fwupd
dnf -y copr enable ublue-os/staging
dnf -y copr disable ublue-os/staging
dnf -y swap \
    --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
    fwupd fwupd

# TODO: remove me on next flatpak release when preinstall landed in Fedora
if [[ "$(rpm -E %fedora)" -ge "42" ]]; then
  dnf -y copr enable ublue-os/flatpak-test
  dnf -y copr disable ublue-os/flatpak-test
  dnf -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak flatpak
  dnf -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-libs flatpak-libs
  dnf -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-session-helper flatpak-session-helper
  dnf -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test install flatpak-debuginfo flatpak-libs-debuginfo flatpak-session-helper-debuginfo
fi

echo "::endgroup::"

echo "::group:: Keyfiles for dconf user profile"

cp /ctx/custom/dconf/* /etc/dconf/db/local.d/

echo "::endgroup::"

echo "::group:: Skel"

# Copy flatpak overrides
mkdir -p /etc/skel/.local/share/flatpak/overrides/
cp /ctx/oci/common/bluefin/etc/skel/.local/share/flatpak/overrides/* /etc/skel/.local/share/flatpak/overrides/

echo "::endgroup::"

echo "::group:: tmpfiles.d"

cp /ctx/oci/common/bluefin/usr/lib/tmpfiles.d/* /usr/lib/tmpfiles.d/

echo "::endgroup::"

echo "::group:: System Configuration"

# Copy systemd services
# cp /ctx/oci/common/shared/usr/lib/systemd/system/flatpak-preinstall.service /usr/lib/systemd/system/
cp /ctx/oci/common/bluefin/usr/lib/systemd/system/dconf-update.service /usr/lib/systemd/system/
cp /ctx/custom/systemd/system/*.service /usr/lib/systemd/system/

# Enable/disable systemd services
systemctl enable bluefin-dx-groups.service
systemctl enable dconf-update.service
systemctl enable docker.socket
systemctl enable flatpak-preinstall.service
systemctl enable podman.socket
# Example: systemctl mask unwanted-service

echo "::endgroup::"

# Load iptable_nat module for docker-in-docker.
# See:
#   - https://github.com/ublue-os/bluefin/issues/2365
#   - https://github.com/devcontainers/features/issues/1235
mkdir -p /etc/modules-load.d
tee /etc/modules-load.d/ip_tables.conf <<EOF
iptable_nat
EOF

# Restore default glob behavior
shopt -u nullglob

echo "Custom build complete!"
