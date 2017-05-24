#!/bin/bash
# shellcheck disable=SC1090,SC2154,SC2164

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

log() {
  echo "$1" >> "$logfile"
}

origin=$(pwd)
tmpdir="/tmp"
within-tmpdir() {
  mkdir -p "$tmpbase"
  origin=$(pwd)
  tmpdir=$(mktemp -d -p "$tmpbase")
  cd "$tmpdir"
  echo "$tmpdir"
}

installdir=""
with-installation() {
  installdir="$(within-tmpdir)"
  run make install builddir="$installdir" prefix="$installdir"
  export PATH="$PATH:$installdir/bin"
}

repodir=""
within-repo() {
  repodir=$(within-tmpdir)
  cd "$repodir"
  git init . 1>&2
  echo "$repodir"
}

with-n-reviewers() {
  for (( i = 1; i <= $1; i++ )); do
    git config --add --local "reviewers.u$i" "u$i@e$i"
  done
}

within-repo-with-commit() {
  repodir="$(within-repo)"
  cd "$repodir"
  tmpfile=$(mktemp -p "$repodir")
  echo "$tempfile" > "$tmpfile"
  git add "$tmpfile" 1>&2
  git commit -m "Message" 1>&2
  echo "$repodir"
}

restore() {
  [ ! -f "$tmpbase/.leave-dirty" ] && rm -rf "$tmpbase"
  cd "$origin" || true
  unset origin tmpdir repodir installdir
}

# load-helpers
for helper in "${helpers[@]}"; do
  # shellcheck disable=SC1090
  source "$helpersdir/bats-$helper/load.bash"
done
unset helper
