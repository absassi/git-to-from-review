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
  # Given a comma separated list of reviewers, expand it considering
  # the email of each individual reviewer.
  #
  # Argument: comma separated list of reviewers
  # Returns: list of emails, separated by the comma
  # Note: the input list may contain emails

  local reviewers
  local emails
  local exit_code
  local EMAIL_REGEX

  EMAIL_REGEX="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$"

  emails=""

  IFS=","
  for name in $1; do
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

expand-reviewers-string() {
  # Given a comma separated list with a mix of reviewers alias, groups and
  # emails, expand it into a string that is accepted by gerrit to be appended
  # to the remote branch name.
  #
  # Argument: comma separated list of reviewers, groups or emails
  # Returns: string required by gerrit
  # See: https://gerrit-review.googlesource.com/Documentation/user-upload.html#reviewers
  # Note: The return string does not contain the starting '%'

  users=$(expand-list "$1")
  reviewers_string=$(expand-emails "$users" | sed "s/,/,r=/g")

  # Fail if expand-emails fail
  exit_code=$?
  [ $exit_code -ne 0 ] && return $exit_code

  # if the reviewers_string is not empty, the first reviewer
  # also should start with "r="
  [ -n "$reviewers_string" ] && echo "r=$reviewers_string"
}
