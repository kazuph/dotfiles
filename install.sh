#!/bin/bash -u

# install homebrew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew install git
brew install zsh
brew install reattach-to-user-namespace
brew install tmux
brew install wget
brew install fd
brew install ripgrep
brew install hub
brew install macvim vim nvim
brew tap homebrew/cask-fonts
brew cask install font-hack-nerd-font
brew install git-delta
brew install silicon

# install oh-my-zsh
zsh
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
  ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done
chsh -s /bin/zsh

# install ore setting
git clone git@github.com:kazuph/dotfiles.git
cd dotfiles

git clone https://github.com/zsh-users/zsh-completions.git

cd ~/.
ln -sfv ~/dotfiles/.vimrc .vimrc
ln -sfv ~/dotfiles/.gvimrc .gvimrc
ln -sfv ~/dotfiles/.gitconfig .gitconfig
ln -sfv ~/dotfiles/.zshrc .zshrc
ln -sfv ~/dotfiles/.zshenv .zshenv
ln -sfv ~/dotfiles/.tmux.conf .tmux.conf
ln -sfv ~/dotfiles/.zpreztorc .zpreztorc
ln -sfv ~/dotfiles/.ideavimrc .ideavimrc

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
tmux source ~/.tmux.conf

# NeoBundleInstall from commandline
curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh
sh ./installer.sh ~/.dein
vim +qa
