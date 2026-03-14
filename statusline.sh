#!/bin/bash

# Starship-inspired statusline for Claude Code (Bracketed Segments Format)
# Catppuccin Mocha color palette - matches ~/.config/starship.toml
# Line 1: user, dir, git, runtime, time, model+style
# Line 2: context bar, cost, duration

# Read JSON input
input=$(cat)

# Extract values from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')
output_style=$(echo "$input" | jq -r '.output_style.name')
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# Catppuccin Mocha colors - Full palette (using ANSI codes)
ROSEWATER='\033[38;2;245;224;220m'
FLAMINGO='\033[38;2;242;205;205m'
PINK='\033[38;2;245;194;231m'
MAUVE='\033[38;2;203;166;247m'
RED='\033[38;2;243;139;168m'
MAROON='\033[38;2;235;160;172m'
PEACH='\033[38;2;250;179;135m'
YELLOW='\033[38;2;249;226;175m'
GREEN='\033[38;2;166;227;161m'
TEAL='\033[38;2;148;226;213m'
SKY='\033[38;2;137;220;235m'
SAPPHIRE='\033[38;2;116;199;236m'
BLUE='\033[38;2;137;180;250m'
LAVENDER='\033[38;2;180;190;254m'
TEXT='\033[38;2;205;214;244m'
SUBTEXT0='\033[38;2;166;173;200m'
BASE='\033[38;2;30;30;46m'
CRUST='\033[38;2;17;17;27m'
RESET='\033[0m'

# Bracket style (Starship-inspired)
BRACKET_OPEN="["
BRACKET_CLOSE="]"
SPACE=" "

# Get OS icon
os_icon="🍎"  # macOS icon (standard Unicode)

# Get username
user=$(whoami)

# Get directory with truncation (last component)
dir_path="$cwd"
if [[ "$dir_path" == "$HOME"* ]]; then
  dir_path="~${dir_path#$HOME}"
fi
IFS='/' read -ra PARTS <<< "${dir_path#/}"
num_parts=${#PARTS[@]}
if [ "$num_parts" -gt 1 ]; then
  dir_display="…/${PARTS[$((num_parts-1))]}"
else
  dir_display="$dir_path"
fi

# --- Git with caching (5s TTL) ---
CACHE_FILE="/tmp/claude-statusline-git-cache"
CACHE_MAX_AGE=5

cache_is_stale() {
  [ ! -f "$CACHE_FILE" ] || \
  [ $(($(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0))) -gt $CACHE_MAX_AGE ]
}

git_branch=""
git_status=""

if cache_is_stale; then
  if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
    status_flags=""
    if ! git -C "$cwd" --no-optional-locks diff --quiet 2>/dev/null; then
      status_flags="${status_flags}●"
    fi
    if ! git -C "$cwd" --no-optional-locks diff --cached --quiet 2>/dev/null; then
      status_flags="${status_flags}+"
    fi
    if [ -n "$(git -C "$cwd" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | head -1)" ]; then
      status_flags="${status_flags}?"
    fi
    echo "${branch}|${status_flags}" > "$CACHE_FILE"
  else
    echo "|" > "$CACHE_FILE"
  fi
fi

IFS='|' read -r cached_branch cached_status < "$CACHE_FILE"
if [ -n "$cached_branch" ]; then
  git_branch="🌿 $cached_branch "
  if [ -n "$cached_status" ]; then
    git_status=" ${cached_status} "
  fi
fi

# Detect runtime version
runtime_version=""
if [ -f "$cwd/package.json" ]; then
  if [ -f "$cwd/.nvmrc" ] && command -v node &> /dev/null; then
    version=$(node -v 2>/dev/null | sed 's/^v//')
    [ -n "$version" ] && runtime_version="⬢ v$version "
  elif [ -f "$cwd/.node-version" ] && command -v node &> /dev/null; then
    version=$(node -v 2>/dev/null | sed 's/^v//')
    [ -n "$version" ] && runtime_version="⬢ v$version "
  elif [ -f "$cwd/bun.lockb" ] && command -v bun &> /dev/null; then
    version=$(bun --version 2>/dev/null)
    [ -n "$version" ] && runtime_version="🥟 v$version "
  elif command -v bun &> /dev/null; then
    version=$(bun --version 2>/dev/null)
    [ -n "$version" ] && runtime_version="🥟 v$version "
  elif command -v node &> /dev/null; then
    version=$(node -v 2>/dev/null | sed 's/^v//')
    [ -n "$version" ] && runtime_version="⬢ v$version "
  fi
fi

# Get current time
current_time=$(date +%R)

# === LINE 1: User, Dir, Git, Runtime, Time, Model+Style ===

# Segment 1: User (Mauve)
printf "${SUBTEXT0}${BRACKET_OPEN}${RESET}"
printf "${MAUVE}${os_icon} ${user}${RESET}"
printf "${SUBTEXT0}${BRACKET_CLOSE}${RESET}"
printf "${SPACE}"

# Segment 2: Directory (Blue)
printf "${SUBTEXT0}${BRACKET_OPEN}${RESET}"
printf "${BLUE}📁 ${dir_display}${RESET}"
printf "${SUBTEXT0}${BRACKET_CLOSE}${RESET}"

# Segment 3: Git Branch & Status (Peach/Yellow)
if [ -n "$git_branch" ]; then
  printf "${SPACE}"
  printf "${SUBTEXT0}${BRACKET_OPEN}${RESET}"
  printf "${PEACH}${git_branch}${RESET}"
  if [ -n "$git_status" ]; then
    printf "${YELLOW}${git_status}${RESET}"
  fi
  printf "${SUBTEXT0}${BRACKET_CLOSE}${RESET}"
fi

# Segment 4: Runtime Version (Green)
if [ -n "$runtime_version" ]; then
  printf "${SPACE}"
  printf "${SUBTEXT0}${BRACKET_OPEN}${RESET}"
  printf "${GREEN}${runtime_version}${RESET}"
  printf "${SUBTEXT0}${BRACKET_CLOSE}${RESET}"
fi

# Segment 5: Time (Sky)
printf "${SPACE}"
printf "${SUBTEXT0}${BRACKET_OPEN}${RESET}"
printf "${SKY}🕐 ${current_time}${RESET}"
printf "${SUBTEXT0}${BRACKET_CLOSE}${RESET}"

# Segment 6: Claude Model & Output Style (Text with Lavender accent)
printf "${SPACE}"
printf "${SUBTEXT0}${BRACKET_OPEN}${RESET}"
if [ "$output_style" != "null" ] && [ -n "$output_style" ]; then
  printf "${TEXT}🤖 ${model} ${LAVENDER}✨ ${output_style}${RESET}"
else
  printf "${TEXT}🤖 ${model}${RESET}"
fi
printf "${SUBTEXT0}${BRACKET_CLOSE}${RESET}"

printf "\n"

# === LINE 2: Context Bar, Cost, Duration ===

# Context bar color (Green < 70%, Yellow 70-89%, Red 90%+)
if [ "$pct" -ge 90 ]; then
  BAR_COLOR="$RED"
elif [ "$pct" -ge 70 ]; then
  BAR_COLOR="$YELLOW"
else
  BAR_COLOR="$GREEN"
fi

# Build 15-char progress bar
BAR_WIDTH=15
FILLED=$((pct * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && BAR=$(printf "%${FILLED}s" | tr ' ' '▓')
[ "$EMPTY" -gt 0 ] && BAR="${BAR}$(printf "%${EMPTY}s" | tr ' ' '░')"

# Format cost
cost_fmt=$(printf '$%.2f' "$cost")

# Format duration
duration_sec=$((duration_ms / 1000))
mins=$((duration_sec / 60))
secs=$((duration_sec % 60))

# Segment 7: Context bar (color-coded)
printf "${SUBTEXT0}${BRACKET_OPEN}${RESET}"
printf "${BAR_COLOR}${BAR}${RESET}"
printf " ${TEXT}${pct}%%${RESET}"
printf "${SUBTEXT0}${BRACKET_CLOSE}${RESET}"
printf "${SPACE}"

# Segment 8: Cost (Flamingo)
printf "${SUBTEXT0}${BRACKET_OPEN}${RESET}"
printf "${FLAMINGO}💰 ${cost_fmt}${RESET}"
printf "${SUBTEXT0}${BRACKET_CLOSE}${RESET}"
printf "${SPACE}"

# Segment 9: Duration (Teal)
printf "${SUBTEXT0}${BRACKET_OPEN}${RESET}"
printf "${TEAL}⏱️  ${mins}m ${secs}s${RESET}"
printf "${SUBTEXT0}${BRACKET_CLOSE}${RESET}"
