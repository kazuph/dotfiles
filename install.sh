#!/bin/bash -u
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
    chsh -s /bin/zsh
fi

# install ore setting
git clone https://kazuph@github.com/kazuph/dotfiles.git
cd dotfiles

git clone https://github.com/zsh-users/zsh-completions.git
git clone https://github.com/knu/z.git

cd ~/.
ln -s ~/dotfiles/.vimrc .vimrc
ln -s ~/dotfiles/.gitconfig .gitconfig
ln -s ~/dotfiles/.zshrc .zshrc
ln -s ~/dotfiles/.zshenv .zshenv
ln -s ~/dotfiles/.tmux.conf .tmux.conf

# NeoBundleInstall from commandline
vim +NeoBundleInstall +qa
