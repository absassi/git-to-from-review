#!/bin/bash
# shellcheck disable=SC1090,SC2154

set -e

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

command-exists() {
  # which ignores previous aliases but is not portable
  # command does not ignore aliases, but is built in
  # so it's better to try to check first with which and fallback to command
  which "$1" &>/dev/null || command -v "$1" &>/dev/null
}

check-dependencies() {
  for i in "${!deps[@]}"; do
    if ! command-exists "${deps[$i]}"; then
      echo -e "- Command '${deps[$i]}' not found." 1>&2
      echo -e "\nPlease check %s" "${deps_instructions[$i]}" 1>&2
      exit 1
    else
      echo "- Command '${deps[$i]}' is available" 1>&2
    fi
  done
}

install-bats() {
  if [ -f "$bats" ]; then
    echo "- Bats is installed locally"
  else
    echo "- Installing Bats, the Automated Testing System locally..."
    git clone https://github.com/sstephenson/bats.git "$batsdir"
  fi
}

install-helpers() {
  for helper in "${helpers[@]}"; do
    if [ -f "$helpersdir/bats-$helper/load.bash" ]; then
      echo "- Helper '$helper' already installed locally"
    else
      echo "- Installing helper '$helper'..."
      git clone "https://github.com/ztombol/bats-$helper" "$helpersdir/bats-$helper"
    fi
  done
}

run-tests() {
  echo "Checking dependencies..." 1>&2
  install-bats
  install-helpers
  check-dependencies

  # Clear logs
  echo "" > "$logfile"  # clear logs

  echo -e "Running the test suite...\n" 1>&2

  $bats "$testdir"

  # Print logs
  local logs
  logs=$(cat "$logfile")
  if [ -n "$logs" ]; then
    echo -e "\nExecution logs:\n" 1>&2
    echo -e "$logs\n"
  fi
}

run-tests

# Cleanup
clear-config
unset -f clear-config
unset -f command-exists
unset -f check-dependencies
unset -f install-bats
unset -f install-helpers
unset -f load-helpers
unset -f run-tests
