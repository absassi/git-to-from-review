#!/bin/bash

set -e

testdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
projdir="$(cd $testdir && cd .. && pwd)"
batsdir="$testdir/.bats"
bats="$testdir/.bats/bin/bats"
logfile="$testdir/.bats.log"

command_exists() {
  # which ignores previous aliases but is not portable
  # command does not ignore aliases, but is built in
  # so it's better to try to check first with which and fallback to command
  which "$1" &>/dev/null || command -v "$1" &>/dev/null
}

install_bats() {
  if [ -f "$bats" ]; then
    echo "Bats is already installed locally"
  else
    echo "Installing Bats, the Automated Testing System locally..."
    git clone https://github.com/sstephenson/bats.git $batsdir
  fi
}

run_tests() {
  echo "Ensure Bats..."
  install_bats

  # Clear logs
  echo "" > $logfile  # clear logs

  printf "\nRunning the test suite...\n"
  $bats $testdir

  # Print logs
  local logs=$(cat $logfile)
  if [ -n "$logs" ]; then
    printf "\n\nExecution logs:\n"
    echo "$logs"
    echo ""
  fi
}

run_tests

# Cleanup
unset testdir
unset batsdir
unset logfile
unset bats
unset -f run_tests
unset -f install_bats
unset -f command_exists
