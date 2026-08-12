#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# --link-only refreshes the symlinks and skips every bootstrap step. bin/sync
# uses it after a pull; a full run is only needed on a new machine.
LINK_ONLY=""
[ "${1:-}" = "--link-only" ] && LINK_ONLY=1

if [ -z "$LINK_ONLY" ]; then
echo "Installing dotfiles from $DOTFILES_DIR"

# ── Homebrew & core packages ──────────────────────────────────────
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS: install Homebrew if missing, then use it for core packages
    if ! command -v brew &>/dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    echo "Installing brew packages..."
    brew install tmux fzf
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

fi  # end bootstrap (skipped by --link-only)

# ── Link packages ──────────────────────────────────────────────────
cd "$DOTFILES_DIR"

# One mechanism on every machine. stow is not installable without root on the
# lab servers, and stow links directories while a fallback links files, which
# is how the same package ended up laid out three different ways. Everything
# below is plain `ln -s`, so all machines match.
#
# Granularity: one symlink per file, except each skill directory, which is
# linked whole so new files inside it appear without re-running this script.
# ~/.claude/skills also holds unrelated skills, so it is never linked itself.

# Print the entries of a package, relative to the package root.
package_entries() {
    local pkg="$1"
    if [ -d "$pkg/.claude/skills" ]; then
        find "$pkg/.claude/skills" -mindepth 1 -maxdepth 1 -type d
    fi
    find "$pkg" -type f -not -path "$pkg/.claude/skills/*"
}

# Displaced files go here, not next to the original: a .bak left inside
# ~/.claude/skills/ is picked up as a second copy of that skill.
BACKUP_DIR="$HOME/.dotfiles-backup"

# An earlier layout linked whole directories (~/.claude/hooks -> the repo). A
# target under such a directory resolves to the source file itself, so treating
# it as a conflict would move the repo's own file away. Replace those directory
# symlinks with real directories first. Only ones pointing into this repo: on
# seoul ~/.claude legitimately points at /data, and that must be left alone.
ensure_real_dirs() {
    local dir="$1"
    case "$dir" in "$HOME"|/|.) return 0 ;; esac
    ensure_real_dirs "$(dirname "$dir")"
    if [ -L "$dir" ] && [ -d "$dir" ]; then
        case "$(cd "$dir" && pwd -P)/" in
            "$DOTFILES_DIR"/*)
                echo "    unlinking directory $dir (was linked into the repo)"
                rm "$dir"
                ;;
        esac
    fi
    [ -d "$dir" ] || mkdir -p "$dir"
}

link_entry() {
    local src="$DOTFILES_DIR/$1" rel="${1#*/}"
    local target="$HOME/$rel"

    ensure_real_dirs "$(dirname "$target")"

    if [ -L "$target" ]; then
        [ "$(readlink "$target")" = "$src" ] && return 0
        rm "$target"
    elif [ -e "$target" ]; then
        # Never displace something that is really the source file.
        if [ "$(cd "$(dirname "$target")" && pwd -P)/$(basename "$target")" = "$src" ]; then
            echo "    skipped $rel (target resolves to the source)" >&2
            return 0
        fi
        local dest="$BACKUP_DIR/$rel"
        mkdir -p "$(dirname "$dest")"
        rm -rf "${dest:?}"
        mv "$target" "$dest"
        echo "    backed up → ${dest/#"$HOME"/\~}"
    fi

    mkdir -p "$(dirname "$target")"
    ln -s "$src" "$target"
    echo "    linked ${target#"$HOME"/}"
}

# A bad ssh config is discarded wholesale by ssh, which costs you every
# connection from that machine. Catch it before it is linked into place.
check_ssh_config() {
    command -v ssh >/dev/null || return 0
    ssh -F "$DOTFILES_DIR/ssh/.ssh/config" -G github.com >/dev/null 2>&1 && return 0
    echo "ERROR: ssh/.ssh/config is not valid for $(ssh -V 2>&1)" >&2
    ssh -F "$DOTFILES_DIR/ssh/.ssh/config" -G github.com 2>&1 | head -5 >&2
    echo "Refusing to link it. Guard newer options with IgnoreUnknown." >&2
    exit 1
}

echo "Linking dotfiles..."
check_ssh_config
for pkg in zsh vim tmux ssh claude codex; do
    [ -d "$pkg" ] || continue
    echo "  $pkg"
    while IFS= read -r entry; do
        link_entry "$entry"
    done < <(package_entries "$pkg")
done

[ -n "$LINK_ONLY" ] && exit 0

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
