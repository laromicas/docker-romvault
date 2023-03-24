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

# wait $!

# TIMEOUT=10

# while true
# do
#     if is_jd_running; then
#         if [ "$TIMEOUT" -lt 10 ]; then
#             log_debug "JDownloader2 has restarted."
#         fi

#         # Reset the timeout.
#         TIMEOUT=10
#     else
#         if [ "$TIMEOUT" -eq 10 ]; then
#             log_debug "JDownloader2 exited, checking if it is restarting..."
#         elif [ "$TIMEOUT" -eq 0 ]; then
#             log_debug "JDownloader2 not restarting, exiting..."
#             break
#         fi
#         TIMEOUT="$(expr $TIMEOUT - 1)"
#     fi
#     sleep 1
# done