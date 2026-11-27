.DEFAULT_GOAL := help
.PHONY: help install link relink brew dump doctor helium helium-dump

help: ## Show this list
	@grep -E '^[a-z-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

install: brew link helium ## Install everything: brew bundle + symlinks + Helium extensions

link: ## Symlink the configs into the home directory (backs up what is there)
	@bash scripts/link.sh

relink: ## Show what would change without touching anything (dry run)
	@DRY_RUN=1 bash scripts/link.sh

brew: ## Install everything in the Brewfile
	brew bundle --file=Brewfile

dump: ## Regenerate the Brewfile from this machine (keeps hand-added entries)
	@bash scripts/dump.sh
	@echo "Brewfile updated — review it with 'git diff Brewfile'."

doctor: ## Check that the symlinks are in place
	@bash scripts/doctor.sh

helium: ## Register the Helium extensions in helium/extensions.txt (installed on next launch)
	@bash scripts/helium-extensions.sh install

helium-dump: ## Regenerate helium/extensions.txt from the installed Helium profiles
	@bash scripts/helium-extensions.sh dump
