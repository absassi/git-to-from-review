#!/bin/bash
# shellcheck disable=SC1090,SC2154

echo-help() {
  echo -e "Usage: $0 [--help | --dirty]"
  echo -e "Run the test suite\n"
  echo -e "Options:"
  echo -e "\t--help\tDisplay this message"
  echo -e "\t--dirty\tDo not clear temporary directories and files"
}

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
  local test_cases logs exit_code
  test_cases=($@)

  echo "Checking dependencies..." 1>&2
  install-bats
  install-helpers
  check-dependencies

  # Clear logs
  echo "" > "$logfile"  # clear logs

  echo -e "Running the test suite...\n" 1>&2

  set +e
  [ ${#test_cases[@]} -eq 0 ] && test_cases+=($testdir)
  $bats "${test_cases[@]}"
  exit_code=$?

  # Print logs
  logs=$(cat "$logfile")
  if [ -n "$logs" ]; then
    echo -e "\n\n===============\nExecution logs:" 1>&2
    echo -e "$logs\n" 1>&2
  fi

  return $exit_code
}

run() {
  local args test_cases
  args=($@)
  test_cases=()

  set globstar
  source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

  for (( i = 0; i < ${#args[@]}; i++ )) do
    key="${args[$i]}"
    case $key in
      -h|--help)
        echo-help
        return 1
      ;;
      -d|--dirty)
        mkdir -p "$tmpbase"
        touch "$tmpbase/.leave-dirty"
      ;;
      *)
        test_cases+=($key)
      ;;
    esac
  done

  run-tests "${test_cases[@]}"
  exit_code=$?

  # Cleanup
  clear-config
  unset -f clear-config
  unset -f command-exists
  unset -f check-dependencies
  unset -f echo-help
  unset -f install-bats
  unset -f install-helpers
  unset -f load-helpers
  unset -f run-tests

  return $exit_code
}

run "$@"
