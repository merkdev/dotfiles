.DEFAULT_GOAL := help
.PHONY: help install link relink brew dump doctor

help: ## Show this list
	@grep -E '^[a-z-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

install: brew link ## Install everything: brew bundle + symlinks

link: ## Symlink the configs into the home directory (backs up what is there)
	@bash scripts/link.sh

relink: ## Show what would change without touching anything (dry run)
	@DRY_RUN=1 bash scripts/link.sh

brew: ## Install everything in the Brewfile
	brew bundle --file=Brewfile

dump: ## Regenerate the Brewfile from this machine
	brew bundle dump --file=Brewfile --describe --force
	@echo "Brewfile updated — review it with 'git diff Brewfile'."

doctor: ## Check that the symlinks are in place
	@bash scripts/doctor.sh
