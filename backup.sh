#!/usr/bin/env bash
# ======================================
# Fish UltraPro Backup/Restore Utility
# ======================================
# This script helps manage backups of Fish configuration
# Usage:
#   backup.sh backup    - Create a backup of current config
#   backup.sh list      - List all available backups
#   backup.sh restore   - Restore from most recent backup
#   backup.sh restore <backup_dir> - Restore from specific backup

set -e

CONFIG_DIR="$HOME/.config/fish"
BACKUP_BASE="$HOME/.config/fish_backup"

backup() {
    if [ ! -d "$CONFIG_DIR" ]; then
        echo "Error: Fish config directory '$CONFIG_DIR' does not exist" >&2
        exit 1
    fi
    
    local backup_dir="${BACKUP_BASE}_$(date +%Y%m%d%H%M%S)_$$"
    echo "Creating backup to: $backup_dir"
    
    if ! mkdir -p "$backup_dir"; then
        echo "Error: Failed to create backup directory" >&2
        exit 1
    fi
    
    # Handle case where CONFIG_DIR might be empty or glob fails
    if [ -n "$(ls -A "$CONFIG_DIR" 2>/dev/null)" ]; then
        if ! cp -r "$CONFIG_DIR"/* "$backup_dir/" 2>/dev/null; then
            echo "Error: Failed to copy config files" >&2
            rm -rf "$backup_dir"
            exit 1
        fi
    else
        echo "Warning: Config directory is empty" >&2
    fi
    
    echo "✅ Backup created successfully: $backup_dir"
    echo "   To restore: $0 restore $backup_dir"
}

list_backups() {
    local backups
    backups=$(ls -d ${BACKUP_BASE}_* 2>/dev/null | sort -r)
    
    if [ -z "$backups" ]; then
        echo "No backups found"
        return 0
    fi
    
    echo "Available backups:"
    local count=1
    for backup in $backups; do
        local size
        size=$(du -sh "$backup" 2>/dev/null | cut -f1)
        local date
        date=$(stat -c %y "$backup" 2>/dev/null || stat -f %Sm "$backup" 2>/dev/null || echo "unknown")
        printf "  %d. %s (%s, %s)\n" "$count" "$(basename "$backup")" "$size" "$date"
        count=$((count + 1))
    done
}

restore() {
    local backup_dir="$1"
    
    if [ -z "$backup_dir" ]; then
        # Find most recent backup
        backup_dir=$(ls -d ${BACKUP_BASE}_* 2>/dev/null | sort -r | head -n 1)
        if [ -z "$backup_dir" ]; then
            echo "Error: No backups found" >&2
            exit 1
        fi
        echo "Using most recent backup: $backup_dir"
    fi
    
    if [ ! -d "$backup_dir" ]; then
        echo "Error: Backup directory '$backup_dir' does not exist" >&2
        exit 1
    fi
    
    echo "⚠️  Warning: This will replace your current Fish configuration!"
    echo "   Backup: $backup_dir"
    echo "   Target: $CONFIG_DIR"
    read -p "Continue? (y/N): " confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Cancelled"
        exit 0
    fi
    
    # Create backup of current config before restoring
    local current_backup="${BACKUP_BASE}_before_restore_$(date +%Y%m%d%H%M%S)_$$"
    if [ -d "$CONFIG_DIR" ]; then
        echo "Backing up current config to: $current_backup"
        mkdir -p "$current_backup"
        if [ -n "$(ls -A "$CONFIG_DIR" 2>/dev/null)" ]; then
            cp -r "$CONFIG_DIR"/* "$current_backup/" 2>/dev/null || true
        fi
    fi
    
    # Restore from backup
    if ! mkdir -p "$CONFIG_DIR"; then
        echo "Error: Failed to create config directory" >&2
        exit 1
    fi
    
    echo "Restoring from backup..."
    # Handle case where backup_dir might be empty or glob fails
    if [ -n "$(ls -A "$backup_dir" 2>/dev/null)" ]; then
        if ! cp -r "$backup_dir"/* "$CONFIG_DIR/"; then
            echo "Error: Failed to restore backup" >&2
            exit 1
        fi
    else
        echo "Error: Backup directory is empty" >&2
        exit 1
    fi
    
    echo "✅ Configuration restored successfully"
    echo "   Previous config backed up to: $current_backup"
    echo "   Restart Fish: exec fish"
}

case "${1:-}" in
    backup)
        backup
        ;;
    list)
        list_backups
        ;;
    restore)
        restore "$2"
        ;;
    *)
        echo "Usage: $0 {backup|list|restore [backup_dir]}" >&2
        echo "" >&2
        echo "Commands:" >&2
        echo "  backup              - Create a backup of current config" >&2
        echo "  list                - List all available backups" >&2
        echo "  restore             - Restore from most recent backup" >&2
        echo "  restore <backup_dir> - Restore from specific backup" >&2
        exit 1
        ;;
esac

