#!/usr/bin/bash

set -eoux pipefail

echo "::group:: ===$(basename "$0")==="


# Copy files
rsync -rvK /ctx/custom/gnome/gnome-shell/extensions/ /usr/share/gnome-shell/extensions/

# Install tooling
dnf5 -y install glib2-devel gcc gcc-c++ gettext meson ninja-build sassc cmake dbus-devel

# Build Extensions

## AppIndicator Support
glib-compile-schemas --strict /usr/share/gnome-shell/extensions/appindicatorsupport@rgcjonas.gmail.com/schemas

# Blur My Shell
make -C /usr/share/gnome-shell/extensions/blur-my-shell@aunetx
unzip -o /usr/share/gnome-shell/extensions/blur-my-shell@aunetx/build/blur-my-shell@aunetx.shell-extension.zip -d /usr/share/gnome-shell/extensions/blur-my-shell@aunetx
glib-compile-schemas --strict /usr/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas
rm -rf /usr/share/gnome-shell/extensions/blur-my-shell@aunetx/build

## Color picker
meson setup -Dtarget=system --prefix=/usr /usr/share/gnome-shell/extensions/color-picker@tuberry /usr/share/gnome-shell/extensions/color-picker@tuberry/_build
meson install -C /usr/share/gnome-shell/extensions/color-picker@tuberry/_build --skip-subprojects
rm -rf /usr/share/gnome-shell/extensions/color-picker@tuberry/_build

## Dash to Dock
make -C /usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com
glib-compile-schemas --strict /usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/schemas
rm -rf /usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/build

## Disable Unredirect
cp -rf /usr/share/gnome-shell/extensions/disable-unredirect@exeos/src/* /usr/share/gnome-shell/extensions/disable-unredirect@exeos/

## GSConnect
meson setup --prefix=/usr /usr/share/gnome-shell/extensions/gsconnect@andyholmes.github.io /usr/share/gnome-shell/extensions/gsconnect@andyholmes.github.io/_build
meson install -C /usr/share/gnome-shell/extensions/gsconnect@andyholmes.github.io/_build --skip-subprojects
rm -rf /usr/share/gnome-shell/extensions/gsconnect@andyholmes.github.io/_build
# GSConnect installs schemas to /usr/share/glib-2.0/schemas and meson compiles them automatically

## Hide Top Bar
make -C /usr/share/gnome-shell/extensions/hidetopbar@mathieu.bidon.ca
glib-compile-schemas --strict /usr/share/gnome-shell/extensions/hidetopbar@mathieu.bidon.ca/schemas

## Search Light
glib-compile-schemas --strict /usr/share/gnome-shell/extensions/search-light@icedman.github.com/schemas

rm /usr/share/glib-2.0/schemas/gschemas.compiled
glib-compile-schemas /usr/share/glib-2.0/schemas

# Cleanup
dnf5 -y remove glib2-devel gcc gcc-c++ gettext meson ninja-build sassc cmake dbus-devel
rm -rf /usr/share/gnome-shell/extensions/tmp

echo "::endgroup::"