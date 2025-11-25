## How I manage plugins
## --------------------
## I use Fisher as the plugin manager, but I never auto-install at shell startup
## (that keeps startup fast and avoids network calls). Use the installer script, or
## run `fisher install ...` yourself when you actually want to change plugins.

# I keep Fisher paths at their defaults so functions/conf.d work in every session.

# Plugin Versioning Strategy:
# - Tide is pinned to v6 (@v6) for stability and compatibility
# - Other plugins use latest stable versions (no version pinning)
# - To pin a plugin version, add @version suffix: plugin@v1.2.3
# - Check plugin repositories for latest stable versions

# Reference list I like to keep handy (uncomment to use):
# set -l plugins \
#     jorgebucaran/fisher \
#     PatrickF1/fzf.fish \
#     IlanCosman/tide@v6 \
#     jorgebucaran/autopair.fish \
#     jethrokuan/z \
#     jorgebucaran/nvm.fish \
#     meaningful-ooo/puffer-fish \
#     gazorby/fish-abbreviation-tips \
#     franciscolourenco/done \
#     jorgebucaran/bass

# To install later, I just run:
# fisher install <plugins...>
#
# To update plugins to latest versions:
# fisher update
#
# To pin a plugin to a specific version:
# fisher install plugin@v1.2.3
