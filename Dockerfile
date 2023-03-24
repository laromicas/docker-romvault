# FROM jlesage/baseimage-gui:ubuntu-18.04
FROM jlesage/baseimage-gui:ubuntu-20.04

RUN set -x && \
    apt-get update && \
    apt install gnupg ca-certificates -y && \
    apt install dirmngr gnupg apt-transport-https ca-certificates software-properties-common -y && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    # echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | tee /etc/apt/sources.list.d/mono-official-stable.list && \
    apt-add-repository 'deb https://download.mono-project.com/repo/ubuntu stable-focal main' && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        wget \
        ca-certificates \
        unzip \
        mono-runtime \
        libmono-system-servicemodel4.0a-cil \
        libgtk2.0-0 \
        mono-complete \
        xterm \
        && \
    # Get latest version of ROMVault & RVCmd
    ROMVAULT_DOWNLOAD=$(curl 'https://www.romvault.com' | \
        sed -n 's/.*href="\([^"]*\).*/\1/p' | \
        grep -i download | \
        grep -i romvault | \
        # sort -r | \
        head -1) \
        && \
    RVCMD_DOWNLOAD=$(curl 'https://www.romvault.com' | \
        sed -n 's/.*href="\([^"]*\).*/\1/p' | \
        grep -i download | \
        grep -i rvcmd | \
        sort -r | \
        head -1) \
        && \
    # Document Versions
    echo "romvault" $(basename --suffix=.zip $ROMVAULT_DOWNLOAD | cut -d "_" -f 2) >> /VERSIONS && \
    echo "rvcmd" $(basename --suffix=.zip $RVCMD_DOWNLOAD | cut -d "_" -f 2) >> /VERSIONS && \
    # Download RomVault
    mkdir -p /opt/romvault_downloads/ && \
    curl --output /opt/romvault_downloads/romvault.zip "https://www.romvault.com/${ROMVAULT_DOWNLOAD}" && \
    curl --output /opt/romvault_downloads/rvcmd.zip "https://www.romvault.com/${RVCMD_DOWNLOAD}" && \
    unzip /opt/romvault_downloads/romvault.zip -d /opt/romvault/ && \
    unzip /opt/romvault_downloads/rvcmd.zip -d /opt/romvault/ && \
    # Clean up
    # apt-get remove -y \
    #     curl \
    #     wget \
    #     ca-certificates \
    #     unzip \
    #     && \
    # apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    echo Finished

COPY startapp.sh /startapp.sh
COPY etc/ /etc/


ENV APP_NAME="ROMVault"

RUN \
    APP_ICON_URL=https://www.romvault.com/graphics/romvaultTZ.jpg && \
    install_app_icon.sh "$APP_ICON_URL"


# ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

# RUN set -x && \
#     apt-date update
#     apt-get install -y --no-install-recommends \
#         ca-certificates \
#         git \
#         nuget \
#         libgtk-dotnet3.0-cil \
#         software-properties-common \
#         wget \
#         apt-transport-https \
#         && \
#     # install dotnet
#     cd /src
#     wget -nv https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
#     dpkg -i packages-microsoft-prod.deb
#     apt-get update
#     apt-get install -y \
#         dotnet-sdk-3.1 \
#         mono-xbuild \
#         && \

#     # build & install ilrepack
#     git clone --recursive https://github.com/gluck/il-repack.git /src/il-repack
#     cd /src/il-repack


#     # install rvworld
#     git clone https://github.com/RomVault/RVWorld.git /src/RVWorld
#     cd /src/RVWorld
#     git fetch origin pull/8/head:pr8
#     git checkout pr8
#     # patch makefile to build on linux
#     sed -i 's/msbuild/dotnet build/g' Makefile
#     # build
#     export FrameworkPathOverride=/usr/lib/mono/4.5/
#     nuget restore
#     make
#     make build-gui