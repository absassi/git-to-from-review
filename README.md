# git-to-from-review

Git to-review and from-review commands to integrate with
[Gerrit code review](https://www.gerritcodereview.com/) tool to simplify usage
of fetch and push commands. Differently from aliases or custom refspec
configurations, these commands work nicely with multiple remote branches
and repositories.

These commands are inspired by the
[git-gerrit](https://github.com/gnustavo/git-gerrit) and
[git-review](https://github.com/openstack-infra/git-review) commands.

## Overview

The `git to-review` command sends to Gerrit a local branch to code-review. The
destination remote and branch is taken from branch tracking information or from
the command line if tracking information is missing or something other than a
branch is being sent.

The `git from-review` command retrieves from Gerrit one or all patch sets of
some change, optionally creating or updating branches pointing to the patch set
commits.

## Installation

To install for all users, download the repository and run `make install` with
root permissions. This will copy the executables to `/usr/local/bin` and the
Bash completion script to `/etc/bash_completion.d`.

To install into a specific location, a parameter `prefix` can be passed,
e.g. `make install prefix=$HOME/.local`. Note that this will not automatically
set up Bash auto-completion, therefore it will be necessary to source the
`$prefix/etc/bash_completion.d/git-to-from-review` script at Bash startup.

To uninstall, remove `git-to-review` and `git-from-review` from
`/usr/local/bin` or `$prefix/bin`, and `git-to-from-review` from
`/etc/bash_completion.d` if necessary.

Alternatively, for a "more manageable" installation/uninstallation process see
[GNU Stow](https://www.gnu.org/software/stow/manual/stow.html).

## Usage

### git to-review

    usage: git to-review [<options>] [<commit>]

        Send a branch to code-review for the branch it tracks.

        -v, --verbose         be more verbose
        -q, --quiet           be more quiet
        -n, --dry-run         dry run
        -d, --draft           send as draft
        -r, --reviewers ...   comma separated list of reviewers
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

#### Reviewers

`to-review` supports specifying the reviewers responsible for analyzing the
submitted change via the `-r` (or `--reviewers`) option.
This option accepts a comma separated list of emails, reviewer aliases or
groups.

The `git config` command can be used to configure both reviewer aliases and
groups. The following example illustrates a typical sequence of commands:

    $ git config --add --local reviewers.theguy theguy@thecompany.com
    $ git config --add --local reviewers.thegirl thegirl@thecompany.com
    $ git config --add --local reviewers.theboss theboss@thecompany.com
    $ git config --add --local reviewers.groups.buddies theguy,thegirl
    $ git to-review -r buddies,theboss,theintern@thecompany.com

Note that all these commands accept comma separated lists (no space should be
used).

Once configured aliases and groups can be used as many times as needed.
In the example, the `--local` flag means that the configuration only applies to
the current repository. Please refer to `git config` to understand the effects
of different flags.

In order to remove an alias or group, the file `config` under the `.git` folder
inside the repository can be edited (`git config --unset` also do the job).

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
        -r, --rebase          rebase onto the fetched patch set
        -c, --checkout        checkout the fetched patch set
        -p, --cherry-pick     cherry-pick the fetched patch set

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

#### Performing some actions

There is also the option to rebase onto, checkout or cherry-pick a fetched
patch set. In this case, the branch name is optional, but the patch set number
is mandatory. For instance, to download a patch set, create a branch and
checkout it:

    $ git from-review --checkout 1234/3 change
    From ssh://gerrit.example.com:29418/project
     * [new ref]         refs/changes/34/1234/3 -> change
    Switched to branch 'change'

The rebase action will trigger an interactive rebase, which is useful to remove
any previous patch set when rebeasing onto a new one.
