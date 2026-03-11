##
# oh-my-zsh
##
export ZSH="$HOME/.oh-my-zsh"
export DISABLE_MAGIC_FUNCTIONS=true  # Disable url-quote-magic and bracketed-paste-magic (fixes slow pasting)

ZSH_DISABLE_COMPFIX=true             # Skip insecure directory check on startup (avoids Homebrew false positives)
zstyle ':omz:update' mode auto       # Auto-update oh-my-zsh without prompting
zstyle ':omz:update' frequency 7     # Check for updates weekly

##
# Plugins
##
plugins=(
  colored-man-pages
  docker
  extract
  fast-syntax-highlighting
  fzf
  git
  kubectl
  zsh-autosuggestions
  zsh-interactive-cd
)

source "$ZSH/oh-my-zsh.sh"

##
# Completion
##
zmodload -i zsh/complist
setopt hash_list_all            # Rehash command table before completing (finds newly installed commands)
setopt always_to_end            # Move cursor to end of word after completion
setopt complete_in_word         # Allow completing from the middle of a word
setopt correct                  # Suggest corrections for mistyped commands
setopt list_ambiguous           # Insert common prefix before showing completion menu

# Case-insensitive completion, partial matching at . _ - boundaries
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
# Interactive menu on >1 match; try exact, then ignored, then approximate matches
zstyle ':completion:*' menu select=1 _complete _ignored _approximate
# Allow stacking single-char flags for docker (e.g. -it instead of -i -t)
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes

##
# Pushd
##
setopt auto_pushd               # cd pushes old directory onto the stack automatically
setopt pushd_ignore_dups        # Don't push duplicate directories onto the stack
setopt pushd_silent             # Don't print the stack after pushd/popd
setopt pushd_to_home            # pushd with no args goes to $HOME (like cd)

##
# History
# Note: Ctrl+R uses atuin (separate database). These options affect up/down arrow
# and bang expansion (!! !$ etc.) which still use zsh's native HISTFILE.
##
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt append_history           # Append to history file, don't overwrite
setopt hist_ignore_all_dups     # Remove older duplicate when adding a new entry
setopt hist_ignore_space        # Don't record commands starting with a space
setopt hist_reduce_blanks       # Trim unnecessary whitespace before saving
setopt hist_verify              # Show expanded history command in buffer before executing
setopt inc_append_history       # Write to history immediately, not on shell exit
setopt share_history            # Share history across all open shells in real time
setopt bang_hist                # Enable ! history expansion (!! !$ !grep etc.)

##
# Shell Behavior
##
setopt auto_cd                  # Type a directory path to cd into it
setopt auto_remove_slash        # Remove trailing slash when next char indicates it's not needed
setopt chase_links              # Resolve symlinks to physical paths on cd
setopt extended_glob            # Enable extended globbing (^ ~ # operators in patterns)
setopt glob_dots                # Globs match dotfiles without an explicit leading dot
setopt print_exit_value         # Print non-zero exit codes (e.g. "zsh: exit 1")
unsetopt beep                   # Disable terminal bell on error
unsetopt bg_nice                # Don't lower priority of background jobs
unsetopt clobber                # Require >| to overwrite files and >>| to create via append
unsetopt hist_beep              # Disable bell when scrolling past history bounds
unsetopt hup                    # Don't send SIGHUP to background jobs on shell exit
unsetopt ignore_eof             # Allow Ctrl+D to exit the shell
unsetopt list_beep              # Disable bell on ambiguous completion
unsetopt rm_star_silent         # Prompt for confirmation on rm * or rm path/*
unsetopt prompt_cr prompt_sp    # Disable the % marker for partial lines without trailing newline
print -Pn "\e]0; %n@%M: %~\a"  # Set terminal title to user@host: ~/path

##
# Machine-Specific Settings
##
[[ -f "$ZDOTDIR/.zshlocal" ]] && source "$ZDOTDIR/.zshlocal"

##
# Aliases
##

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias -- -="cd -"

# General utilities
alias sudo='sudo '                                                                      # Trailing space: expand aliases after sudo
alias chrome='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome'
alias c="tr -d '\n' | pbcopy"                                                           # Copy stdin to clipboard, stripping newlines
alias reload="exec ${SHELL} -l"                                                         # Replace shell with a fresh login shell
alias path='echo -e ${PATH//:/\\n}'                                                     # Print each PATH entry on its own line
alias watch='watch '                                                                    # Trailing space: expand aliases after watch
alias l='eza -lah --git --icons=auto --git-repos-no-status --group-directories-first'
alias myip="curl ipv4.icanhazip.com"

# Kubernetes
alias kw='kubectl config current-context'  # Show current context
alias kx='kubectx'                         # Switch context
alias kn='kubens'                          # Switch namespace

# AWS
alias awsp='export AWS_PROFILE=$(aws configure list-profiles | gum filter --placeholder "Select AWS profile")'
alias awswho='aws sts get-caller-identity --no-cli-pager'

# Azure
alias al='az login --output none'
alias aw='az account show --output json | jq -r "\"\u001b[94m\" + .name + \"\u001b[0m - \u001b[33m\" + .tenantDefaultDomain + \"\u001b[0m (\" + .user.name + \")\""'

# Typo corrections
alias gti='git'
alias cod='code'

##
# Exports
##
export KUBE_EDITOR="nano"
export PATH="/opt/homebrew/bin:$PATH"
export STARSHIP_CONFIG="$ZDOTDIR/starship.toml"

##
# Tool Initialization
##
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Prompt
eval "$(starship init zsh)"

# Shell history search (Ctrl+R)
eval "$(atuin init zsh --disable-up-arrow)"

# Smart cd replacement - lazy-loaded since z/zi are the only entry points
_init_zoxide() {
  unfunction z zi _init_zoxide 2>/dev/null
  eval "$(command zoxide init zsh)"
}
z()  { _init_zoxide; z "$@"; }
zi() { _init_zoxide; zi "$@"; }

# Dev tool version manager - must run at startup to put shims in PATH
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# Auto-load .envrc files on cd
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# Tool completions
if command -v crossplane >/dev/null 2>&1; then
  source <(crossplane completions)
fi

# VS Code shell integration (only inside VS Code terminals)
[[ "$TERM_PROGRAM" == "vscode" ]] && {
  _vscode_zsh="$(code --locate-shell-integration-path zsh 2>/dev/null)" && . "$_vscode_zsh"
  unset _vscode_zsh
}

##
# Functions
##

# Interactively pick an Azure subscription and switch to it
as() {
  local -A acct
  local name id

  while IFS=$'\t' read -r name id; do
    acct[$name]=$id
  done < <(az account list --query "[].[name,id]" -o tsv) || return

  name=$(printf '%s\n' "${(@k)acct}" | gum filter --placeholder "Select Azure subscription") || return
  echo -e "Setting Azure subscription to \e[33m${name}\e[0m"
  az account set --subscription "${acct[$name]}"
}

# Log a command and its output to a file, while also printing to stdout
lc() {
  local file="$1"; shift
  echo "=== $* ===" | tee -a "$file"
  "$@" 2>&1 | tee -a "$file"
  echo "" >> "$file"
}
