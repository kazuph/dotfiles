# zmodload zsh/zprof && zprof

if [[ "$SHLVL" -eq 1 && ! -o LOGIN && -s "${ZDOTDIR:-$hOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

if [ -d /home/linuxbrew/.linuxbrew ] ; then
  eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
fi

# $HOME/bin以下をpathに追加する
if [ -d $HOME/bin ]; then
  export PATH=$HOME/bin:$PATH
fi

# uv  
export PATH="/Users/kazuph/.local/bin:$PATH"

# Rust cargo binaries (ensure priority over ~/.local/bin)
. "$HOME/.cargo/env"

# Function to prioritize ~/.cargo/bin over ~/.local/bin
prioritize_cargo_bin() {
    # Remove ~/.cargo/bin from PATH if it exists
    export PATH=$(echo $PATH | tr ':' '\n' | grep -v "^$HOME/.cargo/bin$" | tr '\n' ':' | sed 's/:$//')
    # Add ~/.cargo/bin at the beginning
    export PATH="$HOME/.cargo/bin:$PATH"
}

# Apply prioritization
prioritize_cargo_bin
