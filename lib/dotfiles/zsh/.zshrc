##
# oh-my-zsh
##
export ZSH="$HOME/.oh-my-zsh"
export TERM="xterm-256color"

ZSH_DISABLE_COMPFIX=true             # Skip security audit
zstyle ':omz:update' mode auto       # Automatically update without asking
zstyle ':omz:update' frequency 7     # Update once a week (7 days)

##
# Fast paste
##
# Increase the chunk size for bracketed paste to make pasting instant
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic
}

pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

# Disable the bracketed paste mode delay
BRACKETED_PASTE_MAGIC_DELAY=0.01

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

##
# Completion
##
autoload -Uz compinit
# Speed up compinit by only checking once a day
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# kubectl completion for resource names
if command -v kubectl &> /dev/null; then
  source <(kubectl completion zsh)
fi

zmodload -i zsh/complist
setopt hash_list_all            # hash everything before completion
setopt always_to_end            # when completing from the middle of a word, move the cursor to the end of the word
setopt complete_in_word         # allow completion from within a word/phrase
setopt correct                  # spelling correction for commands
setopt list_ambiguous           # complete as much of a completion until it gets ambiguous.

# sections completion !
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*' # case insensitive completion
zstyle ':completion:*' menu select=1 _complete _ignored _approximate # enable completion menu
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes

##
# Pushd
##
setopt auto_pushd               # make cd push old dir in dir stack
setopt pushd_ignore_dups        # no duplicates in dir stack
setopt pushd_silent             # no dir stack after pushd or popd
setopt pushd_to_home            # `pushd` = `pushd $HOME`

##
# History
##
HISTFILE=~/.zsh/.zsh_history    # where to store zsh config
HISTSIZE=1024                   # big history
SAVEHIST=1024                   # big history
setopt append_history           # append
setopt hist_ignore_all_dups     # no duplicate
unsetopt hist_ignore_space      # ignore space prefixed commands
setopt hist_reduce_blanks       # trim blanks
setopt hist_verify              # show before executing history commands
setopt inc_append_history       # add commands as they are typed, don't wait until shell exit
setopt share_history            # share hist between sessions
setopt bang_hist                # !keyword

##
# Various
##
setopt auto_cd                  # if command is a path, cd into it
setopt auto_remove_slash        # self explicit
setopt chase_links              # resolve symlinks
setopt correct                  # try to correct spelling of commands
setopt extended_glob            # activate complex pattern globbing
setopt glob_dots                # include dotfiles in globbing
setopt print_exit_value         # print return value if non-zero
unsetopt beep                   # no bell on error
unsetopt bg_nice                # no lower prio for background jobs
unsetopt clobber                # must use >| to truncate existing files
unsetopt hist_beep              # no bell on error in history
unsetopt hup                    # no hup signal at shell exit
unsetopt ignore_eof             # do not exit on end-of-file
unsetopt list_beep              # no bell on ambiguous completion
unsetopt rm_star_silent         # ask for confirmation for `rm *' or `rm path/*'
unsetopt prompt_cr prompt_sp    # disable % at the end of the line
print -Pn "\e]0; %n@%M: %~\a"   # terminal title

source $ZSH/oh-my-zsh.sh

##
# Extra Settings
##
[[ -f $ZDOTDIR/.zshlocal ]] && source $ZDOTDIR/.zshlocal  # For machine specific settings

##
# Aliases
##

# Easier navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias -- -="cd -"

alias sudo='sudo '                                                                      # Enable aliases to be sudo’ed
alias chrome='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome'           # Google Chrome
alias c="tr -d '\n' | pbcopy"                                                           # Trim new lines and copy to clipboard
alias reload="exec ${SHELL} -l"                                                         # Reload the shell (i.e. invoke as a login shell)
alias path='echo -e ${PATH//:/\\n}'                                                     # Print each PATH entry on a separate line
alias watch='watch '                                                                    # Make aliases work with 'watch'
alias l='eza -lah --git --icons=auto --git-repos-no-status --group-directories-first'   # Set useful eza options
alias cat='bat'                                                                         # Replace cat with bat
alias grep='rg'                                                                         # Replace grep with ripgrep
alias myip="curl ipv4.icanhazip.com"                                                    # Utility for checking IP address

alias kw='kubectl config current-context'                                               # Show current kubectl context
alias kx='kubectx'                                                                      # Switch kubectl context               
alias kn='kubens'                                                                       # Switch kubectl namespace  

# Prompt for an AWS profile and export the selection
alias awsp='export AWS_PROFILE=$(aws configure list-profiles | gum filter --placeholder "Select AWS profile")'
# Show the current AWS caller identity information
alias awswho='aws sts get-caller-identity --no-cli-pager'

# Authenticate with Azure CLI without subscription prompts
alias al='az login --output none'
# Pick an Azure subscription interactively and switch to it
alias as='az account list --query "[].name" -o tsv | gum filter --placeholder "Select Azure subscription" | xargs -I{} az account set --subscription "{}"'
# Show current Azure account details with colored output
alias aw='az account show --output json | jq -r "\"\u001b[94m\" + .name + \"\u001b[0m - \u001b[33m\" + .tenantDefaultDomain + \"\u001b[0m (\" + .user.name + \")\""'

# Typos
alias gti='git'
alias cod='code'

##
# Other
##
export DISABLE_MAGIC_FUNCTIONS=true

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

export KUBE_EDITOR="nano" # Setting kube editor to nano
export PATH="/opt/homebrew/bin:$PATH" # Adding homebrew to path

# Tool initializations - lazy loaded for faster startup
# These will initialize on first use rather than at startup
export STARSHIP_CONFIG="$ZDOTDIR/starship.toml"

# Initialize starship immediately (needed for prompt)
eval "$(starship init zsh)"

# Lazy-load atuin - only initialize when first needed
atuin() {
  unfunction atuin
  eval "$(command atuin init zsh --disable-up-arrow)"
  atuin "$@"
}

# Lazy-load zoxide - only initialize when first needed
z() {
  unfunction z
  eval "$(command zoxide init zsh)"
  z "$@"
}

zi() {
  unfunction zi
  eval "$(command zoxide init zsh)"
  zi "$@"
}

# Lazy-load mise - only initialize when first needed
mise() {
  unfunction mise
  eval "$(command mise activate zsh)"
  mise "$@"
}

# Initialize direnv hook (lightweight, but can be lazy-loaded if needed)
eval "$(direnv hook zsh)"
