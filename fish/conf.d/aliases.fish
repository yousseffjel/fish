## My everyday aliases
## --------------------
## These are the shortcuts I actually use. If you don’t like any of them,
## drop a file in ~/.config/fish/local/*.fish to override or remove.
## Heads-up: I map cp/mv/rm to safer helpers below — feel free to delete those.
alias ..='cd ..'
alias ...='cd ../..'

# Prefer eza; fall back to exa; else leave ls as-is
if type -q eza
	alias ls='eza --icons --group-directories-first'
	alias ll='eza -lh --icons --group-directories-first'
	alias la='eza -lha --icons --group-directories-first'
else if type -q exa
	alias ls='exa --icons --group-directories-first'
	alias ll='exa -lh --icons --group-directories-first'
	alias la='exa -lha --icons --group-directories-first'
end

# Prefer bat; on Debian/Ubuntu the binary may be batcat
if type -q bat
	alias cat='bat --style=plain'
else if type -q batcat
	alias cat='batcat --style=plain'
end

# --- Package Management (Arch) ---
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rns'
# 'clean' removes orphaned packages. This fails if there are none; I keep it simple.
# If you want a safer version that no-ops when empty, I can turn this into a function.
alias clean='sudo pacman -Rns $(pacman -Qtdq)'

# --- Git Shortcuts ---
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --decorate --all'

# --- File management ---
# I prefer explicit safety helpers. These override the system defaults — remove them if you disagree.
alias cp='cpc'
alias mv='mvc'
alias rm='trash'
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

# --- Misc ---
alias please='sudo'
alias h='history | fzf'
