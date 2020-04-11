ZSH_RS_FILE = "~/.zshrc"

all: sync

sync:
	brew bundle
	sed -iE 's/ZSH_THEME=".*"/ZSH_THEME="norm"/g' ~/.zshrc

	#alias del="trash"
	#alias rm="echo do not directly delete any type of file! USE DEL"
	#export HOMEBREW_GITHUB_API_TOKEN=...
	#source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
	#export NVM_DIR="$HOME/.nvm" [ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This l$ [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nv$

