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
        # Validate source exists
        if not test -e "$src"
            echo "Error: Source '$src' does not exist" >&2
            continue
        end
        # Validate destination is a directory or create it
        if not test -d "$dest"
            echo "Error: Destination '$dest' is not a directory" >&2
            return 1
        end
        # Check if destination file already exists
        set dest_file "$dest/"(path basename $src)
        if test -e "$dest_file"
            echo "Warning: Destination '$dest_file' already exists. Overwriting..." >&2
        end
        # Validate required tools
        if not type -q pv
            echo "Error: pv (pipe viewer) is required but not installed" >&2
            return 1
        end
        if test -f "$src"
            set -l file_size (stat -f%z "$src" 2>/dev/null; or stat -c%s "$src" 2>/dev/null; or echo "unknown")
            echo "Copying $src → $dest (size: $file_size bytes)"
            if not pv "$src" > "$dest_file" ^/dev/null
                echo "Error: Failed to copy file" >&2
                return 1
            end
            echo "✅ Copied successfully"
        else if test -d "$src"
            echo "Copying directory $src → $dest"
            if not type -q tar
                echo "Error: tar is required but not installed" >&2
                return 1
            end
            if not tar cf - "$src" 2>/dev/null | pv ^/dev/null | tar xf - -C "$dest" 2>/dev/null
                echo "Error: Failed to copy directory" >&2
                return 1
            end
            echo "✅ Copied successfully"
        end
    end
end

# --- Move with progress ---
function mvc
    if count $argv < 2
        echo "Usage: mvc source [source2 ...] target_dir" >&2
        return 1
    end
    # Validate all arguments are provided
    if test (count $argv) -lt 2
        echo "Error: At least one source and one destination required" >&2
        return 1
    end
    for src in $argv[1..-2]
        set dest $argv[-1]
        # Validate source exists and is readable
        if not test -e "$src"
            echo "Error: Source '$src' does not exist" >&2
            continue
        end
        if not test -r "$src"
            echo "Error: Source '$src' is not readable" >&2
            continue
        end
        # Validate destination is a directory
        if not test -d "$dest"
            echo "Error: Destination '$dest' is not a directory" >&2
            return 1
        end
        if not test -w "$dest"
            echo "Error: Destination '$dest' is not writable" >&2
            return 1
        end
        # Check if destination file already exists
        set dest_file "$dest/"(path basename $src)
        if test -e "$dest_file"
            echo "Warning: Destination '$dest_file' already exists. Overwriting..." >&2
        end
        # Validate required tools
        if not type -q pv
            echo "Error: pv (pipe viewer) is required but not installed" >&2
            return 1
        end
        if test -f "$src"
            set -l file_size (stat -f%z "$src" 2>/dev/null; or stat -c%s "$src" 2>/dev/null; or echo "unknown")
            echo "Moving $src → $dest (size: $file_size bytes)"
            if pv "$src" > "$dest_file"
                if not command rm "$src"
                    echo "Warning: File copied but source deletion failed" >&2
                else
                    echo "✅ Moved successfully"
                end
            else
                echo "Error: Failed to move file. Source preserved." >&2
                return 1
            end
        else if test -d "$src"
            echo "Moving directory $src → $dest"
            if not type -q tar
                echo "Error: tar is required but not installed" >&2
                return 1
            end
            if tar cf - "$src" 2>/dev/null | pv ^/dev/null | tar xf - -C "$dest" 2>/dev/null
                if not command rm -rf "$src"
                    echo "Warning: Directory copied but source deletion failed" >&2
                else
                    echo "✅ Moved successfully"
                end
            else
                echo "Error: Failed to move directory. Source preserved." >&2
                return 1
            end
        end
    end
end

# --- Trash management ---
function trash
    # Filter out common rm flags (ignore them, like -rf, -r, -f, etc.)
    # Use a different approach: build array explicitly
    set files
    for arg in $argv
        # Skip flags (arguments starting with -)
        if not string match -q -- '-*' "$arg"
            set files $files "$arg"
        end
    end
    
    # If no files after filtering flags, show usage
    if test (count $files) -eq 0
        if test (count $argv) -gt 0
            echo "Usage: trash file [file2 ...]" >&2
            echo "Note: Only flags were provided (like -rf). Please provide file names." >&2
        else
            echo "Usage: trash file [file2 ...]" >&2
            echo "Note: Flags like -rf are ignored. If using globs (like fish_*), ensure files exist." >&2
        end
        return 1
    end
    
    # Expand glob patterns manually if they contain wildcards
    # Fish may expand globs before aliases, but we handle both cases
    set expanded_files
    for pattern in $files
        # Check if pattern contains glob characters
        if string match -q -- '*\**' "$pattern"; or string match -q -- '*\?*' "$pattern"; or string match -q -- '*\[*' "$pattern"
            # Pattern contains glob characters, expand it using find
            # Get the directory part and the pattern part
            set -l dir_part (dirname "$pattern")
            set -l name_part (basename "$pattern")
            
            # If dir_part is ".", search current directory
            if test "$dir_part" = "." -o "$dir_part" = ""
                set dir_part (pwd)
            end
            
            # Use find to expand the glob pattern
            set -l matches (find "$dir_part" -maxdepth 1 -name "$name_part" 2>/dev/null)
            if test (count $matches) -gt 0
                for match in $matches
                    set expanded_files $expanded_files "$match"
                end
            else
                echo "Warning: No files match pattern '$pattern', skipping" >&2
            end
        else
            # No glob characters, use as-is (might already be expanded by Fish)
            set expanded_files $expanded_files "$pattern"
        end
    end
    
    if test (count $expanded_files) -eq 0
        echo "No files to trash" >&2
        return 1
    end
    
    set -l trash_dir ~/.local/share/Trash/files
    # Validate home directory is writable
    if not test -w ~
        echo "Error: No write permission to home directory" >&2
        return 1
    end
    if not mkdir -p "$trash_dir"
        echo "Error: Failed to create trash directory '$trash_dir'" >&2
        return 1
    end
    
    set -l moved_count 0
    for f in $expanded_files
        # Validate input is a valid path
        if test -z "$f"
            echo "Warning: Empty argument, skipping" >&2
            continue
        end
        # Check if file exists
        if not test -e "$f"
            echo "Warning: '$f' does not exist, skipping" >&2
            continue
        end
        if not test -w (dirname "$f")
            echo "Error: No write permission to remove '$f'" >&2
            continue
        end
        mv "$f" "$trash_dir/" 2>/dev/null
        if test $status -ne 0
            echo "Error: Failed to move '$f' to trash" >&2
            return 1
        end
        set moved_count (math $moved_count + 1)
    end
    
    if test $moved_count -gt 0
        echo "Moved $moved_count file(s) to Trash 🗑️"
    else
        echo "No files were moved to trash" >&2
        return 1
    end
end

function etrash
    set -l trash_dir ~/.local/share/Trash/files
    if not test -d $trash_dir
        echo "Trash directory does not exist. Nothing to empty."
        return 0
    end
    # Count files before deletion for confirmation
    set -l file_count (count (find $trash_dir -type f 2>/dev/null))
    if test $file_count -eq 0
        echo "Trash is already empty."
        return 0
    end
    echo "About to permanently delete $file_count file(s) from trash."
    read -P "Are you sure? (y/N): " confirm
    if test "$confirm" != "y" -a "$confirm" != "Y"
        echo "Cancelled."
        return 0
    end
    rm -rf "$trash_dir"/* 2>/dev/null
    if test $status -ne 0
        echo "Error: Failed to empty trash" >&2
        return 1
    end
    echo "Trash emptied 🧹"
end

# --- Fuzzy cd using fzf ---
function fcd
    if not type -q fzf
        echo "Error: fzf is not installed" >&2
        return 1
    end
    if not type -q find
        echo "Error: find is not installed" >&2
        return 1
    end
    set -l search_path "."
    if count $argv > 0
        set search_path $argv[1]
        # Validate search path exists
        if not test -d "$search_path"
            echo "Error: Search path '$search_path' is not a directory" >&2
            return 1
        end
    end
    set dir (find "$search_path" -type d -maxdepth 10 2>/dev/null | fzf)
    if test -n "$dir"
        if test -d "$dir"
            cd "$dir"
        else
            echo "Error: Selected directory '$dir' does not exist" >&2
            return 1
        end
    end
end

# --- Notification echo ---
function notify_done
    printf '\033[1;32m✔ Done: %s\033[0m\n' "$argv"
end

# --- Extract archives (auto-detect format) ---
function extract
    if count $argv -eq 0
        echo "Usage: extract <archive> [destination]" >&2
        echo "Supported: zip, tar, tar.gz, tar.bz2, tar.xz, 7z, rar, gz, bz2, xz" >&2
        return 1
    end
    
    set -l archive $argv[1]
    set -l dest "."
    if count $argv > 1
        set dest $argv[2]
    end
    
    if not test -f "$archive"
        echo "Error: Archive '$archive' does not exist" >&2
        return 1
    end
    
    set -l basename (path basename "$archive")
    set -l name (string replace -r '\.[^.]*$' '' -- $basename)
    
    # Create destination directory if needed
    if not test -d "$dest"
        if not mkdir -p "$dest"
            echo "Error: Failed to create destination directory '$dest'" >&2
            return 1
        end
    end
    
    # Detect and extract based on file extension
    switch $archive
        case '*.tar.bz2' '*.tbz2'
            if not type -q tar
                echo "Error: tar is required" >&2
                return 1
            end
            echo "Extracting $archive to $dest..."
            tar -xjf "$archive" -C "$dest" 2>/dev/null
        case '*.tar.gz' '*.tgz'
            if not type -q tar
                echo "Error: tar is required" >&2
                return 1
            end
            echo "Extracting $archive to $dest..."
            tar -xzf "$archive" -C "$dest" 2>/dev/null
        case '*.tar.xz' '*.txz'
            if not type -q tar
                echo "Error: tar is required" >&2
                return 1
            end
            echo "Extracting $archive to $dest..."
            tar -xJf "$archive" -C "$dest" 2>/dev/null
        case '*.tar'
            if not type -q tar
                echo "Error: tar is required" >&2
                return 1
            end
            echo "Extracting $archive to $dest..."
            tar -xf "$archive" -C "$dest" 2>/dev/null
        case '*.zip'
            if not type -q unzip
                echo "Error: unzip is required" >&2
                return 1
            end
            echo "Extracting $archive to $dest..."
            unzip -q "$archive" -d "$dest" 2>/dev/null
        case '*.7z'
            if not type -q 7z
                echo "Error: 7z is required" >&2
                return 1
            end
            echo "Extracting $archive to $dest..."
            7z x "$archive" -o"$dest" -y >/dev/null ^&1
        case '*.rar'
            if not type -q unrar
                echo "Error: unrar is required" >&2
                return 1
            end
            echo "Extracting $archive to $dest..."
            unrar x "$archive" "$dest" >/dev/null ^&1
        case '*.gz'
            if not type -q gunzip
                echo "Error: gunzip is required" >&2
                return 1
            end
            echo "Extracting $archive to $dest..."
            gunzip -c "$archive" > "$dest/$name" 2>/dev/null
        case '*.bz2'
            if not type -q bunzip2
                echo "Error: bunzip2 is required" >&2
                return 1
            end
            echo "Extracting $archive to $dest..."
            bunzip2 -c "$archive" > "$dest/$name" 2>/dev/null
        case '*.xz'
            if not type -q unxz
                echo "Error: unxz is required" >&2
                return 1
            end
            echo "Extracting $archive to $dest..."
            unxz -c "$archive" > "$dest/$name" 2>/dev/null
        case '*'
            echo "Error: Unsupported archive format: $archive" >&2
            echo "Supported: zip, tar, tar.gz, tar.bz2, tar.xz, 7z, rar, gz, bz2, xz" >&2
            return 1
    end
    
    if test $status -eq 0
        echo "✅ Extracted successfully to $dest"
    else
        echo "Error: Extraction failed" >&2
        return 1
    end
end

# --- Create directory and cd into it ---
function mkcd
    if count $argv -eq 0
        echo "Usage: mkcd <directory>" >&2
        return 1
    end
    
    set -l dir $argv[1]
    
    if test -e "$dir" -a ! -d "$dir"
        echo "Error: '$dir' exists but is not a directory" >&2
        return 1
    end
    
    if not test -d "$dir"
        if not mkdir -p "$dir"
            echo "Error: Failed to create directory '$dir'" >&2
            return 1
        end
    end
    
    cd "$dir"
end

# --- Find process by name ---
function psgrep
    if count $argv -eq 0
        echo "Usage: psgrep <process_name>" >&2
        return 1
    end
    
    if not type -q ps
        echo "Error: ps is required" >&2
        return 1
    end
    
    if type -q pgrep
        pgrep -af "$argv[1]"
    else
        ps aux | grep -v grep | grep -- "$argv[1]"
    end
end

# --- Disk usage for current directory ---
function duh
    if not type -q du
        echo "Error: du is required" >&2
        return 1
    end
    
    set -l path "."
    if count $argv > 0
        set path $argv[1]
    end
    
    if not test -e "$path"
        echo "Error: Path '$path' does not exist" >&2
        return 1
    end
    
    # Use human-readable format, sort by size
    if type -q sort
        du -h "$path" | sort -hr | head -20
    else
        du -h "$path"
    end
end

# --- Find large files ---
function findlarge
    if not type -q find
        echo "Error: find is required" >&2
        return 1
    end
    
    set -l size "100M"
    set -l path "."
    
    if count $argv > 0
        set size $argv[1]
    end
    if count $argv > 1
        set path $argv[2]
    end
    
    if not test -d "$path"
        echo "Error: Path '$path' is not a directory" >&2
        return 1
    end
    
    echo "Finding files larger than $size in $path..."
    find "$path" -type f -size +"$size" -exec ls -lh {} \; 2>/dev/null | awk '{print $5, $9}' | sort -hr
end

# --- Quick project finder/launcher ---
function proj
    if not type -q fzf
        echo "Error: fzf is required" >&2
        return 1
    end
    
    # Common project directories
    set -l search_dirs $HOME/projects $HOME/dev $HOME/development $HOME/code $HOME/src
    set -l base_dir $HOME
    
    if count $argv > 0
        set base_dir $argv[1]
    end
    
    # Build search paths
    set search_paths $base_dir
    for dir in $search_dirs
        if test -d "$dir"
            set search_paths $search_paths $dir
        end
    end
    
    # Find directories that look like projects (contain .git, package.json, etc.)
    set projects
    for dir in $search_paths
        if test -d "$dir"
            set -l found (find "$dir" -maxdepth 3 -type d \( -name '.git' -o -name 'node_modules' -o -name 'package.json' -o -name 'Cargo.toml' -o -name 'go.mod' -o -name 'requirements.txt' \) -prune -o -type d -print 2>/dev/null | head -50)
            set projects $projects $found
        end
    end
    
    # Use fzf to select
    set -l selected (printf '%s\n' $projects | fzf --height 40% --preview 'ls -la {} 2>/dev/null | head -20')
    
    if test -n "$selected" -a -d "$selected"
        cd "$selected"
        echo "📁 Switched to: $selected"
    end
end
