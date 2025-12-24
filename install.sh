#!/bin/bash
set -e

# ===========================================
# dotfiles installer for macOS
# ===========================================

DOTFILES_DIR="$HOME/dotfiles"
CONFIG_DIR="$HOME/.config"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ===========================================
# 1. OS Check
# ===========================================
if [ "$(uname)" != "Darwin" ]; then
    log_error "This script is for macOS only"
    exit 1
fi
log_info "Detected macOS"

# ===========================================
# 2. Install Homebrew
# ===========================================
# Try to find brew in common locations
if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

if ! command -v brew &> /dev/null; then
    log_warn "Homebrew not found."
    log_info "Please install Homebrew first by running:"
    echo ""
    echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    echo ""
    log_info "After installation, run this script again."
    exit 1
else
    log_info "Homebrew found at $(which brew)"
fi

# ===========================================
# 3. Install CLI Tools
# ===========================================
log_info "Installing CLI tools..."

BREW_PACKAGES=(
    # Core tools
    git
    zsh
    tmux
    neovim

    # Modern CLI replacements
    starship      # prompt
    zoxide        # smarter cd
    eza           # modern ls
    bat           # modern cat
    ripgrep       # modern grep
    fd            # modern find
    fzf           # fuzzy finder
    git-delta     # better git diff

    # Development
    ghq           # git repository manager
    gh            # GitHub CLI
    jq            # JSON processor
    tig           # git TUI

    # Utilities
    reattach-to-user-namespace  # tmux clipboard
    trash         # safe rm

    # Fonts
    font-udev-gothic-nf   # UDフォント + JetBrains Mono + Nerd Font
    font-hack-nerd-font
)

for pkg in "${BREW_PACKAGES[@]}"; do
    if brew list "$pkg" &>/dev/null; then
        log_info "$pkg already installed"
    else
        log_info "Installing $pkg..."
        brew install "$pkg" || log_warn "Failed to install $pkg"
    fi
done

log_success "CLI tools installed"

# ===========================================
# 4. Install mise (version manager)
# ===========================================
if ! command -v mise &> /dev/null; then
    log_info "Installing mise..."
    curl https://mise.run | sh
    eval "$($HOME/.local/bin/mise activate zsh)"
    log_success "mise installed"
else
    log_info "mise already installed"
fi

# ===========================================
# 5. Setup Prezto (zsh framework)
# ===========================================
if [ ! -d "$HOME/.zprezto" ]; then
    log_info "Installing Prezto..."
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "$HOME/.zprezto"
    log_success "Prezto installed"
else
    log_info "Prezto already installed"
fi

# ===========================================
# 6. Create symbolic links
# ===========================================
log_info "Creating symbolic links..."

mkdir -p "$CONFIG_DIR"

# Shell configs
ln -sfv "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
ln -sfv "$DOTFILES_DIR/.zshenv" "$HOME/.zshenv"
ln -sfv "$DOTFILES_DIR/.zpreztorc" "$HOME/.zpreztorc"
ln -sfv "$DOTFILES_DIR/.zprofile" "$HOME/.zprofile" 2>/dev/null || true

# Git configs
ln -sfv "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
ln -sfv "$DOTFILES_DIR/.gitignore_global" "$HOME/.gitignore_global"

# tmux
ln -sfv "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"

# Neovim (AstroNvim)
if [ -d "$CONFIG_DIR/nvim" ] && [ ! -L "$CONFIG_DIR/nvim" ]; then
    log_warn "Backing up existing nvim config..."
    mv "$CONFIG_DIR/nvim" "$CONFIG_DIR/nvim.bak.$(date +%Y%m%d%H%M%S)"
fi
ln -snfv "$DOTFILES_DIR/.config/nvim" "$CONFIG_DIR/nvim"

# Starship
ln -sfv "$DOTFILES_DIR/.config/starship.toml" "$CONFIG_DIR/starship.toml"

# Ghostty
ln -snfv "$DOTFILES_DIR/.config/ghostty" "$CONFIG_DIR/ghostty"

# IdeaVim
ln -sfv "$DOTFILES_DIR/.ideavimrc" "$HOME/.ideavimrc" 2>/dev/null || true

log_success "Symbolic links created"

# ===========================================
# 7. Setup tmux plugin manager
# ===========================================
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    log_info "Installing tmux plugin manager..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    log_success "TPM installed"
else
    log_info "TPM already installed"
fi

# ===========================================
# 8. modern-tools.zsh (already in .zshrc)
# ===========================================
if grep -q "modern-tools.zsh" "$DOTFILES_DIR/.zshrc" 2>/dev/null; then
    log_info "modern-tools.zsh is already configured in .zshrc"
else
    log_info "Adding modern-tools.zsh to .zshrc..."
    echo "" >> "$DOTFILES_DIR/.zshrc"
    echo "# Modern CLI tools (starship, zoxide, eza, bat, etc.)" >> "$DOTFILES_DIR/.zshrc"
    echo 'source "$HOME/dotfiles/.config/zsh/modern-tools.zsh"' >> "$DOTFILES_DIR/.zshrc"
    log_success "modern-tools.zsh added"
fi

# ===========================================
# 9. tmux plugins config (already in .tmux.conf)
# ===========================================
log_info "tmux plugins config is already configured in .tmux.conf"

# ===========================================
# 10. Install bat themes
# ===========================================
log_info "Setting up bat themes..."
mkdir -p "$(bat --config-dir)/themes"
if [ ! -f "$(bat --config-dir)/themes/Catppuccin Mocha.tmTheme" ]; then
    curl -sL "https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme" \
        -o "$(bat --config-dir)/themes/Catppuccin Mocha.tmTheme"
    bat cache --build
    log_success "bat themes installed"
fi

# ===========================================
# 11. TouchID for sudo (optional)
# ===========================================
log_info "Setting up TouchID for sudo..."
curl -sL https://gist.github.com/kawaz/d95fb3b547351e01f0f3f99783180b9f/raw/install-pam_tid-and-pam_reattach.sh | bash || log_warn "TouchID setup skipped"

# ===========================================
# Done!
# ===========================================
echo ""
log_success "=========================================="
log_success "Installation complete!"
log_success "=========================================="
echo ""
log_info "Next steps:"
echo "  1. Restart your terminal or run: exec zsh"
echo "  2. In tmux, press prefix + I to install plugins"
echo "  3. Set your terminal font to 'Hack Nerd Font'"
echo ""
log_info "Installed tools:"
echo "  - starship (modern prompt)"
echo "  - zoxide (z command for smart cd)"
echo "  - eza (modern ls with icons)"
echo "  - bat (modern cat with syntax highlighting)"
echo "  - ripgrep (fast grep replacement)"
echo "  - fd (fast find replacement)"
echo "  - fzf (fuzzy finder)"
echo "  - ghq (git repository manager)"
echo ""
