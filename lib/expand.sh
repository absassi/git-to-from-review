#!/bin/bash

find-reviewer-email() {
  # Retrieve the email associated with a reviewer alias
  #
  # Argument: reviewer alias
  # Returns: email address for reviewer
  git config --get "reviewers.$1"
}

expand-group() {
  # Retrieve all the reviewers stored in a group
  #
  # Argument: group name
  # Returns: list of reviewer aliases, separated by ',' (comma)

  # Since it is a multivar, multiple lines can be returned, so let's join them
  git config --get-all "reviewers.groups.$1" | paste -sd "," -
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
    group=$(expand-group $name)
    if [ -z "$group" ]; then
      # If it is not empty, fallback to the original term
      reviewers=$(printf "$name\n$reviewers")
        # ^ printf ignores final new lines, so prepending solves the problem
        # of tralling commas
    else
      # otherwise, use the result
      reviewers=$(printf "$group\n$reviewers")
    fi
  done
  # Make sure the reviewers are not duplicated and join the list using commas
  echo "$reviewers" | sort | uniq | paste -sd "," -
}

expand-emails() {
  # Given a comma separated list of reviewers and groups, expand it to the
  # emails of each individual reviewer.
  #
  # Arguments:
  #   list - comma separated list of reviewers or groups
  # Returns: list of reviewer aliases, separated by the comma

  local reviewers="$(expand-list $1)"
  local emails=""

  IFS=","
  for name in $reviewers; do
    emails=$(printf "$(find-reviewer-email $name)\n$emails")
  done
  # Make sure the reviewers are not duplicated and join the list using commas
  echo "$emails" | sort | uniq | paste -sd "," -
}
