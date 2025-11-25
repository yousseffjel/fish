## UltraPro Doctor
## ----------------
## I use this to quickly check that my Fish setup is healthy:
## - Fish version is modern enough
## - Fisher and Tide are installed
## - Common tools I rely on are available (fzf, pv, zip, unzip, tar, curl, eza/exa, bat/batcat)
## - The main config is symlinked as the installer expects
##
## Usage:
##   ultrapro_doctor
## Exit codes:
##   0 = everything looks good, 1 = I found at least one warning
## Feel free to extend this for your own needs.
function ultrapro_doctor
    set -l issues 0

    echo "== UltraPro Doctor =="

    # Fish version (extract major.minor safely)
    set -l verline (fish --version)
    set -l ver (string replace -r '^.*?([0-9]+)\.([0-9]+).*$' '$1.$2' -- "$verline")
    set -l major (string split -m1 . -- $ver)[1]
    if test -n "$major" -a "$major" -ge 3
        echo "[ok] fish version: $verline"
    else
        echo "[warn] fish version too old or undetected: $verline"
        set issues 1
    end

    # Fisher
    if functions -q fisher
        echo "[ok] fisher installed"
        # Check if Fisher plugins are actually installed (optimized: read first line only)
        if test -f "$HOME/.config/fish/fish_plugins"
            set -l first_line (head -n 1 "$HOME/.config/fish/fish_plugins" 2>/dev/null | string trim)
            if test -n "$first_line"
                echo "[ok] fisher plugins file exists"
            else
                echo "[warn] fisher plugins file is empty"
                set issues 1
            end
        else
            echo "[warn] fisher plugins file not found (plugins may not be installed)"
            set issues 1
        end
    else
        echo "[warn] fisher not found. Install with: curl -sL https://git.io/fisher | source; and fisher install jorgebucaran/fisher"
        set issues 1
    end

    # Tide
    if functions -q tide
        echo "[ok] tide installed"
    else
        echo "[warn] tide not found. Install with: fisher install IlanCosman/tide@v6"
        set issues 1
    end

    # Check other key plugins
    set -l key_plugins fzf.fish autopair z nvm abbreviation-tips done
    for plugin in $key_plugins
        set -l plugin_name (string replace -r '\.fish$' '' -- $plugin)
        if functions -q $plugin_name; or test -f "$HOME/.config/fish/functions/$plugin_name.fish"
            true  # Plugin appears to be installed
        else
            echo "[warn] plugin $plugin may not be installed"
            set issues 1
        end
    end

    # Tools
    set -l tools fzf pv zip unzip tar curl
    for t in $tools
        if type -q $t
            true
        else
            echo "[warn] missing tool: $t"
            set issues 1
        end
    end

    # eza/exa
    if type -q eza
        echo "[ok] eza present"
    else if type -q exa
        echo "[ok] exa present"
    else
        echo "[warn] neither eza nor exa found"
        set issues 1
    end

    # bat/batcat
    if type -q bat
        echo "[ok] bat present"
    else if type -q batcat
        echo "[ok] batcat present"
    else
        echo "[warn] neither bat nor batcat found"
        set issues 1
    end

    # Symlink status
    set -l cfg "$HOME/.config/fish/config.fish"
    if test -L $cfg
        if type -q readlink
            set -l tgt (readlink -f $cfg)
            if test -e $tgt
                echo "[ok] $cfg is a symlink -> $tgt (target exists)"
            else
                echo "[warn] $cfg is a symlink -> $tgt (target does not exist - broken link)"
                set issues 1
            end
        else
            echo "[ok] $cfg is a symlink"
        end
    else
        echo "[warn] $cfg is not a symlink (installer links repo to config dir)"
        set issues 1
    end

    # Startup time (if available)
    if set -q __fish_start_time
        set -l end_time (date +%s.%N)
        set -l startup_time (math "$end_time - $__fish_start_time")
        printf "[ok] startup time: %.3fs\n" $startup_time
    end
    
    if test $issues -eq 0
        echo "== All checks passed =="
        return 0
    else
        echo "== Completed with warnings =="
        return 1
    end
end

# --- Show startup time ---
function startup_time
    if set -q __fish_start_time
        set -l end_time (date +%s.%N)
        set -l startup_time (math "$end_time - $__fish_start_time")
        printf "Fish startup time: %.3fs\n" $startup_time
    else
        echo "Startup time tracking not available (restart shell to enable)" >&2
    end
end
