ln -sfv ~/dotfiles/.gitconfig ~/.gitconfig
ln -sfv ~/dotfiles/.gitignore_global ~/.gitignore_global
ln -sfv ~/dotfiles/.tmux.conf ~/.tmux.conf

# tmux scripts (pane border label, status segments, etc.)
mkdir -p ~/.tmux
ln -snfv ~/dotfiles/.tmux/scripts ~/.tmux/scripts

# Ghostty configuration
# 実体はディレクトリ単位で管理しているため、~/.config/ghostty をシンボリックリンクに統一
mkdir -p ~/.config
ln -snfv ~/dotfiles/.config/ghostty ~/.config/ghostty
