#!/bin/bash

# OSの種類を取得
if [ "$(uname)" == "Darwin" ]; then
    # Mac OSの場合
    echo "Mac OS"
elif [ "$(uname -s)" == "Linux" ]; then
    # Linuxの場合
    echo "Linux"
    
    # Ubuntuの場合は必要なパッケージをインストール
    if [ "$(lsb_release -si)" == "Ubuntu" ]; then
        echo "Ubuntu"
        sudo apt update
        sudo apt install build-essential wget curl git -y
    fi
fi

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
brew install ag
brew install macvim neovim
brew install font-hack-nerd-font
brew install ghq
brew install jq
brew install ms-jpq/sad/sad
brew install anyenv
brew install trash
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
ln -sfv ~/dotfiles/.gitignore_global .gitignore_global
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


