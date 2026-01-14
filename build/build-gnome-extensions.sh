#!/usr/bin/bash

set -eoux pipefail

echo "::group:: ===$(basename "$0")==="


# Copy files
ls -la /ctx/custom/gnome-shell/extensions/appindicatorsupport@rgcjonas.gmail.com
rsync -rvK /ctx/custom/gnome-shell/extensions/ /usr/share/gnome-shell/extensions/

# Install tooling
dnf5 -y install glib2-devel meson sassc cmake dbus-devel

# Build Extensions

# AppIndicator Support
ls -la /usr/share/gnome-shell/extensions/appindicatorsupport@rgcjonas.gmail.com
glib-compile-schemas --strict /usr/share/gnome-shell/extensions/appindicatorsupport@rgcjonas.gmail.com/schemas

rm /usr/share/glib-2.0/schemas/gschemas.compiled
glib-compile-schemas /usr/share/glib-2.0/schemas

# Cleanup
dnf5 -y remove glib2-devel meson sassc cmake dbus-devel
rm -rf /usr/share/gnome-shell/extensions/tmp

echo "::endgroup::"