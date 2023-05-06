#
# ROMVault Dockerfile
#
# https://github.com/laromicas/docker-romvault
#
# NOTES:
#   - We are using Mono.
#   - Only 64-bits x86_64 supported right now, but
#     maybe later if there is demand I will try
#     to add ARM support.
#
ARG DOCKER_IMAGE_VERSION=1.0.0-rc5

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
    # Get latest version of ROMVault & RVCmd
    ROMVAULT_DOWNLOAD=$(curl ${ROMVAULT_URL} | \
        sed -n 's/.*href="\([^"]*\).*/\1/p' | \
        grep -i download | \
        grep -i romvault | \
        sort -r -f -u | \
        $FILTER) \
        && \
    RVCMD_DOWNLOAD=$(curl ${ROMVAULT_URL} | \
        sed -n 's/.*href="\([^"]*\).*/\1/p' | \
        grep -i download | \
        grep -i rvcmd | \
        grep -i linux | \
        sort -r -f -u | \
        head -1) \
        && \
    echo ROMVAULT_DOWNLOAD=${ROMVAULT_DOWNLOAD} && \
    echo RVCMD_DOWNLOAD=${RVCMD_DOWNLOAD} && \
    # Document Versions
    echo "romvault" $(basename ${ROMVAULT_DOWNLOAD} .zip | cut -d "V" -f 3) >> /VERSIONS && \
    echo "rvcmd" $(basename ${RVCMD_DOWNLOAD} .zip | cut -d "V" -f 3 | cut -d "-" -f 1) >> /VERSIONS && \
    # Download RomVault
    mkdir -p /defaults/ && mkdir -p /opt/romvault/ && \
    curl --output /defaults/romvault.zip "${ROMVAULT_URL}/${ROMVAULT_DOWNLOAD}" && \
    curl --output /defaults/rvcmd.zip "${ROMVAULT_URL}/${RVCMD_DOWNLOAD}" && \
    unzip /defaults/romvault.zip -d /opt/romvault/ && \
    unzip /defaults/rvcmd.zip -d /opt/romvault/

# Uses local files instead of downloading
# COPY ROMVault3.6.0.zip /defaults/romvault.zip
# RUN \
#     unzip /defaults/romvault.zip -d /opt/romvault/ && \
#     echo "romvault 3.6.0" >> /VERSIONS


# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.17-v4.4.1

# Install mono and dependencies.
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" | cat - /etc/apk/repositories  > repositories && mv -f repositories /etc/apk && \
    apk add --no-cache mono libgdiplus gtk+2.0 msttcorefonts-installer && \
    apk add --no-cache mono-dev git bash automake autoconf findutils make pkgconf libtool g++ && \
    apk add --no-cache --virtual=.build-dependencies ca-certificates && \
    cert-sync /etc/ssl/certs/ca-certificates.crt && \
    update-ms-fonts && \
    fc-cache -f && \
    mkdir -p /opt/ && \
    git clone https://github.com/mono/xsp.git /opt/xsp && \
    cd /opt/xsp && ./autogen.sh && ./configure --prefix=/usr && make && make install && \
    rm -rf /opt/xsp && \
    apk del .build-dependencies && \
    apk del mono-dev git bash automake autoconf findutils make pkgconf libtool g++

RUN \
    APP_ICON_URL=https://www.romvault.com/graphics/romvaultTZ.jpg && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /
COPY --from=rv /opt/romvault/ /opt/romvault/
COPY --from=rv /VERSIONS /VERSIONS
RUN chmod +x /startapp.sh
RUN chmod +x /etc/cont-init.d/99-romvault

# Set internal environment variables.
ARG DOCKER_IMAGE_VERSION
RUN \
    export ROMVAULT_VERSION=$(echo "$(grep romvault /VERSIONS | cut -d' ' -f2)") && \
    set-cont-env APP_NAME "ROMVault" && \
    set-cont-env APP_VERSION "$ROMVAULT_VERSION" && \
    set-cont-env DOCKER_IMAGE_VERSION "$DOCKER_IMAGE_VERSION" && \
    WINDOW_NAME="RomVault ($ROMVAULT_VERSION) \/config" && \
    eval "echo \"$(cat /etc/openbox/main-window-selection.xml)\"" > /etc/openbox/main-window-selection.xml && \
    true

# ROMVAULT_VERSION=$(grep romvault /VERSIONS | cut -d' ' -f2)
# APP_NAME="RomVault ($ROMVAULT_VERSION) \/config"


# Metadata.
LABEL maintainer="Lak <laromicas@hotmail.com>"
LABEL \
      org.label-schema.name="romvault" \
      org.label-schema.description="Docker container for ROMVault" \
      org.label-schema.version="${DOCKER_IMAGE_VERSION:-unknown}" \
      org.label-schema.vcs-url="https://github.com/laromicas/docker-romvault" \
      org.label-schema.schema-version="1.0"
