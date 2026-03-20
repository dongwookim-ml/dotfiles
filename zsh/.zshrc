# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git z fzf zsh-autosuggestions zsh-syntax-highlighting zsh-completions)

source $ZSH/oh-my-zsh.sh

# ── Editor ──────────────────────────────────────────────────────────
export EDITOR='vim'
export VISUAL='vim'

# ── History ─────────────────────────────────────────────────────────
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS   # no duplicate entries
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY          # share history between sessions

# ── Aliases ─────────────────────────────────────────────────────────
alias ll='ls -lAFh'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'
alias gc='git commit'
alias gp='git push'
alias gpl='git pull'
alias cc='claude --dangerously-skip-permissions --continue || claude --dangerously-skip-permissions'

# tmux
alias ta='tmux attach -t'
alias tad='tmux attach -d -t'
alias tl='tmux list-sessions'
alias tn='tmux new-session -s'
alias tk='tmux kill-session -t'
alias tks='tmux kill-server'

export PATH="$HOME/.local/bin:$PATH"

# ── Dotfiles update check ─────────────────────────────────────────
# Compares local HEAD against remote tracking ref (no network cost).
# A background fetch keeps remote refs fresh for the next shell.
() {
  local dotdir="$HOME/dotfiles"
  [[ -d "$dotdir/.git" ]] || return
  local local_head remote_head
  local_head=$(git -C "$dotdir" rev-parse HEAD 2>/dev/null) || return
  remote_head=$(git -C "$dotdir" rev-parse @{u} 2>/dev/null) || return
  if [[ "$local_head" != "$remote_head" ]]; then
    print -P "%F{yellow}[dotfiles] Your dotfiles are out of date. Run 'cd ~/dotfiles && git pull' to update.%f"
  fi
  # Fetch in background so remote refs are fresh next time
  git -C "$dotdir" fetch --quiet 2>/dev/null &!
}

# ── Machine-specific overrides ──────────────────────────────────────
# Put machine-specific config (conda init, tokens, etc.) in ~/.zshrc.local
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
