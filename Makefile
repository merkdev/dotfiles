.DEFAULT_GOAL := help
.PHONY: help install link relink brew python node dump doctor

help: ## Show this list
	@grep -E '^[a-z-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

install: brew python node link ## Install everything: brew bundle + runtimes + symlinks

link: ## Symlink the configs into the home directory (backs up what is there)
	@bash scripts/link.sh

relink: ## Show what would change without touching anything (dry run)
	@DRY_RUN=1 bash scripts/link.sh

brew: ## Install everything in the Brewfile
	brew bundle --file=Brewfile

# /usr/bin/python3 is sealed by macOS and cannot be upgraded.
python: ## Install the default Python via uv
	uv python install 3.14 --default --preview-features python-install-default

# brew installs the nvm script but no runtime, and node must come from nvm so
# .nvmrc can pick the version per project. Never `brew install node`.
node: ## Install the default Node via nvm
	. /opt/homebrew/opt/nvm/nvm.sh && nvm install --lts && nvm alias default 'lts/*'

dump: ## Regenerate the Brewfile from this machine (keeps hand-added entries)
	@bash scripts/dump.sh
	@echo "Brewfile updated — review it with 'git diff Brewfile'."

doctor: ## Check that the symlinks are in place
	@bash scripts/doctor.sh
