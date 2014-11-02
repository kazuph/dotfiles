#!/bin/bash -u

# install homebrew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew install git
brew install zsh
brew install reattach-to-user-namespace
brew install tmux
brew install wget
brew install hub
brew install macvim --with-cscope --with-lua --HEAD && brew install vim --with-lua

# install ore setting
git clone git@github.com:kazuph/dotfiles.git
cd dotfiles

git clone https://github.com/zsh-users/zsh-completions.git
git clone https://github.com/knu/z.git

cd ~/.
ln -sfv ~/dotfiles/.vimrc .vimrc
ln -sfv ~/dotfiles/.gvimrc .gvimrc
ln -sfv ~/dotfiles/.gitconfig .gitconfig
ln -sfv ~/dotfiles/.zshrc .zshrc
ln -sfv ~/dotfiles/.zshenv .zshenv
ln -sfv ~/dotfiles/.tmux.conf .tmux.conf

# NeoBundleInstall from commandline
curl https://raw.githubusercontent.com/Shougo/neobundle.vim/master/bin/install.sh | sh
vim +qa
