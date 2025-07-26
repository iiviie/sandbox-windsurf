FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Combine all apt operations into a single layer with optimized package installation
RUN apt update && \
    # Install in order of likelihood to change (stable packages first)
    apt install -y --no-install-recommends \
    # Core system libraries (rarely change)
    libglib2.0-0 libgtk-3-0 libxkbcommon0 libnss3 libx11-6 \
    libxcomposite1 libxdamage1 libxrandr2 libasound2 libxext6 \
    libxtst6 libatk1.0-0 libatk-bridge2.0-0 libcups2 libgbm1 \
    libwayland-client0 libwayland-cursor0 libwayland-egl1 \
    libwayland-server0 libdrm2 libdbus-1-3 libxss1 libgconf-2-4 \
    # Additional Electron/Chromium dependencies
    libasound2-dev libgtk-3-dev libnss3-dev libxrandr2 \
    libxcomposite1 libxcursor1 libxdamage1 libxi6 libxrandr2 \
    libxss1 libgconf-2-4 libxkbfile1 libsecret-1-0 \
    # System utilities
    wget ca-certificates fuse xdg-utils mesa-utils dbus-x11 \
    xvfb x11-xserver-utils pulseaudio locales \
    software-properties-common gnupg curl sudo apt-transport-https \
    # Development tools (more likely to change versions)
    git python3 python3-pip python3-venv \
    # Optional tools (comment out if not needed to save space and time)
    vim nano htop zip unzip \
    && \
    # Install Firefox in same layer to avoid extra apt update
    add-apt-repository ppa:mozillateam/ppa -y && \
    echo 'Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001' > /etc/apt/preferences.d/mozilla-firefox && \
    apt update && apt install -y --no-install-recommends firefox && \
    # Install Node.js from NodeSource for latest stable version
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && \
    apt install -y nodejs && \
    # Update npm to latest version
    npm install -g npm@latest && \
    # Add Windsurf repository and install
    wget -qO- "https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg" | gpg --dearmor > windsurf-stable.gpg && \
    install -D -o root -g root -m 644 windsurf-stable.gpg /etc/apt/keyrings/windsurf-stable.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/windsurf-stable.gpg] https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" > /etc/apt/sources.list.d/windsurf.list && \
    rm -f windsurf-stable.gpg && \
    apt update && \
    apt install -y --no-install-recommends windsurf && \
    # Cleanup in same layer to reduce image size
    apt-get autoremove -y && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    apt-get clean

# Set up locale and user in a single optimized layer
RUN locale-gen en_US.UTF-8 && \
    # Create user with dynamic UID (will be overridden by run script if needed)
    useradd -u 1000 -ms /bin/bash windsurfuser && \
    usermod -aG sudo windsurfuser && \
    echo "windsurfuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/windsurfuser && \
    chmod 0440 /etc/sudoers.d/windsurfuser && \
    # Create all directories at once with proper permissions
    mkdir -p /home/windsurfuser/.windsurf/extensions \
             /home/windsurfuser/.config/Windsurf/Code\ Cache/js \
             /home/windsurfuser/.config/Windsurf/Code\ Cache/wasm \
             /home/windsurfuser/.config/Windsurf/User/globalStorage \
             /home/windsurfuser/.mozilla/firefox \
             /home/windsurfuser/projects \
             /home/windsurfuser/host-documents \
             /home/windsurfuser/host-downloads && \
    chown -R windsurfuser:windsurfuser /home/windsurfuser && \
    chmod -R 755 /home/windsurfuser/.windsurf /home/windsurfuser/.config

# Set environment variables
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    BROWSER="/usr/bin/firefox" \
    ELECTRON_DEFAULT_ERROR_MODE=1 \
    ELECTRON_ENABLE_LOGGING=1

# Set work directory and switch to user
USER windsurfuser
WORKDIR /home/windsurfuser

# Setup shell and create startup script
RUN echo '#!/bin/bash\n\
# Enhanced permission fixes for cross-system compatibility\n\
echo "Setting up container permissions..."\n\
\n\
# Fix ownership of mounted volumes if they exist and have wrong permissions\n\
[ -d "/home/windsurfuser/projects" ] && sudo chown -R windsurfuser:windsurfuser /home/windsurfuser/projects\n\
[ -d "/home/windsurfuser/host-documents" ] && sudo chown -R windsurfuser:windsurfuser /home/windsurfuser/host-documents\n\
[ -d "/home/windsurfuser/host-downloads" ] && sudo chown -R windsurfuser:windsurfuser /home/windsurfuser/host-downloads\n\
\n\
# Ensure configuration directories have correct permissions\n\
sudo chown -R windsurfuser:windsurfuser /home/windsurfuser/.windsurf /home/windsurfuser/.config/Windsurf /home/windsurfuser/.mozilla\n\
sudo chmod -R 755 /home/windsurfuser/.windsurf /home/windsurfuser/.config/Windsurf\n\
\n\
# Set proper permissions for mounted directories\n\
[ -d "/home/windsurfuser/projects" ] && chmod 755 /home/windsurfuser/projects\n\
[ -d "/home/windsurfuser/host-documents" ] && chmod 755 /home/windsurfuser/host-documents\n\
[ -d "/home/windsurfuser/host-downloads" ] && chmod 755 /home/windsurfuser/host-downloads\n\
\n\
# Test display connection\n\
echo "Testing display connection..."\n\
if ! xset q >/dev/null 2>&1; then\n\
    echo "Warning: Cannot connect to display. Trying to start virtual display..."\n\
    sudo Xvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 &\n\
    export DISPLAY=:99\n\
    sleep 2\n\
fi\n\
\n\
echo "Starting Windsurf with display: $DISPLAY"\n\
exec windsurf --no-sandbox --disable-gpu-sandbox --disable-dev-shm-usage --disable-extensions --verbose' > start-windsurf.sh && \
    chmod +x start-windsurf.sh && \
    # Setup custom prompt
    echo 'export PS1="\[\033[01;32m\]\u@windsurf-container\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> .bashrc

# Default command - use our wrapper script
CMD ["./start-windsurf.sh"]