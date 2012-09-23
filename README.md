# 新しい環境ですること
~~~
cd ~/.
git clone https://kazuph@github.com/kazuph/dotfiles.git
cd dotfiles
git submodule init
git submodule update
cd ~/.
ln -s dotfiles/_vimrc .vimrc
vim
:NeoBundleInstall
:q
cd
ln -s ~/dotfiles/_gitconfig .gitconfig
ln -s ~/dotfiles/_zshrc .zshrc
ln -s ~/dotfiles/_zshenv .zshenv
ln -s ~/dotfiles/_tmux.conf .tmux.conf
~~~
