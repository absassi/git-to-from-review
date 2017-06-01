# Most user installed commands seems to be placed under /usr/local/bin,
DEFAULT_PREFIX := /usr/local
prefix ?= ${DEFAULT_PREFIX}
compdir := /etc/bash_completion.d
builddir := .build
ifneq (${prefix},${DEFAULT_PREFIX})
	# Unfortunately bash_completion does not consider /usr/local/etc
	compdir := ${prefix}${compdir}
endif

# Let's color warnings in yellow ...
# if system has tput, it supports ANSI. Otherwise the command true does
# nothing with the arguments and returns 0.
TPUT := $(shell command -v tput 2> /dev/null || echo 'true')

default: build

$(builddir):
	@mkdir -p $(builddir)

$(builddir)/git-to-review: $(builddir) \
		lib/shebang.sh lib/expand.sh bin/git-to-review
	cat $(filter-out $(builddir),$^) > $@

$(builddir)/git-from-review: $(builddir) \
		lib/shebang.sh bin/git-from-review
	cat $(filter-out $(builddir),$^) > $@

build: $(builddir)/git-to-review $(builddir)/git-from-review

install: build
# For some reason travis complains about ${preffix}/bin and
# ${prefix}/bash_completion.b not existing
# even with the -D flag passed to the install command ...
# So let's make sure it exists!
# (using a conditional statement before mkdir -p avoids trying to
# recreate /bin and /etc if $prefix is not specified.
# It not necessary, but maybe it is more polite ...)
	@[ ! -d "${prefix}/bin" ] && mkdir -p ${prefix}/bin
	install -D -t ${prefix}/bin $(builddir)/git-*
	@[ ! -d "${compdir}" ] && mkdir -p ${compdir}
	install -m 664 -D -t ${compdir} etc/bash_completion.d/*
ifneq (${prefix},${DEFAULT_PREFIX})
	@${TPUT} bold
	@${TPUT} setaf 0
	@${TPUT} setab 3
	@echo ''
	@echo '=========================== NOTICE ==========================='
	@${TPUT} sgr0
	@${TPUT} bold
	@echo 'In order to enable bash completion make sure to have something '
	@echo 'like the following lines is your ~/.bashrc:'
	@echo ''
	@echo 'if [ -d "${compdir}" ]; then'
	@echo '  for filename in "${compdir}/"*; do'
	@echo '    [ -f "$$filename" ] && source "$$filename";'
	@echo '  done'
	@echo 'fi'
	@${TPUT} sgr0
endif

clean:
	@rm -rf $(builddir)
