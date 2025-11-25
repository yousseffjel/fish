#!/usr/bin/env bash
# ======================================
# Fish UltraPro Update Utility
# ======================================
# This script updates Fisher plugins and optionally pulls latest config from repo
# Usage:
#   update.sh              - Update Fisher plugins only
#   update.sh --config     - Update plugins and pull latest config from git
#   update.sh --plugins-only - Update plugins only (explicit)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATE_CONFIG=0
UPDATE_PLUGINS=1

while [ $# -gt 0 ]; do
    case "$1" in
        --config)
            UPDATE_CONFIG=1
            ;;
        --plugins-only)
            UPDATE_PLUGINS=1
            UPDATE_CONFIG=0
            ;;
        --help|-h)
            echo "Usage: $0 [--config] [--plugins-only]" >&2
            echo "" >&2
            echo "Options:" >&2
            echo "  --config       - Update plugins and pull latest config from git" >&2
            echo "  --plugins-only - Update plugins only (default)" >&2
            echo "  --help, -h     - Show this help message" >&2
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
    shift
done

echo "🔄 Fish UltraPro Update Utility"
echo ""

# Update config from git if requested
if [ "$UPDATE_CONFIG" -eq 1 ]; then
    if [ ! -d "$SCRIPT_DIR/.git" ]; then
        echo "⚠️  Warning: Not a git repository. Skipping config update." >&2
    else
        echo "📥 Updating config from git..."
        cd "$SCRIPT_DIR"
        
        # Check if there are uncommitted changes
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            echo "⚠️  Warning: You have uncommitted changes. Stashing..." >&2
            git stash
        fi
        
        if git pull; then
            echo "✅ Config updated successfully"
        else
            echo "⚠️  Warning: Failed to pull latest config" >&2
        fi
    fi
fi

# Update Fisher plugins
if [ "$UPDATE_PLUGINS" -eq 1 ]; then
    echo "📦 Updating Fisher plugins..."
    
    if ! command -v fish >/dev/null 2>&1; then
        echo "Error: Fish shell is not installed" >&2
        exit 1
    fi
    
    # Check if Fisher is installed
    if ! fish -c 'functions -q fisher' 2>/dev/null; then
        echo "⚠️  Warning: Fisher is not installed. Installing..." >&2
        if ! command -v curl >/dev/null 2>&1; then
            echo "Error: curl is required to install Fisher" >&2
            exit 1
        fi
        fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source; and fisher install jorgebucaran/fisher'
    fi
    
    # Update all plugins
    if fish -c 'fisher update' 2>&1; then
        echo "✅ Plugins updated successfully"
    else
        echo "⚠️  Warning: Some plugins may have failed to update" >&2
    fi
fi

echo ""
echo "✅ Update complete!"
echo "   Restart Fish: exec fish"

