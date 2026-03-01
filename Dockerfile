#
# ROMVault Dockerfile
#
# https://github.com/laromicas/docker-romvault
#
ARG DOCKER_IMAGE_VERSION=1.0.3-3.7.4

# Define software download URLs.
ARG ROMVAULT_URL=https://www.romvault.com
ARG ROMVAULT_VERSION=latest

# Download ROMVault.
FROM alpine:3.17 AS rv
ARG ROMVAULT_URL
ARG ROMVAULT_VERSION
RUN \
    apk --no-cache add curl && \
    if [ "$ROMVAULT_VERSION" = "latest" ]; then FILTER='head -1'; else FILTER="grep $ROMVAULT_VERSION"; fi && \
    # Get latest version of ROMVault
    ROMVAULT_DOWNLOAD=$(curl -sL ${ROMVAULT_URL} | \
        sed -n 's/.*href="\([^"]*\).*/\1/p' | \
        grep -i download | \
        grep -i romvault | \
        sort -r -f -u | \
        $FILTER) \
        && \
    echo "ROMVAULT_DOWNLOAD=${ROMVAULT_DOWNLOAD}" && \
    test -n "$ROMVAULT_DOWNLOAD" || { echo "ERROR: Could not find ROMVault download link"; exit 1; } && \
    # Document Versions
    echo "romvault" $(basename ${ROMVAULT_DOWNLOAD} .zip | cut -d "V" -f 3) >> /VERSIONS && \
    # Download RomVault
    mkdir -p /defaults/ && mkdir -p /opt/romvault/ && \
    curl -sL --output /defaults/romvault.zip "${ROMVAULT_URL}/${ROMVAULT_DOWNLOAD}" && \
    unzip /defaults/romvault.zip -d /opt/romvault/ -o

# Pull base image.
FROM jlesage/baseimage-gui:ubuntu-20.04-v4

RUN \
    LC_ALL=en_US.UTF-8 && LANG=en_US.UTF-8 && LANG=C && \
    APP_ICON_URL=https://www.romvault.com/graphics/romvaultTZ.jpg && \
    install_app_icon.sh "$APP_ICON_URL"

RUN set -x && \
    LC_ALL=en_US.UTF-8 && LANG=en_US.UTF-8 && LANG=C && \
    apt-get update && \
    apt install gnupg ca-certificates -y && \
    apt install dirmngr gnupg apt-transport-https ca-certificates software-properties-common -y && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    apt-add-repository 'deb https://download.mono-project.com/repo/ubuntu stable-focal main' && \
    apt-get update && \
    ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        apt-get install -y --no-install-recommends \
            ca-certificates \
            mono-runtime \
            libmono-system-servicemodel4.0a-cil \
            libgtk2.0-0 \
            gtk2-engines-pixbuf \
            mono-complete \
            xterm; \
    else \
        apt-get install -y --no-install-recommends \
            ca-certificates \
            mono-runtime \
            mono-mcs \
            libmono-system-servicemodel4.0a-cil \
            libgtk2.0-0 \
            gtk2-engines-pixbuf \
            xterm; \
    fi && \
    # Clean up
    # apt-get remove -y \
    #     curl \
    #     wget \
    #     ca-certificates \
    #     unzip \
        # && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    echo Finished

# Add files.
COPY rootfs/ /
COPY --from=rv /opt/romvault/ /opt/romvault/
COPY --from=rv /VERSIONS /VERSIONS
RUN chmod +x /startapp.sh
RUN chmod +x /etc/cont-init.d/99-romvault

# Set internal environment variables.
ARG DOCKER_IMAGE_VERSION
RUN \
    export ROMVAULT_VERSION="$(grep romvault /VERSIONS | cut -d' ' -f2-)" && \
    set-cont-env APP_NAME "ROMVault" && \
    set-cont-env APP_VERSION "$ROMVAULT_VERSION" && \
    set-cont-env DOCKER_IMAGE_VERSION "$DOCKER_IMAGE_VERSION" && \
    WINDOW_NAME="RomVault ($ROMVAULT_VERSION) \/config" && \
    set-cont-env WINDOW_NAME "RomVault ($ROMVAULT_VERSION) \/config" && \
    eval "echo \"$(cat /etc/openbox/main-window-selection.xml)\"" > /etc/openbox/main-window-selection.xml && \
    true

ENV APP_NAME="ROMVault"
