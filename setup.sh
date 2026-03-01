#!/usr/bin/env bash
set -euo pipefail

# Setup script for docker-romvault
# Builds the Docker image locally and runs the container

IMAGE_NAME="${IMAGE_NAME:-romvault}"
CONTAINER_NAME="romvault"
ROMVAULT_DIR="${ROMVAULT_DIR:-$HOME/ROMVault}"
HOST_PORT="${HOST_PORT:-5800}"
USER_ID="${USER_ID:-$(id -u)}"
GROUP_ID="${GROUP_ID:-$(id -g)}"
TZ="${TZ:-$(cat /etc/timezone 2>/dev/null || echo "America/New_York")}"

usage() {
    echo "Usage: $0 [build|run|start|stop|restart|status|logs|clean]"
    echo ""
    echo "Commands:"
    echo "  build    Build the Docker image"
    echo "  run      Create directories, build image, and start the container"
    echo "  start    Start an existing stopped container"
    echo "  stop     Stop the running container"
    echo "  restart  Restart the container"
    echo "  status   Show container status"
    echo "  logs     Show container logs"
    echo "  clean    Stop and remove the container and image"
    echo ""
    echo "Environment variables:"
    echo "  ROMVAULT_DIR  Base directory for ROMVault data (default: ~/ROMVault)"
    echo "  HOST_PORT     Port to expose the web UI on (default: 5800)"
    echo "  USER_ID       User ID for file ownership (default: current user)"
    echo "  GROUP_ID      Group ID for file ownership (default: current group)"
    echo "  TZ            Timezone (default: America/New_York)"
}

check_docker() {
    if ! command -v docker &>/dev/null; then
        echo "Error: Docker is not installed or not in PATH."
        exit 1
    fi
    if ! docker info &>/dev/null; then
        echo "Error: Docker daemon is not running."
        exit 1
    fi
}

check_romvault_zip() {
    local script_dir
    script_dir="$(cd "$(dirname "$0")" && pwd)"
    if ! ls "$script_dir"/ROMVault*.zip &>/dev/null; then
        echo "Error: No ROMVault*.zip file found in $script_dir"
        echo "Download ROMVault from https://www.romvault.com and place the zip file in this directory."
        exit 1
    fi
}

create_dirs() {
    echo "Creating directories under $ROMVAULT_DIR ..."
    mkdir -p "$ROMVAULT_DIR/config"
    mkdir -p "$ROMVAULT_DIR/DatRoot"
    mkdir -p "$ROMVAULT_DIR/RomRoot"
    mkdir -p "$ROMVAULT_DIR/ToSort"
    echo "Directories created."
}

build_image() {
    local script_dir
    script_dir="$(cd "$(dirname "$0")" && pwd)"
    echo "Building Docker image $IMAGE_NAME ..."
    docker build --platform linux/amd64 -t "$IMAGE_NAME" "$script_dir"
    echo "Image built successfully."
}

run_container() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Container '$CONTAINER_NAME' already exists."
        echo "Use '$0 restart' to restart it, or '$0 clean' to remove it first."
        exit 1
    fi

    echo "Starting container '$CONTAINER_NAME' ..."
    docker run -d \
        --name="$CONTAINER_NAME" \
        --platform linux/amd64 \
        -p "${HOST_PORT}:5800" \
        -e "USER_ID=${USER_ID}" \
        -e "GROUP_ID=${GROUP_ID}" \
        -e "TZ=${TZ}" \
        -e "MONO_ENV_OPTIONS=--interpreter" \
        -v "$ROMVAULT_DIR/config:/config:rw" \
        -v "$ROMVAULT_DIR/DatRoot:/config/DatRoot:rw" \
        -v "$ROMVAULT_DIR/RomRoot:/config/RomRoot:rw" \
        -v "$ROMVAULT_DIR/ToSort:/config/ToSort:rw" \
        --restart unless-stopped \
        "$IMAGE_NAME"

    echo ""
    echo "ROMVault is running!"
    echo "Access the web UI at: http://localhost:${HOST_PORT}"
}

case "${1:-}" in
    build)
        check_docker
        check_romvault_zip
        build_image
        ;;
    run)
        check_docker
        check_romvault_zip
        create_dirs
        build_image
        run_container
        ;;
    start)
        check_docker
        docker start "$CONTAINER_NAME"
        echo "Container started. UI at: http://localhost:${HOST_PORT}"
        ;;
    stop)
        check_docker
        docker stop "$CONTAINER_NAME"
        echo "Container stopped."
        ;;
    restart)
        check_docker
        docker restart "$CONTAINER_NAME"
        echo "Container restarted. UI at: http://localhost:${HOST_PORT}"
        ;;
    status)
        check_docker
        docker ps -a --filter "name=^${CONTAINER_NAME}$" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        ;;
    logs)
        check_docker
        docker logs -f "$CONTAINER_NAME"
        ;;
    clean)
        check_docker
        echo "Stopping and removing container '$CONTAINER_NAME' ..."
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        docker rm "$CONTAINER_NAME" 2>/dev/null || true
        echo "Removing image '$IMAGE_NAME' ..."
        docker rmi "$IMAGE_NAME" 2>/dev/null || true
        echo "Cleaned up."
        ;;
    *)
        usage
        exit 1
        ;;
esac
