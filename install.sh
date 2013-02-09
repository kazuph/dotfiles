#!/usr/bin/env bash
cd ~/.
which git > /dev/null 2>&1
if [ $? -eq 0 ] ; then
    echo Success!
else
    echo Error! >&2
    sudo yum install -y git
fi
git clone https://kazuph@github.com/kazuph/dotfiles.git
cd dotfiles
git submodule init
git submodule update
cd ~/.
ln -s dotfiles/_vimrc .vimrc
ln -s ~/dotfiles/_gitconfig .gitconfig
ln -s ~/dotfiles/_zshrc .zshrc
ln -s ~/dotfiles/_zshenv .zshenv
ln -s ~/dotfiles/_tmux.conf .tmux.conf
