#!/bin/bash

BOLD=$'\033[1m'
WHITE=$'\033[0;37m'
YELLOW=$'\033[1;33m'
GREEN=$'\033[1;32m'
NC=$'\033[0m'

function message {
  echo "${WHITE}${BOLD}$1${NC}"
}

function step {
    echo "${YELLOW}❯❯❯ ${WHITE}${BOLD}$1${NC} ${YELLOW}❮❮❮${NC}"
}

function finish {
  echo 
  echo 
  echo "✅  ${WHITE}${BOLD}Done!${NC} 🎉"
}

function title {
  echo 
  echo "⭐️  ${YELLOW}${BOLD}$1${NC} ⭐️"
  echo 
}

function menu_item {
  echo "${GREEN}$1. ${WHITE}${BOLD}$2${NC}"
}
