#!/bin/bash
set -Eeuo pipefail

SHELL_PATH=$(command -v zsh)

if ! grep -qF "$SHELL_PATH" /etc/shells; then
  echo "$SHELL_PATH" | sudo tee -a /etc/shells >/dev/null
fi

sudo chsh -s "$SHELL_PATH" "$USER"
