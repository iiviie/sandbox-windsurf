#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to script directory
cd "$SCRIPT_DIR"

# Optimization: Create projects directory if it doesn't exist
mkdir -p ~/cursor-projects

# Optimization: Check if image already exists to skip unnecessary builds
check_image_exists() {
    docker image inspect windsurf-container >/dev/null 2>&1
}

# Optimization: Create volumes only if they don't exist
setup_volumes() {
    echo "Setting up Docker volumes..."
    docker volume inspect windsurf_app_data >/dev/null 2>&1 || docker volume create windsurf_app_data
    docker volume inspect windsurf_config_data >/dev/null 2>&1 || docker volume create windsurf_config_data  
    docker volume inspect firefox_profile_data >/dev/null 2>&1 || docker volume create firefox_profile_data
}

# Function to detect display server and setup appropriate forwarding
detect_display_server() {
    if [ -n "$WAYLAND_DISPLAY" ] && [ -n "$XDG_RUNTIME_DIR" ]; then
        echo "wayland"
    elif [ -n "$DISPLAY" ]; then
        echo "x11"
    else
        echo "unknown"
    fi
}

# Function to setup display forwarding based on detected server
setup_display_forwarding() {
    local display_server=$(detect_display_server)
    
    echo "Detected display server: $display_server"
    
    case $display_server in
        "wayland")
            setup_wayland_forwarding
            ;;
        "x11")
            setup_x11_forwarding
            ;;
        "unknown")
            echo "Warning: Could not detect display server"
            echo "Trying X11 as fallback..."
            setup_x11_forwarding
            ;;
    esac
}

# Function to setup Wayland forwarding
setup_wayland_forwarding() {
    echo "Setting up Wayland forwarding..."
    
    # Check if Wayland socket exists
    local wayland_socket="$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
    if [ ! -S "$wayland_socket" ]; then
        echo "Warning: Wayland socket not found at $wayland_socket"
        echo "Falling back to X11 via XWayland..."
        setup_x11_forwarding
        return 1
    fi
    
    # Set Wayland-specific environment variables
    export DISPLAY_MODE="wayland"
    export WAYLAND_SOCKET_PATH="$wayland_socket"
    
    echo "Wayland setup complete"
    return 0
}

# Function to setup X11 forwarding
setup_x11_forwarding() {
    echo "Setting up X11 forwarding..."
    
    # Check if DISPLAY is set
    if [ -z "$DISPLAY" ]; then
        echo "Warning: DISPLAY environment variable is not set"
        echo "Display forwarding may not work properly"
        return 1
    fi
    
    # Check if X11 socket exists
    if [ ! -d "/tmp/.X11-unix" ]; then
        echo "Warning: X11 socket directory not found"
        echo "Make sure X11 or XWayland is running on the host"
        return 1
    fi
    
    export DISPLAY_MODE="x11"
    echo "X11 setup complete - using simple host network method"
    return 0
}

# Function to cleanup - mostly a placeholder for consistency
cleanup_display_forwarding() {
    echo "Display forwarding cleanup complete"
}

# Set up display forwarding (auto-detect X11 vs Wayland)
setup_display_forwarding

# Optimization: Only build if image doesn't exist or if forced
if ! check_image_exists; then
    echo "Building Windsurf container image..."
    docker build -t windsurf-container -f Dockerfile .
else
    echo "Using existing Windsurf container image (use 'docker rmi windsurf-container' to force rebuild)"
fi

# Get current user ID and group ID for proper permission mapping
USER_ID=$(id -u)
GROUP_ID=$(id -g)

echo "Using UID: $USER_ID, GID: $GROUP_ID"

# Setup volumes efficiently
setup_volumes

# Create host directories if they don't exist and set proper permissions
echo "Setting up host directories with proper permissions..."
mkdir -p ~/cursor-projects ~/Documents ~/Downloads
# Ensure the directories are accessible
chmod 755 ~/cursor-projects ~/Documents ~/Downloads 2>/dev/null || true

# Prepare Hyprland arguments if needed
HYPRLAND_ARGS=""
if command -v hyprctl &> /dev/null && [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    echo "Detected Hyprland, adding Hyprland-specific variables..."
    HYPRLAND_ARGS="-e HYPRLAND_INSTANCE_SIGNATURE=$HYPRLAND_INSTANCE_SIGNATURE -v /tmp/hypr:/tmp/hypr"
fi

# Build and run Docker command based on display mode
echo "Starting Windsurf container..."
echo "Display mode: $DISPLAY_MODE"
echo "Current DISPLAY: $DISPLAY"

if [ "$DISPLAY_MODE" = "wayland" ]; then
    # Wayland mode with proper argument handling
    docker run -it --rm \
      --name windsurf-instance \
      --hostname windsurf-container \
      --add-host windsurf-container:127.0.0.1 \
      --net=host \
      --user "$USER_ID:$GROUP_ID" \
      -e WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
      -e XDG_RUNTIME_DIR=/tmp/xdg-runtime \
      -v "$XDG_RUNTIME_DIR":/tmp/xdg-runtime \
      -e DISPLAY="$DISPLAY" \
      -v /tmp/.X11-unix:/tmp/.X11-unix \
      $HYPRLAND_ARGS \
      -v windsurf_app_data:/home/windsurfuser/.windsurf \
      -v windsurf_config_data:/home/windsurfuser/.config/Windsurf \
      -v firefox_profile_data:/home/windsurfuser/.mozilla/firefox \
      -v ~/cursor-projects:/home/windsurfuser/projects:rw \
      -v ~/Documents:/home/windsurfuser/host-documents:rw \
      -v ~/Downloads:/home/windsurfuser/host-downloads:rw \
      -v /dev/dri:/dev/dri \
      -v /run/dbus:/run/dbus \
      -v /run/user/$USER_ID/pulse:/run/user/1000/pulse \
      --device /dev/dri \
      --device /dev/fuse \
      --device /dev/snd \
      --cap-add SYS_ADMIN \
      --security-opt apparmor:unconfined \
      --shm-size=2g \
      windsurf-container
else
    # X11 mode
    docker run -it --rm \
      --name windsurf-instance \
      --hostname windsurf-container \
      --add-host windsurf-container:127.0.0.1 \
      --net=host \
      --user "$USER_ID:$GROUP_ID" \
      -e DISPLAY="$DISPLAY" \
      -v /tmp/.X11-unix:/tmp/.X11-unix \
      -v windsurf_app_data:/home/windsurfuser/.windsurf \
      -v windsurf_config_data:/home/windsurfuser/.config/Windsurf \
      -v firefox_profile_data:/home/windsurfuser/.mozilla/firefox \
      -v ~/cursor-projects:/home/windsurfuser/projects:rw \
      -v ~/Documents:/home/windsurfuser/host-documents:rw \
      -v ~/Downloads:/home/windsurfuser/host-downloads:rw \
      -v /dev/dri:/dev/dri \
      -v /run/dbus:/run/dbus \
      -v /run/user/$USER_ID/pulse:/run/user/1000/pulse \
      --device /dev/dri \
      --device /dev/fuse \
      --device /dev/snd \
      --cap-add SYS_ADMIN \
      --security-opt apparmor:unconfined \
      --shm-size=2g \
      windsurf-container
fi

# Note: Cleanup is handled by Docker's --rm flag
echo "Windsurf container has been shut down."