#!/bin/bash -u

# install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/kazuph/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

curl -sL https://gist.github.com/kawaz/d95fb3b547351e01f0f3f99783180b9f/raw/install-pam_tid-and-pam_reattach.sh | bash

brew install git
brew install zsh
brew install reattach-to-user-namespace
brew install tmux
brew install wget
brew install fd
brew install fzf
brew install ripgrep
brew install hub
brew install git-delta
brew install bat
brew install silicon
brew install macvim neovim
brew install font-hack-nerd-font
brew install ghq
brew install anyenv
anyenv init
anyenv install --init
mkdir -p $(anyenv root)/plugins
git clone https://github.com/znz/anyenv-update.git $(anyenv root)/plugins/anyenv-update

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
# ln -sfv ~/dotfiles/.vimrc .vimrc
ln -sfv ~/dotfiles/.gvimrc .gvimrc
ln -sfv ~/dotfiles/.gitconfig .gitconfig
ln -sfv ~/dotfiles/.zshrc .zshrc
ln -sfv ~/dotfiles/.zshenv .zshenv
ln -sfv ~/dotfiles/.tmux.conf .tmux.conf
ln -sfv ~/dotfiles/.zpreztorc .zpreztorc
ln -sfv ~/dotfiles/.ideavimrc .ideavimrc
mkdir -p ~/.config/nvim/
ln -sfv  ~/dotfiles/init.vim ~/.config/nvim/init.vim

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
tmux source ~/.tmux.conf

python3 -m pip install --user --upgrade pynvim


