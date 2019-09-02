all: sync

sync:
	cp oxide.zsh-theme ~/.oh-my-zsh/themes/
	sed -iE 's/ZSH_THEME=".*"/ZSH_THEME="oxide"/g' ~/.zshrc