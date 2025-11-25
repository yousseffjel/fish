## Utility functions I ship with this setup
## ---------------------------------------
## These helpers are tiny and practical. They’re optional — delete what you don’t use.
## Dependencies:
## - cpc/mvc: pv, tar
## - fcd: fzf (falls back to find + fzf)

# --- Copy with progress ---
function cpc
    if count $argv < 2
        echo "Usage: cpc source target_dir"
        return 1
    end
    for src in $argv[1..-2]
        set dest $argv[-1]
        if test -f $src
            echo "Copying $src → $dest"
            set dest_file "$dest/"(path basename $src)
            pv $src > $dest_file
        else if test -d $src
            echo "Copying directory $src → $dest"
            tar cf - $src | pv | tar xf - -C $dest
        end
    end
end

# --- Move with progress ---
function mvc
    if count $argv < 2
        echo "Usage: mvc source target_dir"
        return 1
    end
    for src in $argv[1..-2]
        set dest $argv[-1]
        if test -f $src
            echo "Moving $src → $dest"
            set dest_file "$dest/"(path basename $src)
            pv $src > $dest_file; and command rm $src
        else if test -d $src
            echo "Moving directory $src → $dest"
            tar cf - $src | pv | tar xf - -C $dest; and command rm -rf $src
        end
    end
end

# --- Trash management ---
function trash
    mkdir -p ~/.local/share/Trash/files
    for f in $argv
        command mv $f ~/.local/share/Trash/files/
    end
    echo "Moved to Trash 🗑️"
end

function etrash
    command rm -rf ~/.local/share/Trash/files/*
    echo "Trash emptied 🧹"
end

# --- Fuzzy cd using fzf ---
function fcd
    set dir (find . -type d 2>/dev/null | fzf)
    if test -n "$dir"
        cd "$dir"
    end
end

# --- Notification echo ---
function notify_done
    printf '\033[1;32m✔ Done: %s\033[0m\n' "$argv"
end
