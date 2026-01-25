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

echo "::group:: Copy Bluefin Config from Common"

# Copy just files from @projectbluefin/common (includes 00-entry.just which imports 60-custom.just)
mkdir -p /usr/share/ublue-os/just/
shopt -s nullglob
cp -r /ctx/oci/common/bluefin/usr/share/ublue-os/just/* /usr/share/ublue-os/just/
shopt -u nullglob

echo "::endgroup::"

echo "::group:: Copy Custom Files"

# Copy Brewfiles to standard location
mkdir -p /usr/share/ublue-os/homebrew/
cp /ctx/custom/brew/*.Brewfile /usr/share/ublue-os/homebrew/

# Consolidate Just Files
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
    gum
    nautilus-gsconnect
)

# Install all Fedora packages (bulk - safe from COPR injection)
echo "Installing ${#FEDORA_PACKAGES[@]} packages from Fedora repos..."
dnf5 -y install "${FEDORA_PACKAGES[@]}"

# Clipboard Manager
curl -1sLf 'https://dl.cloudsmith.io/public/gustavosett/clipboard-manager/setup.rpm.sh' | bash
dnf5 install -y win11-clipboard-history

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
cp /ctx/custom/systemd/system/*.service /usr/lib/systemd/system/

# Enable/disable systemd services
systemctl enable podman.socket
systemctl enable dconf-update.service
# Example: systemctl mask unwanted-service

echo "::endgroup::"

# Restore default glob behavior
shopt -u nullglob

echo "Custom build complete!"
