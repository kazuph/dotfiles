#!/bin/bash -u

# OSの種類を取得
if [ "$(uname)" == "Darwin" ]; then
    # Mac OSの場合
    echo "Mac OS"
    # install homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/kazuph/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
    
    curl -sL https://gist.github.com/kawaz/d95fb3b547351e01f0f3f99783180b9f/raw/install-pam_tid-and-pam_reattach.sh | bash

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Linuxの場合
    echo "Linux"
    
    # Ubuntuの場合は必要なパッケージをインストール
    if [ "$(lsb_release -si)" == "Ubuntu" ]; then
        echo "Ubuntu"
        sudo apt update
        sudo apt install -y build-essential wget curl git tree -y
	sudo apt install -y aria2

        # install homebrew
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        (echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/kazuph/.profile
    fi
fi

