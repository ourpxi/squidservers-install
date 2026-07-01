#!/usr/bin/env bash

set -e

APP_NAME="SquidServers"
APPIMAGE_URL="https://cdn.squidservers.com/squidservers-latest.AppImage"
ICON_URL="https://squidservers.com/_next/image?url=%2Fsquidservers-logo.png&w=96&q=75"

INSTALL_DIR="$HOME/.local/share/SquidServers"
APPIMAGE="$INSTALL_DIR/SquidServers.AppImage"
ICON="$INSTALL_DIR/squidservers.png"

BIN_DIR="$HOME/.local/bin"
BIN_PATH="$BIN_DIR/squidservers"

DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/squidservers.desktop"

echo "==> Installing $APP_NAME..."

# Check for wget

if ! command -v wget >/dev/null 2>&1; then
    echo "Error: wget is required but is not installed."
    exit 1
fi

# Check for graphical desktop

has_gui() {
    [[ -n "$DISPLAY" ]] && return 0
    [[ -n "$WAYLAND_DISPLAY" ]] && return 0
    [[ -n "$XDG_SESSION_TYPE" && "$XDG_SESSION_TYPE" != "tty" ]] && return 0

    [[ -n "$XDG_CURRENT_DESKTOP" ]] && return 0
    [[ -n "$DESKTOP_SESSION" ]] && return 0

    pgrep -x gnome-shell >/dev/null && return 0
    pgrep -x plasmashell >/dev/null && return 0
    pgrep -x xfwm4 >/dev/null && return 0
    pgrep -x openbox >/dev/null && return 0
    pgrep -x i3 >/dev/null && return 0
    pgrep -x sway >/dev/null && return 0
    pgrep -x Hyprland >/dev/null && return 0
    pgrep -x cinnamon >/dev/null && return 0
    pgrep -x mate-session >/dev/null && return 0
    pgrep -x lxqt-session >/dev/null && return 0

    return 1
}

echo "==> Checking for graphical desktop..."

if ! has_gui; then
    echo
    echo "No graphical desktop environment or window manager was detected."
    echo "SquidServers requires a graphical desktop to run."
    echo

    read -r -p "Install anyway? [Y/n]: " reply
    reply=${reply:-Y}

    if [[ ! "$reply" =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
fi

# Detect package manager

install_fuse() {
    if command -v apt >/dev/null 2>&1; then
        sudo apt update
        sudo apt install -y fuse3 || sudo apt install -y fuse

    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y fuse3

    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y fuse3

    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --noconfirm fuse3

    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y fuse3

    elif command -v apk >/dev/null 2>&1; then
        sudo apk add fuse3

    else
        echo "Could not detect a supported package manager."
        echo "Please install FUSE manually."
        return 1
    fi
}

# Check FUSE

if ! command -v fusermount >/dev/null 2>&1 && \
   ! command -v fusermount3 >/dev/null 2>&1 && \
   ! ldconfig -p 2>/dev/null | grep -qi fuse; then

    echo
    echo "FUSE is required to run this application but it is not installed."

    read -r -p "Install FUSE now? [Y/n]: " reply
    reply=${reply:-Y}

    if [[ "$reply" =~ ^[Yy]$ ]]; then
        echo "==> Installing FUSE..."
        install_fuse
    else
        echo
        echo "Warning: SquidServers may not run correctly without FUSE."
    fi
fi

# Create directories

echo "==> Creating directories..."

mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$DESKTOP_DIR"

# Check existing installation

if [[ -f "$APPIMAGE" ]]; then
    echo
    echo "An existing SquidServers installation was found."

    read -r -p "Overwrite the existing installation? [Y/n]: " reply
    reply=${reply:-Y}

    if [[ ! "$reply" =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
fi

# Download AppImage

echo "==> Downloading AppImage..."

wget -q --show-progress -O "$APPIMAGE" "$APPIMAGE_URL"

echo "==> Making AppImage executable..."

chmod +x "$APPIMAGE"

# Download icon

echo "==> Downloading application icon..."

wget -q -O "$ICON" "$ICON_URL"

# Create launcher

echo "==> Creating launcher..."

cat > "$BIN_PATH" <<EOF
#!/usr/bin/env bash
exec "$APPIMAGE" --no-sandbox "\$@"
EOF

chmod +x "$BIN_PATH"

# Create desktop shortcut

echo "==> Creating desktop shortcut..."

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=SquidServers
Comment=SquidServers
Exec=$BIN_PATH
Icon=$ICON
Terminal=false
Categories=Network;Utility;
StartupNotify=true
EOF

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
fi

# Check PATH

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo
    echo "Note: $BIN_DIR is not in your PATH."
    echo "Add the following line to your shell configuration file (~/.bashrc, ~/.zshrc, etc.):"
    echo
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo
    echo "Then restart your terminal or run:"
    echo
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo
echo "Installation complete!"
echo
echo "You can now launch SquidServers from your applications menu"
echo "or by running:"
echo
echo "    squidservers"
