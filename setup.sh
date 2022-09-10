#!/bin/sh

MAC_SETUP_DIR="$HOME/projects/mac-setup"
source $MAC_SETUP_DIR/lib/print.sh

pause(){
	echo 
	read -p "Press [Enter] key to continue... " fackEnterKey
	echo
}

verify_ssh_key(){
	path="$HOME/.ssh/id_ed25519.pub"
	step "Verifying ssh key in path: $path"
	if [ ! -f "$path" ]; then
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
	/usr/bin/ruby -e \
		"$(curl \
		-fsSL \
		https://raw.githubusercontent.com/Homebrew/install/master/install)"
	fi
	step "Homebrew is installed!"

	finish
}

brew_bundle(){
	step "Installing Homebrew bundle"
	brew bundle --file="$MAC_SETUP_DIR/Brewfile"

	finish
}

config_macos(){
	step "Tweaking macOS config settings (may take a while)"
	"$MAC_SETUP_DIR/lib/macos.sh"

	finish
}

install_zsh(){
	step "Installing zsh"
	brew list zsh || brew install zsh

	step "Changing shell to zsh"
	"$MAC_SETUP_DIR/lib/shell.sh"

	step "Installing oh-my-zsh"
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

	step "zsh setup complete!"

	finish
}

config_macos(){
	step "Tweaking macOS config settings (may take a while)"
	"$MAC_SETUP_DIR/lib/macos.sh"

	finish
}

install_zsh_plugins(){
	step "Installing Custom zsh plugins"

	if [[ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
		step "powerlevel10k already installed"
	else 
		step "installing powerlevel10k zsh custom theme" 
		git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
	fi 

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
		git clone https://github.com/zdharma/fast-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/fast-syntax-highlighting
	fi 

	if [ -d "$HOME/.oh-my-zsh/custom/plugins/alias-tips" ]; then
		step "alias-tips already installed"
	else 
		step "installing alias-tips" 
		git clone https://github.com/djui/alias-tips.git ~/.oh-my-zsh/custom/plugins/alias-tips
	fi

	finish
}

dotfiles(){
	step "Backing up existing dot files"
	mkdir -p $MAC_SETUP_DIR/backup
	cp -ivL ~/.gitconfig $MAC_SETUP_DIR/backup/.gitconfig.old
	cp -ivL ~/.zsh/.p10k.zsh $MAC_SETUP_DIR/backup/.p10k.zsh.old
	cp -ivL ~/.zsh/.zshrc $MAC_SETUP_DIR/backup/.zshrc.old
	cp -ivL ~/.zsh/.zshenv $MAC_SETUP_DIR/backup/.zshenv.old

	step "Adding symlinks to dot files"
	cp -ivL $MAC_SETUP_DIR/lib/dotfiles/.gitconfig ~/.gitconfig
	mkdir -p $HOME/.zsh
	ln -sfnv $MAC_SETUP_DIR/lib/dotfiles/.zshenv ~/.zshenv
	ln -sfnv $MAC_SETUP_DIR/lib/dotfiles/zsh/.p10k.zsh ~/.zsh/.p10k.zsh
	ln -sfnv $MAC_SETUP_DIR/lib/dotfiles/zsh/.zshrc ~/.zsh/.zshrc
	ln -sfnv $MAC_SETUP_DIR/lib/dotfiles/zsh/.zshenv ~/.zsh/.zshenv

	step "Setting up git email"
	if [ -z "$(git config user.email)" ]; then
	printf "Insert git email: "
	read git_email
	git config --global user.email "${git_email}"
	fi

	step "Remove backups with 'rm -ir $MAC_SETUP_DIR/backup.*.old'"

	finish
}

set_zsh_profile(){
    step "Set zsh profile"

    cp $MAC_SETUP_DIR/mac-profile.json $HOME/Library/Application\ Support/iTerm2/DynamicProfiles

    printf "Remove: \n- ⌥←\n- ⌥→\n- ⌘←\n- ⌘←\n- ⌘←Delete\n- ⌥←Delete\nIn:\n"
    printf "- Iterm2 > Preferences > Keys > Key Bindings"
    printf "- Iterm2 > Preferences > Keys > Profiles > Default > Keys"
    pause
}

verify_ssh_key
homebrew
brew_bundle
install_zsh
iterm2
config_macos
install_zsh_plugins
dotfiles
