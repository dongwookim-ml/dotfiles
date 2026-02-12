#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing dotfiles from $DOTFILES_DIR"

# ── Homebrew ────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "Installing brew packages..."
brew install stow tmux fzf

# ── Oh My Zsh ───────────────────────────────────────────────────────
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# ── Zsh plugins ─────────────────────────────────────────────────────
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    echo "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# ── TPM (Tmux Plugin Manager) ──────────────────────────────────────
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# ── Stow packages ──────────────────────────────────────────────────
cd "$DOTFILES_DIR"

echo "Stowing dotfiles..."
for pkg in zsh vim tmux ssh claude; do
    if [ -d "$pkg" ]; then
        echo "  Stowing $pkg..."
        stow -t "$HOME" --restow "$pkg"
    fi
done

# ── Vim plugins ─────────────────────────────────────────────────────
echo "Installing vim plugins..."
vim +PlugInstall +qall 2>/dev/null || true

# ── fzf key bindings ───────────────────────────────────────────────
if [ -f /opt/homebrew/opt/fzf/install ]; then
    /opt/homebrew/opt/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish
elif [ -f /usr/local/opt/fzf/install ]; then
    /usr/local/opt/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish
fi

echo ""
echo "Done! Next steps:"
echo "  1. Create ~/.zshrc.local for machine-specific config (conda, tokens, etc.)"
echo "  2. Open a new terminal — p10k configure wizard will launch if needed"
echo "  3. In tmux, press C-a Shift-I to install TPM plugins"
