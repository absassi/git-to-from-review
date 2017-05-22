#!/bin/bash
# shellcheck disable=SC1090,SC2154

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

log() {
  echo "$1" >> "$logfile"
}

tmpdir="/tmp"
origin=$(pwd)
within-repo() {
  mkdir -p "$tmpbase"
  origin=$(pwd)
  tmpdir=$(mktemp -d -p "$tmpbase")
  # shellcheck disable=SC2164
  cd "$tmpdir"
  git init .
}

restore() {
  rm -rf "$tmpdir"
  cd "$origin" || return
  unset tmpdir
  unset origin
}

# load-helpers
for helper in "${helpers[@]}"; do
  # shellcheck disable=SC1090
  source "$helpersdir/bats-$helper/load.bash"
done
unset helper
