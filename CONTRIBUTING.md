# Contributing

Thanks for your interest in improving Fish UltraPro!

## Ways to help

-   Report issues with clear steps to reproduce and your OS/distro (and Fish version).
-   Propose improvements to the installer, cross-distro support, or prompt.
-   Add small utility functions or aliases with brief docs.

## Development

-   This repo mirrors Fish’s config layout under `fish/`:
    -   `config.fish`, `conf.d/*.fish`, `functions/*.fish`
-   The installer symlinks these into `~/.config/fish`.
-   Use `bash install.sh --dry-run` to preview changes.
-   Open a new Fish session (`exec fish`) after install to load conf.d.

## Style

-   Keep shell startup fast: avoid network calls or heavy work in `conf.d`.
-   Prefer portability: check for tool availability (`type -q`) before aliasing or sourcing.
-   Document new aliases/functions briefly in comments.

## Testing

-   Run `ultrapro_doctor` after changes to confirm tools/plugins are healthy.
-   Test on at least one Debian/Ubuntu and one Arch-based system when modifying packages.

## License

-   By contributing, you agree your contributions will be licensed under the MIT License.
