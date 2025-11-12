#!/bin/sh

MAC_SETUP_DIR="${0%/*}"

source $MAC_SETUP_DIR/lib/print.sh

pause(){
	echo 
	read -p "Press [Enter] key to continue... " fackEnterKey
	echo
}

verify_ssh_key(){
	echo
	read -p "Do you want to set up SSH key? (y/n): " ssh_response
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
		cat ~/.ssh/id_ed25519.pub | pbcopy
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
	if ! type brew > /dev/null; then
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
	read -p "Do you want to tweak macOS config settings? (y/n): " macos_response
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
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
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
		git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
	fi

	finish
}

dotfiles(){
	step "Backing up existing dot files to $MAC_SETUP_DIR/backup"

	mkdir -p $MAC_SETUP_DIR/backup
	cp -ivL ~/.gitconfig $MAC_SETUP_DIR/backup/.gitconfig.old
	cp -ivL ~/.zsh/.zshrc $MAC_SETUP_DIR/backup/.zshrc.old
	cp -ivL ~/.zsh/.zshenv $MAC_SETUP_DIR/backup/.zshenv.old
	cp -ivL ~/.zsh/starship.toml $MAC_SETUP_DIR/backup/starship.toml.old

	step "Copying dot files"
	cp -ivL $MAC_SETUP_DIR/lib/dotfiles/.gitconfig ~/.gitconfig

	mkdir -p $HOME/.zsh
	cp -ivL $MAC_SETUP_DIR/lib/dotfiles/.zshenv ~/.zshenv
	cp -ivL $MAC_SETUP_DIR/lib/dotfiles/zsh/.zshrc ~/.zsh/.zshrc
	cp -ivL $MAC_SETUP_DIR/lib/dotfiles/zsh/.zshenv ~/.zsh/.zshenv
	cp -ivL $MAC_SETUP_DIR/lib/dotfiles/zsh/starship.toml ~/.zsh/starship.toml

	touch ~/.zsh/.zshlocal

	step "Setting up git name"
	if [[ -z "$(git config user.name)" ]]; then
		printf "Insert git name: "
		read git_name
		git config --global user.name "${git_name}"
	fi

	step "Setting up git email"
	if [[ -z "$(git config user.email)" ]]; then
		printf "Insert git email: "
		read git_email
		git config --global user.email "${git_email}"
	fi

	step "Remove backups with 'rm -ir $MAC_SETUP_DIR/backup.*.old'"

	finish
}

set_zsh_profile(){
    step "Set zsh profile"

    cp $MAC_SETUP_DIR/iterm2/Profiles.json $HOME/Library/Application\ Support/iTerm2/DynamicProfiles

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
		read -p "Do you want to replace it with the new configuration? (y/n): " replace_response
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

verify_ssh_key
homebrew
brew_bundle
install_zsh
config_macos
install_zsh_plugins
dotfiles
set_zsh_profile
config_vscode
install_vscode_extensions
