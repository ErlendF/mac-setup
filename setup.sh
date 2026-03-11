#!/bin/bash
set -Eeuo pipefail

trap 'echo "ERROR: Script failed on line $LINENO" >&2' ERR

MAC_SETUP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

source "$MAC_SETUP_DIR/lib/print.sh"

pause(){
	echo 
	read -rp "Press [Enter] key to continue... "
	echo
}

verify_ssh_key(){
	echo
	read -rp "Do you want to set up SSH key? (y/n): " ssh_response
	echo
	
	if [[ ! "$ssh_response" =~ ^[Yy]$ ]]; then
		step "Skipping SSH key setup"
		finish
		return 0
	fi
	
	path="$HOME/.ssh/id_ed25519.pub"
	step "Verifying ssh key in path: $path"
	if [[ ! -f "$path" ]]; then
		step "Generating SSH key"
		ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519"
		pbcopy < ~/.ssh/id_ed25519.pub
        step "Copied public key, paste it to GitHub"
        open https://github.com/settings/keys
        pause
	else
		step "ssh key already exists"
		step "skipping..."
	fi
	step "Adding the SSH key to the agent now to avoid multiple prompts"
	if ! ssh-add -L -q > /dev/null ; then
		ssh-add
	fi

	finish
}

homebrew(){
	step "Checking Homebrew"
	if ! command -v brew &>/dev/null; then
		step "Installing..."
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	fi
	step "Homebrew is installed!"

	finish
}

brew_bundle(){
	xcode-select --install || true # Install Xcode command line tools if not already installed

	step "Installing Homebrew bundle"
	brew bundle --file="$MAC_SETUP_DIR/Brewfile"

	finish
}

config_macos(){
	echo
	read -rp "Do you want to tweak macOS config settings? (y/n): " macos_response
	echo
	
	if [[ ! "$macos_response" =~ ^[Yy]$ ]]; then
		step "Skipping macOS configuration"
		finish
		return 0
	fi
	
	step "Tweaking macOS config settings (may take a while)"
	"$MAC_SETUP_DIR/lib/macos.sh"

	finish
}

install_zsh(){
	step "Installing zsh"
	brew list zsh || brew install zsh

	step "Changing shell to zsh"
	"$MAC_SETUP_DIR/lib/shell.sh"

	if [[ -d "$HOME/.oh-my-zsh" ]]; then
		step "oh my zsh already installed"
	else 
		step "Installing oh-my-zsh"
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	fi

	step "zsh setup complete!"

	finish
}

install_zsh_plugins(){
	step "Installing Custom zsh plugins"

	if [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
		step "zsh-autosuggestions already installed"
	else 
		step "installing zsh-autosuggestions"
		git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
	fi 

	if [ -d "$HOME/.oh-my-zsh/custom/plugins/fast-syntax-highlighting" ]; then
		step "fast-syntax-highlighting already installed"
	else 
		step "installing fast-syntax-highlighting"
		git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting"
	fi

	finish
}

dotfiles(){
	local ZDOTDIR="$HOME/.zsh"

	step "Backing up existing dot files to $MAC_SETUP_DIR/backup"

	mkdir -p "$MAC_SETUP_DIR/backup"
	backup_date="$(date +%Y%m%d)"

	if [[ -f "$HOME/.gitconfig" ]]; then
		cp -ivL "$HOME/.gitconfig" "$MAC_SETUP_DIR/backup/.gitconfig-$backup_date"
	else
		step "Skipping backup of ~/.gitconfig (not found)"
	fi

	if [[ -f "$ZDOTDIR/.zshrc" ]]; then
		cp -ivL "$ZDOTDIR/.zshrc" "$MAC_SETUP_DIR/backup/.zshrc-$backup_date"
	else
		step "Skipping backup of $ZDOTDIR/.zshrc (not found)"
	fi

	if [[ -f "$HOME/.zshenv" ]]; then
		cp -ivL "$HOME/.zshenv" "$MAC_SETUP_DIR/backup/.zshenv-$backup_date"
	else
		step "Skipping backup of ~/.zshenv (not found)"
	fi

	if [[ -f "$ZDOTDIR/starship.toml" ]]; then
		cp -ivL "$ZDOTDIR/starship.toml" "$MAC_SETUP_DIR/backup/starship-$backup_date.toml"
	else
		step "Skipping backup of $ZDOTDIR/starship.toml (not found)"
	fi

	if [[ -f "$HOME/.config/atuin/config.toml" ]]; then
		cp -ivL "$HOME/.config/atuin/config.toml" "$MAC_SETUP_DIR/backup/atuin-config-$backup_date.toml"
	else
		step "Skipping backup of ~/.config/atuin/config.toml (not found)"
	fi

	step "Copying dot files"
	cp -vL "$MAC_SETUP_DIR/lib/dotfiles/.gitconfig" ~/.gitconfig

	mkdir -p "$ZDOTDIR"
	cp -vL "$MAC_SETUP_DIR/lib/dotfiles/.zshenv" ~/.zshenv
	cp -vL "$MAC_SETUP_DIR/lib/dotfiles/zsh/.zshrc" "$ZDOTDIR/.zshrc"
	cp -vL "$MAC_SETUP_DIR/lib/dotfiles/zsh/starship.toml" "$ZDOTDIR/starship.toml"

	mkdir -p "$HOME/.config/atuin"
	cp -vL "$MAC_SETUP_DIR/lib/dotfiles/atuin/config.toml" ~/.config/atuin/config.toml

	touch "$ZDOTDIR/.zshlocal"

	step "Remove backups with 'rm -ir $MAC_SETUP_DIR/backup'"

	finish
}

config_git_identity(){
	step "Setting up git name"
	if [[ -z "$(git config user.name)" ]]; then
		printf "Insert git name: "
		read -r git_name
		git config --global user.name "${git_name}"
	fi

	step "Setting up git email"
	if [[ -z "$(git config user.email)" ]]; then
		printf "Insert git email: "
		read -r git_email
		git config --global user.email "${git_email}"
	fi

	finish
}

config_azure_cli(){
	step "Configuring Azure CLI settings"

	if command -v brew >/dev/null 2>&1 && [[ -x "$(brew --prefix 2>/dev/null)/bin/az" ]]; then
		"$(brew --prefix)/bin/az" config set core.login_experience_v2=off
		"$(brew --prefix)/bin/az" config set core.collect_telemetry=no
	elif command -v az >/dev/null 2>&1; then
		az config set core.login_experience_v2=off
		az config set core.collect_telemetry=no
	else
		step "Azure CLI not found; skipping"
	fi

	finish
}

set_zsh_profile(){
	step "Set zsh profile"

	cp "$MAC_SETUP_DIR/iterm2/Profiles.json" "$HOME/Library/Application Support/iTerm2/DynamicProfiles"

	step "Removing conflicting key bindings from iTerm2 preferences"
	plist_file="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
	
	# Key codes to remove: ⌥←, ⌥→, ⌘←, ⌘→, ⌘←Delete, ⌥←Delete
	keys_to_remove=(
		"0xf702-0x280000"    # Option+Left
		"0xf703-0x280000"    # Option+Right
		"0xf702-0x100000"    # Command+Left
		"0xf703-0x100000"    # Command+Right
		"0x7f-0x100000"      # Command+Delete
		"0x7f-0x80000"       # Option+Delete
	)
	
	# Remove from GlobalKeyMap if it exists
	for key in "${keys_to_remove[@]}"; do
		/usr/libexec/PlistBuddy -c "Delete :GlobalKeyMap:$key" "$plist_file" 2>/dev/null || true
	done
	
	step "Setting Default profile as default"
	# Set the profile GUID as the default
	defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "A1B9ACAC-3A26-4F37-9720-AAEADC587A1A"
	
	step "Profile setup complete. Restart iTerm2 for changes to take effect."
	finish
}

config_vscode(){
	step "Configuring VS Code settings"
	
	vscode_settings_dir="$HOME/Library/Application Support/Code/User"
	vscode_settings_file="$vscode_settings_dir/settings.json"
	
	# Create VS Code settings directory if it doesn't exist
	mkdir -p "$vscode_settings_dir"
	
	if [[ -f "$vscode_settings_file" ]]; then
		echo
		echo "VS Code settings file already exists."
		read -rp "Do you want to replace it with the new configuration? (y/n): " replace_response
		echo
		
		if [[ "$replace_response" =~ ^[Yy]$ ]]; then
			step "Backing up existing VS Code settings to $MAC_SETUP_DIR/backup/vscode-settings.json.old"
			cp "$vscode_settings_file" "$MAC_SETUP_DIR/backup/vscode-settings.json.old"
			
			step "Replacing VS Code settings"
			cp "$MAC_SETUP_DIR/lib/vscode-settings.json" "$vscode_settings_file"
			step "VS Code configuration complete!"
		else
			step "Skipping VS Code configuration"
			step "You can manually copy settings from: $MAC_SETUP_DIR/lib/vscode-settings.json"
		fi
	else
		step "Creating new VS Code settings file"
		cp "$MAC_SETUP_DIR/lib/vscode-settings.json" "$vscode_settings_file"
		step "VS Code configuration complete!"
	fi
	
	step "Restart VS Code to see the changes"
	
	finish
}

install_vscode_extensions(){
	step "Installing VS Code extensions"
	
	# Check if code command is available
	if ! command -v code &> /dev/null; then
		step "VS Code command line tools not found!"
		step "Please install by opening VS Code and running: Shell Command: Install 'code' command in PATH"
		finish
		return 1
	fi
	
	# List of extensions to install
	extensions=(
		"davidanson.vscode-markdownlint"
		"eamodio.gitlens"
		"github.copilot"
		"github.copilot-chat"
		"github.vscode-github-actions"
		"github.vscode-pull-request-github"
		"golang.go"
		"hashicorp.terraform"
		"johnpapa.vscode-peacock"
		"kcl.kcl-vscode-extension"
		"ms-azuretools.vscode-azureterraform"
		"ms-azuretools.vscode-containers"
		"ms-kubernetes-tools.vscode-kubernetes-tools"
		"ms-python.debugpy"
		"ms-python.python"
		"ms-python.vscode-pylance"
		"ms-python.vscode-python-envs"
		"ms-vscode-remote.remote-containers"
		"ms-vscode.makefile-tools"
		"redhat.vscode-yaml"
		"tamasfe.even-better-toml"
		"usernamehw.errorlens"
	)
	
	for extension in "${extensions[@]}"; do
		step "Installing $extension"
		code --install-extension "$extension" --force
	done
	
	step "All VS Code extensions installed!"
	
	finish
}

# Tasks to run, in order. Each entry is "name:description".
# This array serves as the single source of truth for:
# - the allowlist for selective runs (./setup.sh <task>)
# - the execution order for full runs (./setup.sh)
# - the help text (./setup.sh help)
tasks=(
	"verify_ssh_key:Generate and configure SSH key for GitHub"
	"homebrew:Install the Homebrew package manager"
	"brew_bundle:Install packages from Brewfile"
	"install_zsh:Install zsh and oh-my-zsh"
	"config_macos:Tweak macOS system preferences"
	"install_zsh_plugins:Install zsh-autosuggestions and fast-syntax-highlighting"
	"dotfiles:Back up and install dotfiles (.gitconfig, .zshrc, etc.)"
	"config_git_identity:Set git user name and email"
	"config_azure_cli:Disable Azure CLI telemetry and configure login"
	"set_zsh_profile:Configure iTerm2 profile and key bindings"
	"config_vscode:Install VS Code settings"
	"install_vscode_extensions:Install VS Code extensions"
)

# Extract just the task name from a "name:description" entry.
task_name() { echo "${1%%:*}"; }

# Print available tasks with descriptions.
list_tasks() {
	echo "Usage: ./setup.sh [task]"
	echo
	echo "Available tasks:"
	for entry in "${tasks[@]}"; do
		printf "  %-28s %s\n" "${entry%%:*}" "${entry#*:}"
	done
}

# If "help" or "--help" is passed, show available tasks.
# If a task name is provided, validate and run only that task.
# Otherwise, run all tasks in order.
if [[ "${1:-}" == "help" || "${1:-}" == "--help" ]]; then
	list_tasks
	exit 0
elif [[ -n "${1:-}" ]]; then
	for entry in "${tasks[@]}"; do
		if [[ "$(task_name "$entry")" == "$1" ]]; then
			"$1"
			exit 0
		fi
	done
	echo "Unknown task: $1"
	echo
	list_tasks
	exit 1
else
	for entry in "${tasks[@]}"; do
		"$(task_name "$entry")"
	done
fi
