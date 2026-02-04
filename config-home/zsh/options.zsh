# =============================================================================
# Zsh Options
# =============================================================================
# Source this file from .zshrc: source ~/.config/zsh/options.zsh
# =============================================================================

# -----------------------------------------------------------------------------
# Directory Navigation
# -----------------------------------------------------------------------------
setopt AUTO_CD              # cd by typing directory name
setopt AUTO_PUSHD           # push directories to stack automatically
setopt PUSHD_IGNORE_DUPS    # don't push duplicates
setopt PUSHD_SILENT         # don't print directory stack after pushd/popd
setopt CDABLE_VARS          # cd into named directories

# -----------------------------------------------------------------------------
# Globbing & Expansion
# -----------------------------------------------------------------------------
setopt EXTENDED_GLOB        # extended globbing (#, ~, ^)
setopt GLOB_DOTS            # include dotfiles in glob
setopt NO_CASE_GLOB         # case-insensitive globbing
setopt NUMERIC_GLOB_SORT    # sort numeric filenames numerically

# -----------------------------------------------------------------------------
# Completion
# -----------------------------------------------------------------------------
setopt ALWAYS_TO_END        # move cursor to end after completion
setopt AUTO_LIST            # list choices on ambiguous completion
setopt AUTO_MENU            # show completion menu on tab
setopt AUTO_PARAM_SLASH     # add trailing slash for directories
setopt COMPLETE_IN_WORD     # complete from both ends of word
setopt NO_LIST_BEEP         # don't beep on ambiguous completion

# -----------------------------------------------------------------------------
# History
# -----------------------------------------------------------------------------
setopt EXTENDED_HISTORY          # save timestamp with history
setopt HIST_EXPIRE_DUPS_FIRST    # expire duplicates first when trimming
setopt HIST_FIND_NO_DUPS         # don't show duplicates in search
setopt HIST_IGNORE_ALL_DUPS      # remove older duplicate entries
setopt HIST_IGNORE_DUPS          # don't record duplicates
setopt HIST_IGNORE_SPACE         # don't record commands starting with space
setopt HIST_REDUCE_BLANKS        # remove superfluous blanks
setopt HIST_SAVE_NO_DUPS         # don't save duplicates
setopt HIST_VERIFY               # don't execute immediately on expansion
setopt INC_APPEND_HISTORY        # add commands immediately
setopt SHARE_HISTORY             # share history between sessions

# -----------------------------------------------------------------------------
# Input/Output
# -----------------------------------------------------------------------------
setopt CORRECT              # command correction
setopt NO_CORRECT_ALL       # don't correct all arguments
setopt NO_FLOW_CONTROL      # disable start/stop characters
setopt INTERACTIVE_COMMENTS # allow comments in interactive shell
setopt NO_CLOBBER           # don't overwrite files with > (use >| to force)
setopt NO_BEEP              # no beeping

# -----------------------------------------------------------------------------
# Job Control
# -----------------------------------------------------------------------------
setopt AUTO_RESUME          # resume jobs by name
setopt LONG_LIST_JOBS       # list jobs in long format
setopt NOTIFY               # report status of background jobs immediately

# -----------------------------------------------------------------------------
# Scripts & Functions
# -----------------------------------------------------------------------------
setopt MULTIOS              # write to multiple descriptors
setopt NO_BG_NICE           # don't nice background jobs
