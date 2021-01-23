ZSH_RS_FILE = "~/.zshrc"

all: sync

sync:
	brew bundle
	sed -iE 's/ZSH_THEME=".*"/ZSH_THEME="norm"/g' $(ZSH_RS_FILE)

	#alias del="trash"
	#alias rm="echo do not directly delete any type of file! USE DEL"
	#export HOMEBREW_GITHUB_API_TOKEN=...
	#source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
	#export NVM_DIR="$HOME/.nvm" [ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This l$ [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nv$

	#Terminal stalling fix
	#https://stackoverflow.com/a/58198709
	sudo xcodebuild -license accept

	#VS Code Extensions
	#code --list-extensions | xargs -L 1 echo code --install-extension
	code --install-extension bladnman.auto-align
	code --install-extension CoenraadS.bracket-pair-colorizer
	code --install-extension esbenp.prettier-vscode
	code --install-extension felixfbecker.php-intellisense
	code --install-extension imperez.smarty
	code --install-extension mikestead.dotenv
	code --install-extension mohsen1.prettify-json
	code --install-extension monokai.theme-monokai-pro-vscode
	code --install-extension mrmlnc.vscode-apache
	code --install-extension ms-azuretools.vscode-docker
	code --install-extension ms-vscode.sublime-keybindings
	code --install-extension msjsdiag.debugger-for-chrome
	code --install-extension redhat.vscode-yaml
	code --install-extension syler.sass-indented
	code --install-extension william-voyek.vscode-nginx