ZSH_RS_FILE = "~/.zshrc"

all: sync

sync:
	cp oxide.zsh-theme ~/.oh-my-zsh/themes/
	sed -iE 's/ZSH_THEME=".*"/ZSH_THEME="oxide"/g' ~/.zshrc

	#alias del="trash"
	#alias rm="echo do not directly delete any type of file! USE DEL"
	#export HOMEBREW_GITHUB_API_TOKEN=...