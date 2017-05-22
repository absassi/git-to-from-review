#!/bin/bash

uniqfy() {
  # Make identifiers in a comma|newline separated list unique
  #
  # Returns a comma separated list
  sed "s/,/\n/g" | sort | uniq | paste -sd "," -
}

find-reviewer-email() {
  # Retrieve the email associated with a reviewer alias
  #
  # Argument: reviewer alias
  # Returns: email address for reviewer
  local exit_code

  git config --get "reviewers.$1" 2>/dev/null
  exit_code=$?

  if [ $exit_code -ne 0 ]; then
    echo "Undefined reviewer $1" 1>&2
    return $exit_code
  fi
}

expand-group() {
  # Retrieve all the reviewers stored in a group
  #
  # Argument: group name
  # Returns: list of reviewer aliases, separated by ',' (comma)

  # Since it is a multivar, multiple lines can be returned, so let's join them
  git config --get-all "reviewers.groups.$1" 2>/dev/null | uniqfy
}

expand-list() {
  # Given a comma separated list, expand all the groups inside it
  #
  # Argument: comma separated list of reviewers or groups
  # Returns: list of reviewer aliases, separated by ',' (comma)

  # Set up the accumulator
  local reviewers=""
  local group

  # Use the internal field separator,
  # it determines where the for-loop separates the input
  IFS=","
  for name in $1; do
    # Try to retrieve something
    group=$(expand-group "$name")
    if [ -z "$group" ]; then
      # If it is empty, fallback to the original term
      reviewers=$(echo -e "$reviewers\n$name")
    else
      # otherwise, use the result
      reviewers=$(echo -e "$reviewers\n$group")
    fi
  done
  # Make sure the reviewers are not duplicated and join the list using commas
  echo "$reviewers" | tail -n +2 | uniqfy
  # tip: use tail to remove the trailing newline
  # (-n indicates the starting line, beginning by 1)
}

expand-emails() {
  # Given a comma separated list of reviewers and groups, expand it to the
  # emails of each individual reviewer.
  #
  # Arguments:
  #   list - comma separated list of reviewers or groups
  # Returns: list of reviewer aliases, separated by the comma

  local reviewers
  local emails
  local exit_code
  local EMAIL_REGEX

  EMAIL_REGEX="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$"

  reviewers="$(expand-list "$1")"
  emails=""

  IFS=","
  for name in $reviewers; do
    if [[ "$name" =~ $EMAIL_REGEX ]]; then
      email="$name"
    else
      email=$(find-reviewer-email "$name")

      # Fail if find-reviewer fail
      exit_code=$?
      [ $exit_code -ne 0 ] && return $exit_code
    fi

    emails="$(echo -e "$emails\n$email")"
  done
  # Make sure the reviewers are not duplicated and join the list using commas
  echo "$emails" | tail -n +2 | uniqfy
}
