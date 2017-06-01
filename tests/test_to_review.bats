#!/usr/bin/env bats
# shellcheck disable=SC2154,SC2164

load helper

setup() {
  with-installation
}

teardown() {
  restore
}

@test "install to different prefix" {
  # Given a commit and reviewers and groups configured.
  within-repo-with-commit
  with-n-reviewers 4
  git config --add --local reviewers.groups.g1 u1,u2
  git config --add --local reviewers.groups.g2 u3
  # And a remote repository
  git remote add origin .
  git fetch --all
  # --> until here git creates a origin/master reference that points to
  # local/master
  touch file
  git add file
  git commit -m "Message"
  # --> now local/master differs from origin/master by 1 commit
  git branch --set-upstream-to origin/master
  # When git to-review is called with -r,
  run git to-review -r u4,g1,g2 --dry-run
  # then the remote branch should have a reviewer string appended
  assert_output --partial "refs/for/master%r=u1@e1,r=u2@e2,r=u3@e3,r=u4@e4"
}
