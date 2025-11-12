# Mac Setup

Automated macOS environment setup script for developers. This script configures a fresh Mac with (opinionated) sensible defaults, development tools, and a customized shell environment.

## What This Script Sets Up

The setup script can automatically configure the following components:

### Core Components (Always Installed)

- **Homebrew**: Package manager for macOS
- **Zsh**: Modern shell with Oh My Zsh framework
- **Shell Configuration**: Customized zsh environment using `~/.zsh/` folder structure

### Development Tools (via Homebrew)

The `Brewfile` installs essential development tools and applications:

- **Languages & Runtimes**: Go, Python, Node.js, GCC
- **CLI Tools**: git, tmux, fzf, jq, ripgrep, bat, eza, delta, gh, kubectl, k9s, awscli, terraform (tfenv), stern, atuin, zoxide, dive, starship
- **GUI Applications**: Visual Studio Code, iTerm2, Docker, Firefox, Chrome, Slack, Signal, Spotify, Bitwarden, Rectangle, Contexts
- **Fonts**: Bitstream Vera Sans Mono Nerd Font

### Optional Components (Interactive Prompts)

During setup, you'll be asked whether to configure:

- **SSH Key** *(optional)*: Generate and copy ED25519 SSH key to clipboard for GitHub
- **macOS Settings** *(optional)*: Apply opinionated system preferences (Finder, Dock, trackpad, etc.)
- **VS Code Settings** *(optional)*: Install VS Code configuration and extensions
- **iTerm2 Profile** *(configurable)*: Install custom iTerm2 profile with key bindings

## How It Works

### Zsh Configuration Structure

The setup uses a clean `~/.zsh/` directory structure to organize shell configuration:

```text
~/.zsh/
├── .zshrc           # Main zsh configuration file
├── .zshenv          # Environment variables (sourced first)
├── .zshlocal        # Machine-specific settings (git-ignored, safe for secrets)
├── .zsh_history     # Command history
└── starship.toml    # Starship prompt configuration
```

**Why `~/.zsh/`?**

- Keeps your home directory clean
- Organizes all zsh-related files in one place
- Makes it easy to backup or version control your shell config

### Configuration Loading Order

1. `~/.zshenv` (in home directory) - Sets `ZDOTDIR=$HOME/.zsh`
2. `~/.zsh/.zshlocal` - Environment variables
3. `~/.zsh/.zshrc` - Interactive shell configuration, plugins, aliases

### Shell Features Included

The provided `.zshrc` includes:

- **Oh My Zsh** framework with auto-updates
- **Plugins**: git, docker, kubectl, fzf, zsh-autosuggestions, fast-syntax-highlighting, colored-man-pages, and more
- **Starship prompt** for a beautiful, fast prompt
- **Smart completion**: Case-insensitive with menu selection
- **Command history**: Shared across sessions, no duplicates
- **Modern CLI aliases**: `l` (eza), `cat` (bat), `grep` (ripgrep)
- **Lazy-loaded tools**: atuin, zoxide, mise for faster shell startup

## Installation

```sh
git clone https://github.com/ErlendF/mac-setup.git && \
cd mac-setup && \
./setup.sh
```

The script will guide you through the setup process with interactive prompts for optional components.

## Important Notes

### Machine-Specific Configuration

**Use `~/.zsh/.zshlocal` for local customization:**

- This file is intended to keep changes specific to a local machine as to not require updating the zshrc file too often

Example `~/.zsh/.zshlocal`:

```bash
# Work-specific aliases
export WORK_PROJECT_DIR="$HOME/work/projects"
alias cdwork="cd $WORK_PROJECT_DIR"

# Custom environment variables
export AWS_PROFILE="my-profile"

# Machine-specific paths
export PATH="/opt/custom/bin:$PATH"
```

### Customizing Your Setup

- **Modify `Brewfile`**: Add/remove applications before running the setup
- **Edit `lib/dotfiles/`**: Customize dotfiles to your preferences before installation
- **Adjust `lib/macos.sh`**: Modify system preferences to your liking (only runs if you opt-in)
- **VS Code extensions**: Edit the extensions list in `setup.sh` before installation

### Backups

The script automatically backs up existing configuration files to `backup/` before overwriting:

- `.gitconfig`
- `.zshrc` and related zsh files
- `starship.toml`
- VS Code settings (if replacing)

Remove backups with: `rm -ir backup/*.old`

### Post-Installation

1. **Restart iTerm2** if you installed the custom profile
2. **Restart VS Code** if you configured settings/extensions
3. **Source your shell**: Run `reload` alias or restart your terminal
4. Some macOS settings require a logout/restart to take full effect

### Prerequisites

- macOS (tested on recent versions)
- Internet connection (for downloading packages)
- Admin/sudo access (required for some installations)

## Customization Tips

### Adding More Brew Packages

Edit `Brewfile` and add packages before running setup:

```ruby
brew "package-name"
cask "application-name"
```

### Extending Zsh Configuration

For personal additions that you want version controlled, edit `lib/dotfiles/zsh/.zshrc` directly. For temporary or machine-specific changes, use `~/.zsh/.zshlocal`.

### Skipping Components

The script is modular. You can comment out function calls at the bottom of `setup.sh` to skip specific components:

```bash
# verify_ssh_key
# homebrew
# brew_bundle
# ...
```

## Troubleshooting

- **Homebrew issues**: Ensure you have Command Line Tools: `xcode-select --install`
- **Permission errors**: Some operations require sudo access
- **Shell not changing**: Log out and back in after zsh installation
- **VS Code 'code' command not found**: Open VS Code and run: `Shell Command: Install 'code' command in PATH`

## Attribution

Based on [Sergio's setup](https://github.com/sergiomss/mac-setup)
