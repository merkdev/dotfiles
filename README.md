# dotfiles

macOS (Apple Silicon) kurulumum. Konfigler bu repoda durur, ev dizinine
symlink'lenir — yani `~/.zshrc`'yi duzenlemek repoyu duzenlemek demektir.

## Yeni makinede

```sh
git clone https://github.com/merkdev/dotfiles ~/Code/dotfiles
cd ~/Code/dotfiles
make install
```

`make install` once `brew bundle` ile her seyi kurar, sonra symlink'leri atar.
Yerinde gercek dosya varsa silmez, `.bak-<zaman>` olarak yanina tasir.

## Komutlar

| | |
|---|---|
| `make install` | brew bundle + symlink |
| `make link`    | sadece symlink'le |
| `make relink`  | ne olacagini goster, dokunma (dry run) |
| `make brew`    | Brewfile'daki her seyi kur |
| `make dump`    | Brewfile'i bu makineden yeniden uret |
| `make doctor`  | symlink'ler yerinde mi kontrol et |

## Ne nerede

```
home/     ~/.zshrc, .zprofile, .gitconfig, .gitignore_global
warp/     ~/.warp/ — settings.toml, themes/, tab_configs/
sublime/  Sublime Text kullanici tercihleri
Brewfile  formul, cask, tap, go ve uv araclari
scripts/  link.sh, doctor.sh
```

## Notlar

- Terminal: Warp, `xcad2k-dark` / `xcad2k-light` temalari, JetBrains Mono 13.
  Sistem temasina gore otomatik gecer (`system_theme = true`).
- Kabuk: zsh + oh-my-zsh. `zsh-autosuggestions` ve `zsh-syntax-highlighting`
  **.zshrc'nin en sonunda** yuklenir; syntax-highlighting kendisinden once
  tanimlanan widget'lari sarmaladigi icin oh-my-zsh'tan sonra gelmeli.
- Surum yoneticileri: nvm (node), rbenv (ruby), pnpm, cargo, go.
- Brewfile'a yeni paket eklemek icin elle yazma — kur, sonra `make dump`.
