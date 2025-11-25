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
# Generate unique backup directory name with microsecond precision to avoid collisions
BACKUP_DIR="$HOME/.config/fish_backup_$(date +%Y%m%d%H%M%S)_$$"

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
        # Execute command directly - avoid eval for security
        # For complex commands with operators, use bash -c explicitly
        set +e  # Temporarily disable exit on error for this function
        if [ $# -eq 1 ] && case "$1" in *'|'*|*'&'*|*';'*|*'&&'*|*'||'*) true ;; *) false ;; esac; then
            # Use bash -c with explicit command instead of eval
            bash -c "$1"
        else
            "$@"
        fi
        local exit_code=$?
        set -e  # Re-enable exit on error
        return $exit_code
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
    
    # Validate source file exists
    if [ ! -e "$target" ]; then
        echo "Error: Source file '$target' does not exist" >&2
        return 1
    fi
    
    # If link already points to target, keep it
    if [ -L "$linkpath" ] && [ "$(readlink -f "$linkpath")" = "$(readlink -f "$target")" ]; then
        log "Link exists: $linkpath -> $target"
        return 0
    fi
    backup_path "$linkpath"
    log "Linking $linkpath -> $target"
    # Try to create symlink, handle cross-filesystem issues
    if ! run ln -s "$target" "$linkpath" 2>/dev/null; then
        # If symlink fails, try with absolute path
        local abs_target
        abs_target="$(cd "$(dirname "$target")" && pwd)/$(basename "$target")"
        if ! run ln -s "$abs_target" "$linkpath" 2>/dev/null; then
            echo "Error: Failed to create symlink. Target may be on different filesystem." >&2
            echo "       You may need to copy files instead of symlinking." >&2
            return 1
        fi
    fi
}

echo "🔥 Starting my Fish UltraPro installation..."

# 1) Back up any existing Fish config
if [ -d "$CONFIG_DIR" ] || [ -L "$CONFIG_DIR" ]; then
    echo "Backing up existing Fish config to $BACKUP_DIR"
    run mkdir -p "$BACKUP_DIR"
    run mv "$CONFIG_DIR" "$BACKUP_DIR"
elif [ -f "$CONFIG_DIR" ]; then
    # Handle case where ~/.config/fish is a file instead of directory
    echo "Warning: $CONFIG_DIR exists as a file, not a directory" >&2
    echo "Backing up and removing file..." >&2
    run mkdir -p "$BACKUP_DIR"
    run mv "$CONFIG_DIR" "$BACKUP_DIR/fish_file_backup"
fi

# 2) Create ~/.config/fish structure
# Validate we can create directories
if [ ! -w "$(dirname "$CONFIG_DIR")" ] 2>/dev/null; then
    echo "Error: No write permission to create $CONFIG_DIR" >&2
    exit 1
fi
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

# Check if sudo is available
check_sudo() {
    if ! command -v sudo >/dev/null 2>&1; then
        echo "Warning: sudo not found. Some operations may fail." >&2
        return 1
    fi
    # Test sudo access (non-interactive)
    if ! sudo -n true 2>/dev/null; then
        echo "Note: sudo requires password. You may be prompted during installation." >&2
    fi
    return 0
}

# 4) Install Fish if needed (cross-distro where safe)
install_fish() {
    if command -v pacman >/dev/null 2>&1; then
        check_sudo && run sudo pacman -S --noconfirm fish
    elif command -v apt-get >/dev/null 2>&1; then
        check_sudo && run sudo apt-get update && run sudo apt-get install -y fish
    elif command -v dnf >/dev/null 2>&1; then
        check_sudo && run sudo dnf install -y fish
    elif command -v zypper >/dev/null 2>&1; then
        check_sudo && run sudo zypper install -y fish
    elif command -v apk >/dev/null 2>&1; then
        check_sudo && run sudo apk add fish
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

# Install Fisher with error handling and security checks
if [ "$DRY_RUN" -eq 1 ]; then
    log "DRY-RUN: Would install Fisher and plugins"
else
    # Check if curl is available
    if ! command -v curl >/dev/null 2>&1; then
        echo "⚠️  Warning: curl not found. Cannot install Fisher automatically." >&2
        echo "   Please install curl and run: curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source" >&2
    else
        # Use official Fisher installation method with better error handling
        # Note: Tide is pinned to v6 for stability. Other plugins use latest versions.
        local fisher_install_cmd='set -g fish_color_error red; if not functions -q fisher; curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source; end; and fisher install jorgebucaran/fisher; and fisher install PatrickF1/fzf.fish IlanCosman/tide@v6 jorgebucaran/autopair.fish jethrokuan/z jorgebucaran/nvm.fish gazorby/fish-abbreviation-tips franciscolourenco/done'
        local fisher_output
        fisher_output=$(fish -c "$fisher_install_cmd" 2>&1)
        local fisher_exit_code=$?
        
        if [ $fisher_exit_code -ne 0 ]; then
            echo "⚠️  Warning: Fisher plugin installation failed or had errors." >&2
            echo "   Exit code: $fisher_exit_code" >&2
            echo "   Output: $fisher_output" >&2
            echo "   You can install plugins manually later with:" >&2
            echo "   fisher install jorgebucaran/fisher PatrickF1/fzf.fish IlanCosman/tide@v6 jorgebucaran/autopair.fish jethrokuan/z jorgebucaran/nvm.fish gazorby/fish-abbreviation-tips franciscolourenco/done" >&2
            echo "   Continuing with installation..." >&2
        else
            # Verify Fisher was actually installed
            if fish -c 'functions -q fisher' 2>/dev/null; then
                log "✅ Fisher and plugins installed successfully"
            else
                echo "⚠️  Warning: Fisher installation reported success but fisher function not found" >&2
            fi
        fi
    fi
fi

# 7) Optionally set Fish as my default shell
if [ "$NO_CHSH" -eq 1 ]; then
    log "--no-chsh set; skipping default shell change."
else
    FISH_PATH="$(command -v fish || true)"
    if [ -n "$FISH_PATH" ] && [ "$SHELL" != "$FISH_PATH" ]; then
        # Check if fish is executable
        if [ ! -x "$FISH_PATH" ]; then
            echo "Warning: Fish found at '$FISH_PATH' but is not executable" >&2
        else
            echo "Setting Fish as default shell..."
            # Ensure fish is listed in /etc/shells
            if ! grep -qxF "$FISH_PATH" /etc/shells 2>/dev/null; then
                log "Adding $FISH_PATH to /etc/shells"
                if ! run "echo '$FISH_PATH' | sudo tee -a /etc/shells >/dev/null"; then
                    echo "Warning: Failed to add fish to /etc/shells" >&2
                fi
            fi
            if run chsh -s "$FISH_PATH" 2>&1; then
                log "✅ Default shell changed to $FISH_PATH"
            else
                echo "⚠️  Warning: Failed to change default shell. You may need to run 'chsh -s $FISH_PATH' manually." >&2
            fi
        fi
    fi
fi

# 8) Installation summary and completion
echo ""
echo "✅ Fish UltraPro setup completed!"
if [ "$DRY_RUN" -eq 1 ]; then
    echo "(dry-run) No changes were made."
else
    echo ""
    echo "Installation Summary:"
    echo "  - Config directory: $CONFIG_DIR"
    if [ -d "$BACKUP_DIR" ]; then
        echo "  - Backup location: $BACKUP_DIR"
    fi
    if command -v fish >/dev/null 2>&1; then
        echo "  - Fish version: $(fish --version 2>/dev/null || echo 'unknown')"
    fi
    echo ""
    echo "Next steps:"
    echo "  - Restart your terminal or run 'exec fish' to start using it"
    echo "  - Run 'ultrapro_doctor' to verify installation"
    echo "  - Check ~/.config/fish/local/ for local overrides"
fi
