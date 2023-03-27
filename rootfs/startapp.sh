#!/usr/bin/env sh
#shellcheck shell=sh

set -xe

HOME=/config
export HOME

cd /config

# Set up symlinks.
# We need to launch ROMVault from /config as this is where it will write its config.
ln -fs /opt/romvault/ROMVault35.exe /config/ROMVault35.exe || true
ln -fs /opt/romvault/RomVaultCmd.exe /config/RomVaultCmd.exe || true
ln -fs /opt/romvault/chdman.exe /config/chdman.exe || true

rm -Rf ~/.config/.mono

# exec xterm
mono /config/ROMVault35.exe
