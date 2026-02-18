#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing dotfiles from $DOTFILES_DIR"

# ── Homebrew & core packages ──────────────────────────────────────
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS: install Homebrew if missing, then use it for core packages
    if ! command -v brew &>/dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    echo "Installing brew packages..."
    brew install stow tmux fzf
else
    # Linux: install fzf to ~/.fzf if not available
    if ! command -v fzf &>/dev/null; then
        if [ ! -d "$HOME/.fzf" ]; then
            echo "Installing fzf to ~/.fzf..."
            git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
        fi
        "$HOME/.fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
    fi

    # Verify remaining required tools
    missing=()
    for cmd in tmux zsh; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [ ${#missing[@]} -ne 0 ]; then
        echo "Missing required packages: ${missing[*]}"
        echo "Install them with your system package manager, e.g.:"
        echo "  sudo apt install ${missing[*]}"
        echo "  sudo yum install ${missing[*]}"
        exit 1
    fi
fi

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

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]; then
    echo "Installing zsh-completions..."
    git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"
fi

# ── TPM (Tmux Plugin Manager) ──────────────────────────────────────
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# ── Stow packages ──────────────────────────────────────────────────
cd "$DOTFILES_DIR"

# Back up existing files that would conflict with stow/symlinks
handle_stow_conflicts() {
    local pkg="$1"
    local conflicts=()

    while IFS= read -r file; do
        local rel="${file#"$pkg"/}"
        local target="$HOME/$rel"
        # Conflict = real file (not a symlink) already exists at target
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            conflicts+=("$target")
        fi
    done < <(find "$pkg" -type f)

    if [ ${#conflicts[@]} -eq 0 ]; then
        return 0
    fi

    echo "  Existing files found for $pkg:"
    for f in "${conflicts[@]}"; do
        echo "    $f"
    done

    read -rp "  Overwrite? Backups will be saved as .bak [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        for f in "${conflicts[@]}"; do
            echo "    Backing up $f → ${f}.bak"
            cp "$f" "${f}.bak"
            rm "$f"
        done
        return 0
    else
        echo "  Skipping $pkg"
        return 1
    fi
}

# Manual symlink fallback when stow is not available
stow_manual() {
    local pkg="$1"
    while IFS= read -r file; do
        local rel="${file#"$pkg"/}"
        local target="$HOME/$rel"
        local source="$DOTFILES_DIR/$file"
        mkdir -p "$(dirname "$target")"
        ln -sf "$source" "$target"
    done < <(find "$pkg" -type f)
}

echo "Stowing dotfiles..."
for pkg in zsh vim tmux ssh claude; do
    if [ -d "$pkg" ]; then
        echo "  Stowing $pkg..."
        if handle_stow_conflicts "$pkg"; then
            if command -v stow &>/dev/null; then
                stow -t "$HOME" --restow "$pkg"
            else
                stow_manual "$pkg"
            fi
        fi
    fi
done

# ── Vim plugins ─────────────────────────────────────────────────────
echo "Installing vim plugins..."
vim +PlugInstall +qall 2>/dev/null || true

# ── fzf key bindings ───────────────────────────────────────────────
fzf_install=""
for candidate in \
    /opt/homebrew/opt/fzf/install \
    /usr/local/opt/fzf/install \
    "$HOME/.fzf/install" \
    /home/linuxbrew/.linuxbrew/opt/fzf/install \
    /usr/share/doc/fzf/examples/key-bindings.zsh; do
    if [ -f "$candidate" ]; then
        fzf_install="$candidate"
        break
    fi
done
if [ -n "$fzf_install" ]; then
    if [[ "$fzf_install" == */key-bindings.zsh ]]; then
        echo "fzf key bindings available at $fzf_install (sourced via plugin)"
    else
        "$fzf_install" --key-bindings --completion --no-update-rc --no-bash --no-fish
    fi
fi

echo ""
echo "Done! Next steps:"
echo "  1. Create ~/.zshrc.local for machine-specific config (conda, tokens, etc.)"
echo "  2. Open a new terminal — p10k configure wizard will launch if needed"
echo "  3. In tmux, press C-a Shift-I to install TPM plugins"
