#!/usr/bin/env bats

load test_helper

setup() {
  source "$projdir/lib/expand.sh"
  within-repo
}

teardown() {
  restore
}

@test "find-reviewer-email retrieves the email of a reviewer" {
  # Given a alias is configured for a reviewer,
  git config --local --add reviewers.u1 u1@e1
  # then the function should retrieve that email
  email=$(find-reviewer-email u1)
  assert_equal $email u1@e1
}

@test "expand-group turn group name into list of reviewer aliases" {
  # Given aliases configured for some reviewers,
  for i in {1..6}; do
    git config --local --add "reviewers.u$i" "u$i@e$i"
  done
  # when the aliases are stored in a group, even not at once,
  git config --local --add reviewers.groups.g1 u1,u2,u3
  git config --local --add reviewers.groups.g1 u4,u5,u6
  # then the function should return all the aliases concatenated by ',' (comma)
  reviewers=$(expand-group g1)
  assert_equal $reviewers u1,u2,u3,u4,u5,u6
}

@test "expand-list turn mixed reviewers/groups list into just reviewers" {
  # Given a mixed list with existing users and groups
  for i in {1..9}; do
    git config --local --add "reviewers.u$i" "u$i@e$i"
  done
  git config --local --add reviewers.groups.g1 u3,u4,u5
  git config --local --add reviewers.groups.g2 u7,u8
  # then the function should expand all the groups and leave reviewers only
  reviewers=$(expand-list u1,u2,g1,u6,g2,u9)
  assert_equal $reviewers u1,u2,u3,u4,u5,u6,u7,u8,u9
}

@test "expand-emails turn mixed list of reviewers/groups into list of emails" {
  # Given a mixed list with existing users and groups
  for i in {1..9}; do
    git config --local --add "reviewers.u$i" "u$i@e$i"
  done
  git config --local --add reviewers.groups.g1 u3,u4,u5
  git config --local --add reviewers.groups.g2 u7,u8
  # then expand-groups should expand all the groups and leave reviewers only
  emails=$(expand-emails u1,u2,g1,u6,g2,u9)
  assert_equal $emails u1@e1,u2@e2,u3@e3,u4@e4,u5@e5,u6@e6,u7@e7,u8@e8,u9@e9
}
