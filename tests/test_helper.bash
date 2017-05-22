#!/bin/bash

testdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
projdir="$(cd $testdir && cd .. && pwd)"
projname="$(basename $(pwd))"
tmpbase="/tmp/$projname-tests"
logfile="$testdir/.bats.log"

log() {
  echo $1 >> $logfile
}

tmpdir=
origin=
within-repo() {
  mkdir -p $tmpbase
  origin=$(pwd)
  tmpdir=$(mktemp -d -p $tmpbase)
  cd $tmpdir
  git init
}

restore() {
  rm -rf "$tmpdir"
  cd $origin
}


# ----- Helpers taken from https://github.com/rbenv/rbenv -----

flunk() {
  if [ "$#" -eq 0 ]; then
    cat -
  else
    echo "$@"
  fi
  return 1
}

assert_equal() {
  if [ "$1" != "$2" ]; then
    { echo "actual:   $1"
      echo "expected: $2"
    } | flunk
  fi
}
