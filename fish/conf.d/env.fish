## My environment defaults
## -----------------------
## I keep all environment, locale, and PATH tweaks here so they load early and stay readable.
## If you need to add host-specific values, prefer creating ~/.config/fish/local/*.fish
## so you don’t modify tracked files.

# Editors and basic tools I use
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx BROWSER firefox
set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8
set -gx PAGER less

# PATH I expect available across machines (user bins first)
fish_add_path /usr/local/bin /usr/bin /bin /usr/sbin /sbin /usr/local/sbin
fish_add_path $HOME/.local/bin $HOME/bin

# Small UX/perf touches for a snappy shell
set -g fish_greeting ""
set -U fish_term24bit 1
set -U fish_autosuggestion_delay 0
set -U fish_color_autosuggestion brblack
