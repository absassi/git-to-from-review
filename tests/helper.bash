#!/bin/bash
# shellcheck disable=SC1090,SC2154

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

log() {
  echo "$1" >> "$logfile"
}

tmpdir="/tmp"
origin=$(pwd)
within-tmpdir() {
  mkdir -p "$tmpbase"
  origin=$(pwd)
  tmpdir=$(mktemp -d -p "$tmpbase")
  # shellcheck disable=SC2164
  cd "$tmpdir"
}

within-repo() {
  within-tmpdir
  git init .
}

restore() {
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
