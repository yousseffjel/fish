## My local overrides hook
## -----------------------
## I keep machine- or user-specific tweaks in ~/.config/fish/local/*.fish.
## Those files are not tracked in this repo; this hook loads them automatically.
set -l local_dir "$HOME/.config/fish/local"
if test -d $local_dir
    for f in $local_dir/*.fish
        test -e $f; or continue
        source $f
    end
end
