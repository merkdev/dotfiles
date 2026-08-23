.DEFAULT_GOAL := help
.PHONY: help install link relink brew dump doctor

help: ## Bu listeyi goster
	@grep -E '^[a-z-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

install: brew link ## Her seyi kur: brew bundle + symlink

link: ## Konfigleri ev dizinine symlink'le (varsa yedekler)
	@bash scripts/link.sh

relink: ## Once ne olacagini goster, hicbir sey degistirme
	@DRY_RUN=1 bash scripts/link.sh

brew: ## Brewfile'daki her seyi kur
	brew bundle --file=Brewfile

dump: ## Brewfile'i bu makineden yeniden uret
	brew bundle dump --file=Brewfile --describe --force
	@echo "Brewfile guncellendi — 'git diff Brewfile' ile bak."

doctor: ## Symlink'ler yerinde mi kontrol et
	@bash scripts/doctor.sh
