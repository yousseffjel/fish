#!/usr/bin/env bash
# ======================================
# Fish UltraPro Installer (my workflow)
# ======================================
# What this does for me:
# - Backs up any existing ~/.config/fish to a timestamped folder
# - Symlinks the repo's fish/ files into ~/.config/fish (transparent and reversible)
# - Installs fish (and common tools) when a known package manager is present
# - Installs Fisher and my plugin stack in a single fish invocation
# - Optionally makes fish my default shell
# Flags I use:
#   --no-packages  Skip system package installs (useful on locked-down machines)
#   --no-chsh      Don’t change my default shell
#   --dry-run      Print what would happen without making any changes
# Safe by default: no network calls during login shell; I delegate installs to this script.

set -e

# Resolve the script directory so I can run this from anywhere
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_FISH_DIR="$SCRIPT_DIR/fish"

CONFIG_DIR="$HOME/.config/fish"
BACKUP_DIR="$HOME/.config/fish_backup_$(date +%Y%m%d%H%M%S)"

# Flags
NO_PACKAGES=0
NO_CHSH=0
DRY_RUN=0

while [ $# -gt 0 ]; do
    case "$1" in
        --no-packages)
            NO_PACKAGES=1
            ;;
        --no-chsh)
            NO_CHSH=1
            ;;
        --dry-run)
            DRY_RUN=1
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
    shift
done

run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "DRY-RUN: $*"
        return 0
    else
        # If only one argument and it looks like a shell command with operators, evaluate it
        # Otherwise execute normally (safer for simple commands)
        if [ $# -eq 1 ] && case "$1" in *'|'*|*'&'*|*';'*|*'&&'*|*'||'*) true ;; *) false ;; esac; then
            eval "$1"
        else
            "$@"
        fi
    fi
}

log() { printf "%s\n" "$*"; }

# Move an existing path into the backup directory, preserving the basename
backup_path() {
    local path="$1"
    if [ -e "$path" ] || [ -L "$path" ]; then
        mkdir -p "$BACKUP_DIR"
        local base
        base="$(basename "$path")"
        log "Backing up $path -> $BACKUP_DIR/$base"
        run mv "$path" "$BACKUP_DIR/$base"
    fi
}

# Create/replace a symlink inside ~/.config/fish that points at a file in this repo
link_into_config() {
    local target="$1"   # source in repo
    local linkpath="$2" # destination path in ~/.config/fish
    # If link already points to target, keep it
    if [ -L "$linkpath" ] && [ "$(readlink -f "$linkpath")" = "$(readlink -f "$target")" ]; then
        log "Link exists: $linkpath -> $target"
        return 0
    fi
    backup_path "$linkpath"
    log "Linking $linkpath -> $target"
    run ln -s "$target" "$linkpath"
}

echo "🔥 Starting my Fish UltraPro installation..."

# 1) Back up any existing Fish config
if [ -d "$CONFIG_DIR" ] || [ -L "$CONFIG_DIR" ]; then
    echo "Backing up existing Fish config to $BACKUP_DIR"
    run mkdir -p "$BACKUP_DIR"
    run mv "$CONFIG_DIR" "$BACKUP_DIR"
fi

# 2) Create ~/.config/fish structure
run mkdir -p "$CONFIG_DIR"
run mkdir -p "$CONFIG_DIR/conf.d"
run mkdir -p "$CONFIG_DIR/functions"

# 3) Symlink configuration from the repo
echo "Linking configuration files..."
if [ ! -d "$REPO_FISH_DIR" ]; then
    echo "Error: '$REPO_FISH_DIR' not found. The repo should contain a 'fish/' directory mirroring ~/.config/fish." >&2
    exit 1
fi

# The repo mirrors ~/.config/fish
link_into_config "$REPO_FISH_DIR/config.fish" "$CONFIG_DIR/config.fish"
# conf.d files
for f in "$REPO_FISH_DIR"/conf.d/*.fish; do
    [ -e "$f" ] || continue
    base="$(basename "$f")"
    link_into_config "$f" "$CONFIG_DIR/conf.d/$base"
done
# functions (optional)
if [ -d "$REPO_FISH_DIR/functions" ]; then
    for f in "$REPO_FISH_DIR"/functions/*.fish; do
        [ -e "$f" ] || continue
        base="$(basename "$f")"
        link_into_config "$f" "$CONFIG_DIR/functions/$base"
    done
fi

# 4) Install Fish if needed (cross-distro where safe)
install_fish() {
    if command -v pacman >/dev/null 2>&1; then
        run sudo pacman -S --noconfirm fish
    elif command -v apt-get >/dev/null 2>&1; then
        run sudo apt-get update
        run sudo apt-get install -y fish
    elif command -v dnf >/dev/null 2>&1; then
        run sudo dnf install -y fish
    elif command -v zypper >/dev/null 2>&1; then
        run sudo zypper install -y fish
    elif command -v apk >/dev/null 2>&1; then
        run sudo apk add fish
    elif command -v brew >/dev/null 2>&1; then
        run brew install fish
    else
        log "No known package manager found. Please install 'fish' manually."
    fi
}

if ! command -v fish >/dev/null 2>&1; then
    echo "Fish shell not found. Attempting installation..."
    if [ "$NO_PACKAGES" -eq 0 ]; then
        install_fish
    else
        log "--no-packages set; skipping fish installation."
    fi
fi

# 5) Install the tools I like (fzf, bat, pv, zip, unzip, p7zip, tar, eza/exa)
echo "Installing dependencies: fzf, bat, pv, zip, unzip, p7zip, tar, eza/exa..."
install_deps() {
    if command -v pacman >/dev/null 2>&1; then
        run sudo pacman -S --needed --noconfirm fzf bat pv zip unzip p7zip tar eza
    elif command -v apt-get >/dev/null 2>&1; then
        run sudo apt-get update
        # Prefer eza, fall back to exa if unavailable; tolerate failure without aborting
        if ! run sudo apt-get install -y fzf bat pv zip unzip p7zip-full tar eza 2>/dev/null; then
            run sudo apt-get install -y fzf bat pv zip unzip p7zip-full tar exa 2>/dev/null || true
        fi
    elif command -v dnf >/dev/null 2>&1; then
        run sudo dnf install -y fzf bat pv zip unzip p7zip p7zip-plugins tar eza 2>/dev/null || log "Some packages may not be available (non-fatal)"
    elif command -v zypper >/dev/null 2>&1; then
        run sudo zypper install -y fzf bat pv zip unzip p7zip-full tar eza 2>/dev/null || log "Some packages may not be available (non-fatal)"
    elif command -v apk >/dev/null 2>&1; then
        run sudo apk add fzf bat pv zip unzip p7zip tar eza 2>/dev/null || log "Some packages may not be available (non-fatal)"
    elif command -v brew >/dev/null 2>&1; then
        run brew install fzf bat pv zip unzip p7zip gnu-tar eza
    else
        log "No known package manager found. Please install manually: fzf bat pv zip unzip p7zip tar eza"
    fi
}

if [ "$NO_PACKAGES" -eq 0 ]; then
    install_deps
else
    log "--no-packages set; skipping dependency installation."
fi

# 6) Install Fisher and my plugins (single fish session for consistency)
echo "Installing Fisher plugins..."
# Handle legacy/partial installs that leave conflicting files
if [ -d "$CONFIG_DIR/fisher_plugins" ]; then
    run mkdir -p "$BACKUP_DIR"
    log "Backing up legacy fisher_plugins to $BACKUP_DIR/fisher_plugins_$(date +%s)"
    run mv "$CONFIG_DIR/fisher_plugins" "$BACKUP_DIR/fisher_plugins_$(date +%s)"
fi

# Install Fisher with error handling
if [ "$DRY_RUN" -eq 1 ]; then
    log "DRY-RUN: Would install Fisher and plugins"
else
    if ! fish -c 'set -g fish_color_error red; curl -sL https://git.io/fisher | source; and fisher install jorgebucaran/fisher; and fisher install PatrickF1/fzf.fish IlanCosman/tide@v6 jorgebucaran/autopair.fish jethrokuan/z jorgebucaran/nvm.fish gazorby/fish-abbreviation-tips franciscolourenco/done' 2>&1; then
        echo "⚠️  Warning: Fisher plugin installation failed or had errors." >&2
        echo "   You can install plugins manually later with:" >&2
        echo "   fisher install jorgebucaran/fisher PatrickF1/fzf.fish IlanCosman/tide@v6 jorgebucaran/autopair.fish jethrokuan/z jorgebucaran/nvm.fish gazorby/fish-abbreviation-tips franciscolourenco/done" >&2
        echo "   Continuing with installation..." >&2
    else
        log "✅ Fisher and plugins installed successfully"
    fi
fi

# 7) Optionally set Fish as my default shell
if [ "$NO_CHSH" -eq 1 ]; then
    log "--no-chsh set; skipping default shell change."
else
    FISH_PATH="$(command -v fish || true)"
    if [ -n "$FISH_PATH" ] && [ "$SHELL" != "$FISH_PATH" ]; then
        echo "Setting Fish as default shell..."
        # Ensure fish is listed in /etc/shells
        if ! grep -qxF "$FISH_PATH" /etc/shells 2>/dev/null; then
            log "Adding $FISH_PATH to /etc/shells"
            run "echo '$FISH_PATH' | sudo tee -a /etc/shells >/dev/null"
        fi
        run chsh -s "$FISH_PATH"
    fi
fi

# 8) Done
echo "✅ Fish UltraPro setup completed!"
if [ "$DRY_RUN" -eq 1 ]; then
    echo "(dry-run) No changes were made."
else
    echo "Restart your terminal or run 'exec fish' to start using it."
fi
