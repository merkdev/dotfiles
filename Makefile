.DEFAULT_GOAL := help
.PHONY: help install link relink brew python dump doctor

help: ## Show this list
	@grep -E '^[a-z-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

install: brew python link ## Install everything: brew bundle + Python + symlinks

link: ## Symlink the configs into the home directory (backs up what is there)
	@bash scripts/link.sh

relink: ## Show what would change without touching anything (dry run)
	@DRY_RUN=1 bash scripts/link.sh

brew: ## Install everything in the Brewfile
	brew bundle --file=Brewfile

# macOS ships Python 3.9 in /usr/bin on a sealed system volume: it cannot be
# removed or upgraded, and nothing should be installed into it. uv puts a real
# interpreter in ~/.local/bin, which is already first on PATH.
python: ## Install the default Python via uv
	uv python install 3.14 --default --preview-features python-install-default

dump: ## Regenerate the Brewfile from this machine (keeps hand-added entries)
	@bash scripts/dump.sh
	@echo "Brewfile updated — review it with 'git diff Brewfile'."

doctor: ## Check that the symlinks are in place
	@bash scripts/doctor.sh
