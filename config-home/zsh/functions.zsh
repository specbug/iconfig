# =============================================================================
# Zsh Functions
# =============================================================================
# Source this file from .zshrc: source ~/.config/zsh/functions.zsh
# =============================================================================

# -----------------------------------------------------------------------------
# Directory & Navigation
# -----------------------------------------------------------------------------

# Create directory and cd into it
mkcd() {
    mkdir -p "$@" && cd "${@: -1}"
}

# Find and cd into directory (uses fzf if available)
cdf() {
    local dir
    if command -v fzf &> /dev/null; then
        dir=$(find ${1:-.} -type d 2>/dev/null | fzf +m) && cd "$dir"
    else
        echo "fzf not installed"
    fi
}

# cd up N directories
up() {
    local d=""
    local limit="${1:-1}"
    for ((i=1; i<=limit; i++)); do
        d="../$d"
    done
    cd "$d"
}

# Quick project navigation (customize paths)
proj() {
    local base="${HOME}/Documents/Personal"
    if [[ -n "$1" ]]; then
        cd "${base}/$1"
    else
        cd "$base"
    fi
}

# -----------------------------------------------------------------------------
# File Operations
# -----------------------------------------------------------------------------

# Extract any archive
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.tar.xz)    tar xJf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Create a backup of a file
backup() {
    cp "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"
}

# Find file by name
ff() {
    if command -v fd &> /dev/null; then
        fd "$@"
    else
        find . -name "*$1*"
    fi
}

# Find file and open in editor
fe() {
    local file
    if command -v fzf &> /dev/null; then
        file=$(fzf --preview 'bat --color=always {}' --preview-window='right:60%')
        [[ -n "$file" ]] && ${EDITOR:-nvim} "$file"
    else
        echo "fzf not installed"
    fi
}

# -----------------------------------------------------------------------------
# Git Helpers
# -----------------------------------------------------------------------------

# Git commit with message
gcmsg() {
    git commit -m "$*"
}

# Git add and commit
gac() {
    git add "${@:1:$#-1}" && git commit -m "${@: -1}"
}

# Git add all and commit
gaac() {
    git add -A && git commit -m "$*"
}

# Interactive git add (uses fzf)
gadd() {
    if command -v fzf &> /dev/null; then
        git status -s | fzf -m --preview 'git diff --color=always {2}' | awk '{print $2}' | xargs git add
    else
        git add -p
    fi
}

# Show git branch with fzf
gbf() {
    if command -v fzf &> /dev/null; then
        git branch -a | fzf | sed 's/^[* ]*//' | sed 's/remotes\/origin\///' | xargs git checkout
    fi
}

# Delete merged branches
gclean() {
    git branch --merged | grep -v '\*\|main\|master\|develop' | xargs -n 1 git branch -d
}

# -----------------------------------------------------------------------------
# Development Utilities
# -----------------------------------------------------------------------------

# Quick HTTP server
serve() {
    local port="${1:-8000}"
    python3 -m http.server "$port"
}

# JSON pretty print
json() {
    if [[ -t 0 ]]; then
        python3 -m json.tool "$@"
    else
        python3 -m json.tool
    fi
}

# URL encode/decode
urlencode() { python3 -c "import urllib.parse; print(urllib.parse.quote('$1'))"; }
urldecode() { python3 -c "import urllib.parse; print(urllib.parse.unquote('$1'))"; }

# Base64 encode/decode
b64e() { echo -n "$1" | base64; }
b64d() { echo -n "$1" | base64 -d; }

# Generate random string
randstr() {
    local len="${1:-32}"
    openssl rand -base64 $((len * 3 / 4 + 1)) | head -c "$len"
    echo
}

# UUID generator
uuid() {
    uuidgen | tr '[:upper:]' '[:lower:]'
}

# -----------------------------------------------------------------------------
# System & Process
# -----------------------------------------------------------------------------

# Find process by name and optionally kill
pskill() {
    local pid
    pid=$(ps aux | grep -v grep | grep -i "$1" | awk '{print $2}')
    if [[ -n "$pid" ]]; then
        echo "Killing PID: $pid"
        kill -9 $pid
    else
        echo "No process found matching: $1"
    fi
}

# Show listening ports
listening() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        lsof -iTCP -sTCP:LISTEN -n -P
    else
        netstat -tlnp
    fi
}

# Kill process on port
killport() {
    local port="$1"
    local pid=$(lsof -ti ":$port")
    if [[ -n "$pid" ]]; then
        echo "Killing PID $pid on port $port"
        kill -9 "$pid"
    else
        echo "No process found on port $port"
    fi
}

# -----------------------------------------------------------------------------
# Docker Helpers
# -----------------------------------------------------------------------------

# Docker shell into container
dsh() {
    docker exec -it "$1" /bin/sh
}

# Docker bash into container
dbash() {
    docker exec -it "$1" /bin/bash
}

# Stop all running containers
dstopall() {
    docker stop $(docker ps -q)
}

# Remove all stopped containers
drmall() {
    docker rm $(docker ps -aq)
}

# -----------------------------------------------------------------------------
# Utility
# -----------------------------------------------------------------------------

# Quick notes
note() {
    local notes_dir="${HOME}/notes"
    [[ -d "$notes_dir" ]] || mkdir -p "$notes_dir"
    if [[ -n "$1" ]]; then
        echo "$(date +%Y-%m-%d\ %H:%M:%S): $*" >> "${notes_dir}/quick.md"
        echo "Note added."
    else
        ${EDITOR:-nvim} "${notes_dir}/quick.md"
    fi
}

# Weather
weather() {
    curl -s "wttr.in/${1:-}"
}

# Cheat sheet
cheat() {
    curl -s "cheat.sh/$1"
}

# Calculator
calc() {
    echo "$*" | bc -l
}

# Timer
timer() {
    local seconds="${1:-60}"
    echo "Timer: $seconds seconds"
    sleep "$seconds"
    echo -e "\a\nTime's up!"
    osascript -e 'display notification "Timer finished!" with title "Timer"' 2>/dev/null
}
