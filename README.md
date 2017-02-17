# git-to-from-review

Git to-review and from-review commands to integrate with Gerrit code review tool
to simplify usage of fetch and push commands. Differently from aliases or custom
refspec configurations, these commands work nicely with multiple remote branches
and repositories.

## Overview

The `git to-review` command sends to Gerrit a local branch to code-review. The
destination remote and branch is taken from branch tracking information or from
the command line if tracking information is missing or something other than a
branch is being sent.

The `git from-review` command retrieves from Gerrit one or all patch sets of
some change, optionally creating or updating branches pointing to the patch set
commits.

## Installation

Download the scripts in `bin` directory into a directory in your `PATH`
environment variable (such as `/usr/local/bin` to install for all users).

To set up auto-completion of arguments in Bash, download the script
`etc/bash_completion.d/git-to-from-review` and source at Bash startup.
To install for all users, simply place it inside `/etc/bash_completion.d`.

## Usage

### git to-review

    usage: git to-review [<options>] [<commit>]

        Send a branch to code-review for the branch it tracks.

        -v, --verbose         be more verbose
        -q, --quiet           be more quiet
        -n, --dry-run         dry run
        -d, --draft           send as draft
        --remote ...          remote name
        --for ...             branch to submit for review
        -u, --set-upstream    set upstream for further patch sets
        -f, --force           allow sending multiple changes
        --no-verify           do not run pre-push hook

#### Basic usage

Commit to `master` (which tracks `origin/master`) and send `HEAD` to review for
`master` (equivalent to `git push origin HEAD:refs/for/master`):

    $ git status
    On branch master
    Your branch is ahead of 'origin/master' by 1 commit.
    ...
    $ git to-review
    To ssh://gerrit.example.com:29418/project
     * [new branch]      HEAD -> refs/for/master

New patch sets to the same change are sent exactly the same way, just preserve
the `Change-Id:` line in commit message, as usual.

#### Drafts

To send the commit as a draft change or patch set, add the `-d` or `--draft`
option:

    $ git to-review -d
    To ssh://gerrit.example.com:29418/project
     * [new branch]      HEAD -> refs/drafts/master

#### Specifying branch or commit

To send another branch or commit instead of `HEAD`, just add it to the command
line. If the branch has tracking information, it is used to determine which
remote and branch to send to.

    $ git branch -vv
      feature 1234567 [origin/feature] ...
      local   89abcde ...
    * master  f012345 [origin/master] ...

    $ git to-review feature
    To ssh://gerrit.example.com:29418/project
     * [new branch]      feature -> refs/for/feature

    $ git to-review --for=master --set-upstream local
    Branch local set up to track remote branch master from origin.
    To ssh://gerrit.example.com:29418/project
     * [new branch]      local -> refs/for/master

### git from-review

    usage: git from-review [<options>] <change>[/<patchset>] [<branch>]

        Retrieves a change from code-review into a branch.

        -v, --verbose         be more verbose
        -q, --quiet           be more quiet
        -n, --dry-run         dry run
        --remote ...          remote name
        -u, --set-upstream-to ...
                              set upstream branch for further patch sets
        -f, --force           allow forced updated of branch

#### Basic usage

To create a branch `change` at the patch set 3 of change 1234, just type:

    $ git from-review 1234/3 change
    From ssh://gerrit.example.com:29418/project
     * [new ref]         refs/changes/34/1234/3 -> change

The remote name defaults to `origin` if unspecified.

#### Retrieving all patch sets

To retreive all patch sets from a change, don't specify the patch set number,
but it is mandatory to specify a branch name prefix. For instance:

    $ git from-review 1234 change
    From ssh://gerrit.example.com:29418/project
     * [new ref]         refs/changes/34/1234/1 -> change/1
     * [new ref]         refs/changes/34/1234/2 -> change/2
     * [new ref]         refs/changes/34/1234/3 -> change/3

#### Without local branch

To simply retrieve a patch set, without local branch creation, a patch set
number must be specified:

    $ git from-review 1234/3
    From ssh://gerrit.example.com:29418/project
     * [new ref]         refs/changes/34/1234/3 -> FETCH_HEAD

This is equivalent to the first part of default Gerrit download commands.

#### Create local branch with tracking information

To create the same branch `change` from the example above, but set up tracking
information in order to amend the change and send a new patch set, type:

    $ git from-review --set-upstream-to=feature 1234/3 change
    From ssh://gerrit.example.com:29418/project
     * [new ref]         refs/changes/34/1234/3 -> change
    Branch change set up to track remote branch feature from origin.

    # Checkout, edit and amend, then:
    $ git to-review
    To ssh://gerrit.example.com:29418/project
     * [new branch]      change -> refs/for/feature
