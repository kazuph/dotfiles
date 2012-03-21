# 新しい環境ですること
~~~
cd ~/.
git clone https://kazuph@github.com/kazuph/dotfiles.git
cd dotfiles
git submodule init
git submodule update
vim
:BundleInstall
cd ~/.
ln -s .vimrc /dotfiles/_vimrc
...
~~~
