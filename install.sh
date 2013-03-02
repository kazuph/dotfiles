#!/usr/bin/env bash
cd ~/.
# install git
which git > /dev/null 2>&1
if [ $? -eq 0 ] ; then
    echo Success!
else
    echo Install git! >&2
    sudo yum install -y git
fi

# install vim
which vim > /dev/null 2>&1
if [ $? -eq 0 ] ; then
    echo Success!
else
    echo Install vim! >&2
    sudo yum install -y vim-enhanced
fi

# install zsh
which zsh > /dev/null 2>&1
if [ $? -eq 0 ] ; then
    echo Success!
else
    echo Install zsh! >&2
    sudo yum install -y zsh
    curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
fi

# install tmux
which tmux > /dev/null 2>&1
if [ $? -eq 0 ] ; then
    echo Success!
else
    echo Install tmux! >&2
    sudo su -
    cd /usr/local/src
    wget https://github.com/downloads/libevent/libevent/libevent-2.0.20-stable.tar.gz
    tar xzf libevent-2.0.20-stable.tar.gz
    cd libevent-2.0.20-stable
    ./configure
    make
    make install
    cd /usr/local/src
    wget downloads.sourceforge.net/tmux/tmux-1.7.tar.gz
    tar xzf tmux-1.7.tar.gz
    cd tmux-1.7
    ./configure
    make
    make install
    ln -s /usr/local/lib/libevent-2.0.so.5 /usr/lib64/libevent-2.0.so.5
    exit
fi

# install ore setting
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

# NeoBundleInstall from commandline
vim +NeoBundleInstall +qa
