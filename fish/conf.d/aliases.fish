## My everyday aliases
## --------------------
## These are the shortcuts I actually use. If you don’t like any of them,
## drop a file in ~/.config/fish/local/*.fish to override or remove.
## Heads-up: I map cp/mv/rm to safer helpers below — feel free to delete those.
alias ..='cd ..'
alias ...='cd ../..'

# Prefer eza; fall back to exa; else leave ls as-is
# Optimized: check once and store result
set -l has_eza (type -q eza; and echo 1; or echo 0)
set -l has_exa (type -q exa; and echo 1; or echo 0)
if test $has_eza -eq 1
	alias ls='eza --icons --group-directories-first'
	alias ll='eza -lh --icons --group-directories-first'
	alias la='eza -lha --icons --group-directories-first'
else if test $has_exa -eq 1
	alias ls='exa --icons --group-directories-first'
	alias ll='exa -lh --icons --group-directories-first'
	alias la='exa -lha --icons --group-directories-first'
end

# Prefer bat; on Debian/Ubuntu the binary may be batcat
# Optimized: check once and store result
set -l has_bat (type -q bat; and echo 1; or echo 0)
set -l has_batcat (type -q batcat; and echo 1; or echo 0)
if test $has_bat -eq 1
	alias cat='bat --style=plain'
else if test $has_batcat -eq 1
	alias cat='batcat --style=plain'
end

# --- Package Management (Arch) ---
# Note: These aliases are Arch Linux specific. Use local overrides for other distros.
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rns'
# 'clean' removes orphaned packages safely (no-ops if none exist)
# Cross-platform: detects package manager and uses appropriate command
function clean
    if type -q pacman
        set orphans (pacman -Qtdq)
        if test -n "$orphans"
            sudo pacman -Rns $orphans  # $orphans is a list, intentionally unquoted
        else
            echo "No orphaned packages to remove"
        end
    else if type -q apt-get
        sudo apt-get autoremove -y
    else if type -q dnf
        sudo dnf autoremove -y
    else if type -q zypper
        sudo zypper packages --unneeded | tail -n +5 | awk '{print $3}' | xargs -r sudo zypper remove -y 2>/dev/null; or echo "No orphaned packages to remove"
    else
        echo "Error: No supported package manager found (pacman, apt-get, dnf, zypper)" >&2
        return 1
    end
end

# --- Git Shortcuts ---
alias gs='git status'
alias ga='git add .'
function gc
    if count $argv -eq 0
        echo "Usage: gc \"commit message\"" >&2
        echo "Or use: git commit (for interactive commit)" >&2
        return 1
    end
    git commit -m "$argv"
end
alias gp='git push'
alias gl='git log --oneline --graph --decorate --all'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gdc='git diff --cached'
alias gst='git stash'
alias gstp='git stash pop'
alias gpl='git pull'
alias gcl='git clone'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gbD='git branch -D'
alias gsw='git switch'
alias gswc='git switch -c'

# --- File management ---
# I prefer explicit safety helpers. These override the system defaults — remove them if you disagree.
alias cp='cpc'
alias mv='mvc'
# Use a wrapper function instead of direct alias to ensure glob expansion works
function rm --wraps=trash
    # Fish expands globs before function calls, so this should work
    trash $argv
end
alias cls='clear'

# --- Compression ---
alias zipf='zip -r'
alias unzipf='unzip'
alias targz='tar -czvf'
alias untargz='tar -xzvf'
alias 7zf='7z a'
alias un7zf='7z x'

# --- Fuzzy Finder Shortcuts ---
alias fcd='fcd'
alias ff='fzf'

# --- Docker (systemd) ---
function dockeron
    if not type -q systemctl
        echo "Error: systemctl not found. Docker aliases require systemd." >&2
        return 1
    end
    if sudo systemctl start docker 2>/dev/null
        if sudo systemctl enable docker 2>/dev/null
            echo "Docker started and enabled"
        else
            echo "Warning: Docker started but failed to enable (may require manual enable)" >&2
        end
    else
        echo "Error: Failed to start Docker service" >&2
        return 1
    end
end

function dockeroff
    if not type -q systemctl
        echo "Error: systemctl not found. Docker aliases require systemd." >&2
        return 1
    end
    if sudo systemctl stop docker 2>/dev/null
        if sudo systemctl disable docker 2>/dev/null
            echo "Docker stopped and disabled"
        else
            echo "Warning: Docker stopped but failed to disable" >&2
        end
    else
        echo "Error: Failed to stop Docker service" >&2
        return 1
    end
end

# --- Misc ---
alias please='sudo'
alias h='history | fzf'
