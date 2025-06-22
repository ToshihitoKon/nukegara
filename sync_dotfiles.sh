#!/bin/bash

# nukegara dotfiles synchronization script
# Usage: ./sync_dotfiles.sh <worktree-path> [to-home|from-home] [--force]

set -e

# Check if worktree path is provided
if [[ -z "$1" ]]; then
    echo "Error: Worktree path is required"
    echo "Usage: $0 <worktree-path> [to-home|from-home] [--force]"
    exit 1
fi

WORKTREE_PATH="$1"
HOME_DIR="$HOME"

# Validate worktree path exists
if [[ ! -d "$WORKTREE_PATH" ]]; then
    echo "Error: Worktree path '$WORKTREE_PATH' does not exist"
    exit 1
fi

# Shift arguments to handle remaining parameters
shift

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get dotfiles to sync (only specific patterns)
get_dotfiles_list() {
    local dotfiles=()
    
    # Pattern 1: Direct dotfiles in home directory (e.g., .zshrc, .vimrc)
    while IFS= read -r -d '' file; do
        local basename_file=$(basename "$file")
        # Only include dotfiles that start with . and are regular files
        if [[ "$basename_file" =~ ^\. && -f "$file" ]]; then
            # Skip .gitignore, CLAUDE.md, and this script
            if [[ "$basename_file" != ".gitignore" && "$basename_file" != "CLAUDE.md" && "$basename_file" != "sync_dotfiles.sh" ]]; then
                dotfiles+=("$basename_file")
            fi
        fi
    done < <(find "$WORKTREE_PATH" -mindepth 1 -maxdepth 1 -name ".*" -type f -print0)
    
    # Pattern 2: .config/[appname] directories
    if [[ -d "$WORKTREE_PATH/.config" ]]; then
        while IFS= read -r -d '' dir; do
            local app_name=$(basename "$dir")
            dotfiles+=(".config/$app_name")
        done < <(find "$WORKTREE_PATH/.config" -mindepth 1 -maxdepth 1 -type d -print0)
    fi
    
    printf '%s\n' "${dotfiles[@]}"
}

usage() {
    echo "Usage: $0 <worktree-path> [to-home|from-home] [--force]"
    echo ""
    echo "Arguments:"
    echo "  worktree-path  Path to the git worktree directory containing environment dotfiles"
    echo ""
    echo "Commands:"
    echo "  to-home    Copy files from worktree to home directory"
    echo "  from-home  Copy files from home directory to worktree"
    echo ""
    echo "Target files:"
    echo "  - Dotfiles in home directory (e.g., .zshrc, .vimrc, .tmux.conf)"
    echo "  - Directories under .config/ (e.g., .config/alacritty, .config/i3)"
    echo ""
    echo "Options:"
    echo "  --force    Skip diff confirmation and copy files directly"
    echo ""
    echo "Examples:"
    echo "  $0 ./env-macbook to-home              # Show diff and ask for confirmation before copying to ~"
    echo "  $0 ./env-macbook from-home --force    # Copy from ~ to worktree without confirmation"
}

show_diff() {
    local src="$1"
    local dst="$2"
    local file="$3"
    
    # Check if colordiff is available
    local diff_cmd="diff"
    if command -v colordiff >/dev/null 2>&1; then
        diff_cmd="colordiff"
    fi
    
    if [[ -f "$src/$file" && -f "$dst/$file" ]]; then
        echo -e "${BLUE}=== Diff for $file ===${NC}"
        if $diff_cmd -u "$dst/$file" "$src/$file" 2>/dev/null; then
            echo -e "${GREEN}No differences found${NC}"
        fi
        echo ""
    elif [[ -f "$src/$file" && ! -f "$dst/$file" ]]; then
        echo -e "${YELLOW}=== New file: $file ===${NC}"
        echo -e "${GREEN}File will be created${NC}"
        echo ""
    elif [[ ! -f "$src/$file" && -f "$dst/$file" ]]; then
        echo -e "${RED}=== File exists in destination but not in source: $file ===${NC}"
        echo -e "${YELLOW}File will be overwritten/removed${NC}"
        echo ""
    fi
}

show_directory_diff() {
    local src="$1"
    local dst="$2"
    local dir="$3"
    
    # Check if colordiff is available
    local diff_cmd="diff"
    if command -v colordiff >/dev/null 2>&1; then
        diff_cmd="colordiff"
    fi
    
    if [[ -d "$src/$dir" && -d "$dst/$dir" ]]; then
        echo -e "${BLUE}=== Directory diff for $dir ===${NC}"
        # Show file differences in directory
        local diff_output
        diff_output=$($diff_cmd -u -r "$dst/$dir" "$src/$dir" 2>/dev/null || true)
        if [[ -n "$diff_output" ]]; then
            echo "$diff_output"
        else
            echo -e "${GREEN}No differences found${NC}"
        fi
        echo ""
    elif [[ -d "$src/$dir" && ! -d "$dst/$dir" ]]; then
        echo -e "${YELLOW}=== New directory: $dir ===${NC}"
        echo -e "${GREEN}Directory will be created${NC}"
        echo ""
    fi
}

copy_file_or_dir() {
    local src="$1"
    local dst="$2"
    local item="$3"
    
    # Create destination directory if it doesn't exist
    local dst_dir
    dst_dir="$(dirname "$dst/$item")"
    [[ ! -d "$dst_dir" ]] && mkdir -p "$dst_dir"
    
    if [[ -f "$src/$item" ]]; then
        # Regular dotfile
        cp "$src/$item" "$dst/$item"
        echo -e "${GREEN}Copied file: $item${NC}"
    elif [[ -d "$src/$item" && "$item" =~ ^\.config/ ]]; then
        # .config directory - use cp -r
        if [[ -d "$dst/$item" ]]; then
            rm -rf "$dst/$item"
        fi
        cp -r "$src/$item" "$dst/$item"
        echo -e "${GREEN}Copied directory: $item${NC}"
    else
        echo -e "${YELLOW}Source not found or invalid pattern: $item${NC}"
    fi
}

main() {
    local direction="$1"
    local force="$2"
    
    if [[ -z "$direction" ]]; then
        usage
        exit 1
    fi
    
    local src_dir
    local dst_dir
    
    case "$direction" in
        "to-home")
            src_dir="$WORKTREE_PATH"
            dst_dir="$HOME_DIR"
            echo -e "${BLUE}Copying from worktree to home directory${NC}"
            ;;
        "from-home")
            src_dir="$HOME_DIR"
            dst_dir="$WORKTREE_PATH"
            echo -e "${BLUE}Copying from home directory to worktree${NC}"
            ;;
        *)
            echo -e "${RED}Error: Invalid direction '$direction'${NC}"
            usage
            exit 1
            ;;
    esac
    
    echo "Source: $src_dir"
    echo "Destination: $dst_dir"
    echo ""
    
    # Get list of files that exist in nukegara
    local dotfiles_list
    readarray -t dotfiles_list < <(get_dotfiles_list)
    
    # Show diffs if not forcing
    if [[ "$force" != "--force" ]]; then
        echo -e "${YELLOW}=== Showing differences ===${NC}"
        echo ""
        
        for item in "${dotfiles_list[@]}"; do
            if [[ "$item" =~ ^\.config/ ]]; then
                # .config directory
                show_directory_diff "$src_dir" "$dst_dir" "$item"
            else
                # Regular dotfile
                show_diff "$src_dir" "$dst_dir" "$item"
            fi
        done
        
        echo -e "${YELLOW}Do you want to proceed with copying? (y/N)${NC}"
        read -r response
        case "$response" in
            [yY]|[yY][eE][sS])
                echo -e "${GREEN}Proceeding with copy...${NC}"
                ;;
            *)
                echo -e "${YELLOW}Operation cancelled${NC}"
                exit 0
                ;;
        esac
        echo ""
    fi
    
    # Perform the copy
    echo -e "${BLUE}=== Copying files ===${NC}"
    for item in "${dotfiles_list[@]}"; do
        if [[ -e "$src_dir/$item" ]]; then
            copy_file_or_dir "$src_dir" "$dst_dir" "$item"
        else
            echo -e "${YELLOW}Skipped (not found): $item${NC}"
        fi
    done
    
    echo ""
    echo -e "${GREEN}Synchronization completed!${NC}"
}

main "$@"
