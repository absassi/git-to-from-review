#!/usr/bin/env bats
# shellcheck disable=SC2154,SC2164

load helper

setup() {
  within-tmpdir
  cd "$projdir"
}

teardown() {
  restore
}

@test "install to different prefix" {
  # When installing to a different prefix
  run make install builddir="$tmpdir" prefix="$tmpdir"
  # then output should contain a notice about bash_completion.d,
  assert_output --partial NOTICE
  assert_output --partial /etc/bash_completion.d
  # the files should be concatenated in the build dir,
  assert_file_exist "$tmpdir/git-to-review"
  assert_file_exist "$tmpdir/git-from-review"
  # a bin dir should be created if not exists,
  assert_file_exist "$tmpdir/bin"
  # and the files should be generated under the given prefix
  assert_file_exist "$tmpdir/bin/git-to-review"
  assert_file_exist "$tmpdir/bin/git-from-review"
  assert_file_exist "$tmpdir/etc/bash_completion.d/git-to-from-review"
}

@test "accept trailing slash" {
  # When installing to a different prefix
  run make install prefix="$tmpdir/"
  # and the files should be generated under the given prefix
  assert_file_exist "$tmpdir/bin/git-to-review"
  assert_file_exist "$tmpdir/bin/git-from-review"
  assert_file_exist "$tmpdir/etc/bash_completion.d/git-to-from-review"
}

@test "make do not install by default" {
  # When 'install' is not passed
  make builddir="$tmpdir"
  # then no file should be created
  assert_file_not_exist "$tmpdir/bin"
  assert_file_not_exist "$tmpdir/etc"
}

@test "built git-to-review has shebang and expand-* functions" {
  make builddir="$tmpdir"
  run cat "$tmpdir/git-to-review"
  assert_line --index 0 "#!/usr/bin/env bash"
  cat "$tmpdir/git-to-review" | grep "expand-emails" | assert_success
}
