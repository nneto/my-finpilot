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

echo "::group:: Copy Custom Files"

# Copy Brewfiles to standard location
mkdir -p /usr/share/ublue-os/homebrew/
cp /ctx/custom/brew/*.Brewfile /usr/share/ublue-os/homebrew/

# Consolidate Just Files
mkdir -p /usr/share/ublue-os/just/
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

# GitKraken
wget https://api.gitkraken.dev/releases/production/linux/x64/active/gitkraken-amd64.rpm && dnf5 install -y gitkraken-amd64.rpm


# Example using COPR with isolated pattern:
# copr_install_isolated "ublue-os/staging" package-name

echo "::endgroup::"

echo "::group:: Keyfiles for dconf user profile"

cp /ctx/custom/dconf/* /etc/dconf/db/local.d/

echo "::endgroup::"

echo "::group:: System Configuration"

# Copy systemd services
cp /ctx/custom/systemd/system/*.service /usr/lib/systemd/system/

# Enable/disable systemd services
# Example: systemctl mask unwanted-service
systemctl enable podman.socket
systemctl enable dconf-update.service

echo "::endgroup::"

echo "Custom build complete!"
