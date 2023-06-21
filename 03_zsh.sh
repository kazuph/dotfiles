curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
echo Please, run chsh (zsh path is $(which zsh))

ln -sfv ~/dotfiles/.zshrc_for_ubuntu ~/.zshrc
ln -sfv ~/dotfiles/.zimrc_for_ubuntu ~/.zimrc
