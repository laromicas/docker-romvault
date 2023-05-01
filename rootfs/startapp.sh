#!/usr/bin/env sh
#shellcheck shell=sh

set -xe

HOME=/config
export HOME

cd /opt/romvault/
RV_EXE=$(ls | grep -i ROMVault | grep -iv Cmd)

cd /config

# Set up symlinks.
# We need to launch ROMVault from /config as this is where it will write its config.
ln -fs /opt/romvault/${RV_EXE} /config/${RV_EXE} || true
ln -fs /opt/romvault/RomVaultCmd /config/RomVaultCmd || true
ln -fs /opt/romvault/chdman.exe /config/chdman.exe || true

rm -Rf ~/.config/.mono

# exec xterm
mono /config/${RV_EXE}

# wmctrl -r :ACTIVE: -b toggle,maximized_vert,maximized_horz