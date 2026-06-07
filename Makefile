# ─────────────────────────────────────────────────────────────────────────────
# Hunter — Bug Bounty Workspace
#
# Common entry points for toolchain bootstrap and maintenance.
# All targets are idempotent. The full installer lives in ./install.sh.
# ─────────────────────────────────────────────────────────────────────────────

SHELL := /usr/bin/env bash
INSTALL := ./install.sh

.PHONY: all help install tools wordlists templates update check clean uninstall

all: help

help:                       ## Show this help message
	@printf "Hunter — Bug Bounty Workspace\n\n"
	@printf "Targets:\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@printf "\nExamples:\n"
	@printf "  make install       # full toolchain + wordlists + templates\n"
	@printf "  make check         # verify what's installed\n"
	@printf "  make update        # pull latest tools and wordlists\n"
	@printf "  make clean         # uninstall everything from the toolchain\n"

install:                    ## Full install: tools, wordlists, nuclei templates, PATH
	$(INSTALL)

tools:                      ## Install only the tools (skip wordlists and templates)
	$(INSTALL) --tools-only

wordlists:                  ## Clone/update only the wordlists
	$(INSTALL) --wordlists-only

templates:                  ## Update only the nuclei templates
	$(SHELL) -c 'if command -v nuclei >/dev/null 2>&1; then nuclei -update-templates; else echo "nuclei not installed; run: make install"; exit 1; fi'

update:                     ## Update tools, wordlists, and templates in place
	$(INSTALL) --update

check:                      ## Verify installed tools and report missing
	$(INSTALL) --check

clean: uninstall            ## Alias for uninstall

uninstall:                  ## Remove everything installed by ./install.sh
	$(INSTALL) --uninstall
