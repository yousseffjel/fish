# Fish UltraPro

A clean, fast Fish shell setup with a one-command installer, a great Tide v6 prompt, and sensible defaults.

[![Shell](https://img.shields.io/badge/shell-fish-7CDEF4?logo=fishshell&logoColor=white)](https://fishshell.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

If this saves you time, please star the repo — it helps others find it, too.

## Highlights

-   Mirror of `~/.config/fish` in `fish/` for simple, transparent config
-   Batteries included: Fisher, Tide v6, fzf.fish, autopair, z, nvm, abbreviation-tips, done
-   Symlink-based install (safe, reversible), cross-distro packages, optional flags
-   Lean prompt tuned for speed and clarity without an interactive wizard
-   Optional Classic preset for Tide (auto-applied once, skip-able)

## Table of contents

-   [Quick start](#quick-start)
-   [Layout](#layout)
-   [Tide prompt (v6) – fast, readable, reliable](#tide-prompt-v6--fast-readable-reliable)
    -   [Classic preset (auto-applied once)](#classic-preset-auto-applied-once)
-   [Local overrides](#local-overrides)
-   [Installer flags](#installer-flags)
-   [Troubleshooting](#troubleshooting)
-   [Health check](#health-check)
-   [Uninstall](#uninstall)
-   [FAQ](#faq)
-   [Contributing](#contributing)
-   [License](#license)

## Quick start

Run from the repository root:

```bash
bash install.sh
```

Then start a fresh Fish session:

```fish
exec fish
```

Notes:

-   The installer links files into `~/.config/fish` so changes stay in sync.
-   If a supported package manager is found, common tools will be installed; otherwise you’ll get guidance.
-   Tested on Arch-based and Debian/Ubuntu systems; other distros use best-effort package detection.

## Layout

The repo mirrors `~/.config/fish`:

-   `fish/`
    -   `config.fish` — entrypoint loaded by Fish
    -   `conf.d/` — modular files auto-sourced by Fish (alphabetical order)
        -   `env.fish` — environment and PATH
        -   `plugins.fish` — plugin configuration (no auto-install on startup)
        -   `aliases.fish` — common aliases
        -   `functions.fish` — lightweight utility functions
        -   `prompt.fish` — Tide Classic preset (applied once, optional)
        -   `local-overrides.fish` — host-specific overrides auto-sourced
    -   `functions/` — per-function autoloads (e.g. `ultrapro_doctor`)

Ordering guidance:

-   Files are loaded alphabetically. The names here are chosen to ensure a safe order without numeric prefixes.

## Tide prompt (v6) – fast, readable, reliable

This setup configures Tide non-interactively for a lean, informative prompt:

-   Left: current directory, git, node, virtual_env, jobs, cmd duration
-   Right: clock
-   Truecolor if supported
-   No heavy I/O on startup; falls back to a simple prompt if Tide is missing

You can tweak items at any time (new sessions pick up changes):

```fish
set -U tide_left_prompt_items dir git node virtual_env jobs cmd_duration
set -U tide_right_prompt_items time
set -U tide_prompt_style lean
set -U tide_prompt_color_mode truecolor
tide reload 2>/dev/null
```

Tip: if you prefer the Tide wizard, run `tide configure` and it will overwrite these variables with your choices.

### Classic preset (auto-applied once)

This repo ships a Classic preset that applies once on your first interactive session (can be skipped). It’s equivalent to:

```fish
tide configure --auto \
    --style=Classic \
    --prompt_colors='True color' \
    --classic_prompt_color=Dark \
    --show_time='12-hour format' \
    --classic_prompt_separators=Round \
    --powerline_prompt_heads=Round \
    --powerline_prompt_tails=Sharp \
    --powerline_prompt_style='Two lines, character and frame' \
    --prompt_connection=Solid \
    --powerline_right_prompt_frame=No \
    --prompt_connection_andor_frame_color=Darkest \
    --prompt_spacing=Sparse \
    --icons='Many icons' \
    --transient=No
```

Controls:

-   Skip before first run: `set -U tide_ultrapro_classic_skip 1`
-   Re-apply later: `set -e tide_ultrapro_classic_applied; and exec fish`

If you prefer to keep only the minimal defaults, set the skip flag once and you’re done.

## Local overrides

Want host- or user-specific knobs? Drop files in:

```text
~/.config/fish/local/*.fish
```

They're auto-sourced by `local-overrides.fish` and are not part of the repo.

Examples:

-   Disable or adjust an alias:

```fish
# ~/.config/fish/local/aliases.fish
# Remove the generated alias named 'rm' if you prefer stock rm
functions -e rm 2>/dev/null
```

-   Add machine-specific PATH entries:

```fish
# ~/.config/fish/local/path.fish
fish_add_path /opt/special/bin
```

## Installer flags

-   `--no-packages` — skip installing system packages
-   `--no-chsh` — don’t change default shell
-   `--dry-run` — print actions without changing anything

## Troubleshooting

-   Tide error (Unknown command: _tide_2_line_prompt_)

    -   Start a new Fish session (`exec fish`) after install
    -   Verify: `type -q tide; and echo tide ok || echo tide missing`
    -   Reinstall Tide if functions are missing: `fisher reinstall IlanCosman/tide@v6; and exec fish`

-   Fisher conflicts during install

    -   The installer backs up legacy `~/.config/fish/fisher_plugins` automatically; re-run after it’s moved

-   Debian/Ubuntu `bat` is `batcat`
    -   This config auto-detects and aliases accordingly (see `aliases.fish`)

## Health check

After install, run:

```fish
ultrapro_doctor
```

It validates Fish version, Fisher/Tide presence, common tools, and that configs are linked properly.

## Uninstall

Because the installer uses symlinks and creates a timestamped backup, you can revert safely:

```fish
# Find the most recent backup directory
set backup (ls -d ~/.config/fish_backup_* ^/dev/null | tail -n 1)
test -n "$backup"; and echo "Restoring from $backup"; or echo "No backup found"

# Remove current config and restore backup
test -n "$backup"; and rm -rf ~/.config/fish; and mv $backup ~/.config/fish
```

Optional cleanup:

```fish
# Remove universal variables set by Tide presets if desired
set -e tide_ultrapro_classic_applied
set -e tide_ultrapro_classic_skip
```

To switch your default shell back (if changed):

```fish
chsh -s (command -v bash)
```

## FAQ

-   Why Fish instead of bash/zsh?

    -   Modern UX, autosuggestions, sane scripting, and great performance.

-   I don’t like overriding core commands like `rm`/`cp`/`mv`.

    -   You can remove any alias in a local override (see examples above). Helpers like `trash`, `cpc`, and `mvc` are available explicitly.

-   The prompt didn’t reload when I changed variables.

    -   Run `tide reload 2>/dev/null` or start a new shell with `exec fish`.

-   Can I skip all plugin installs?
    -   Run the installer with `--no-packages` and open a Fish session. Skip the Classic preset via `set -U tide_ultrapro_classic_skip 1`. You can later run `fisher` manually.

## Contributing

PRs welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT
