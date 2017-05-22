#!/bin/bash
# shellcheck disable=SC2034

testdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
projdir="$(cd "$testdir" && cd .. && pwd)"
projname="$(basename "$projdir")"

batsdir="$testdir/.bats"
bats="$testdir/.bats/bin/bats"

tmpbase="/tmp/$projname-tests"
logfile="$testdir/.bats.log"

deps=(jq)
deps_instructions=(https://stedolan.github.io/jq/download/)

helpersdir="$testdir/.helper-libs"
helpers=(support assert file)

clear-config() {
  unset testdir
  unset batsdir
  unset helpersdir
  unset bats
  unset logfile
  unset deps
  unset deps_instructions
  unset helpers
}
