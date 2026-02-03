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
#if IONICE environment variables are set use them
if [ -n "${IONICE_CLASS}" ]; then
    if [ -n "${IONICE_LEVEL}" ]; then
        echo "Starting with ionice class ${IONICE_CLASS} and level ${IONICE_LEVEL}"
        exec ionice -c "${IONICE_CLASS}" -n "${IONICE_LEVEL}" mono /config/${RV_EXE}
    else
        echo "Starting with ionice class ${IONICE_CLASS}"
        exec ionice -c "${IONICE_CLASS}" mono /config/${RV_EXE}
    fi
    exit $?
fi
mono /config/${RV_EXE}

# wmctrl -r :ACTIVE: -b toggle,maximized_vert,maximized_horz