# UltraPro: my Fish entrypoint
# ---------------------------------
# This is the main config Fish reads on startup. I keep it minimal on purpose:
# - No plugin installs or network calls here (the installer handles that for me)
# - I only set a tiny PATH safety net for previewing the repo
# - If I'm looking at this file inside the repo (not in ~/.config/fish), I also source
#   conf.d/* from the repo so the prompt/tools work while I preview

# Tiny PATH safety net for preview sessions (env.fish is the real place I manage PATH)
set -gx PATH $HOME/.local/bin $PATH

# If I'm previewing this file directly from the repo (not symlinked into ~/.config/fish),
# also source the neighboring conf.d files so I see a proper prompt/tools while previewing.
set -l this (status filename)
if test -n "$this"
    set -l this_dir (dirname $this)
    if test "$this_dir" != "$__fish_config_dir"
        set -l repo_conf_d "$this_dir/conf.d"
        if test -d $repo_conf_d
            for f in $repo_conf_d/*.fish
                test -e $f; or continue
                source $f
            end
        end
    end
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# pnpm
set -gx PNPM_HOME "/home/yusuf/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
