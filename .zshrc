# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path
paths=(
  /opt/homebrew/bin
	/opt/homebrew/opt/python@3.13/libexec/bin/python
	$HOME/.nodebrew/current/bin
	$HOME/.bun/bin
  $HOME/.local/bin
)

# Join paths
joined_paths=$(IFS=:; echo "${paths[*]}")

export PATH="$joined_paths:$PATH"

# 出力後1行空白追加
add_newline() {
  if [[ -z $PS1_NEWLINE_LOGIN ]]; then
    PS1_NEWLINE_LOGIN=true
  else
    printf '\n'
  fi
}
precmd() {
  add_newline
}

# z
. /opt/homebrew/etc/profile.d/z.sh

# =============================================================
# ====================== zinit(plugin manager)================================
# =============================================================

# zinit 初期化
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# プラグイン（遅延読み込み）
zinit light zsh-users/zsh-autosuggestions

# fzf キーバインド・補完（即時読み込み）
export FZF_CTRL_R_OPTS='--reverse'
zinit snippet https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.zsh
zinit snippet https://raw.githubusercontent.com/junegunn/fzf/master/shell/completion.zsh

# 補完システム初期化
autoload -Uz compinit
compinit

# プロンプト（Powerlevel10k）
zinit ice depth=1
zinit light romkatv/powerlevel10k

zinit light Aloxaf/fzf-tab

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"

# mise
eval "$(/opt/homebrew/bin/mise activate zsh)"

# zeno.zsh (abbr: alias の代わりに展開される略語)
export ZENO_ENABLE_SOCK=1
zinit light yuki-yano/zeno.zsh

bindkey ' '  zeno-auto-snippet
bindkey '^m' zeno-auto-snippet-and-accept-line

# ghq + fzf
function ghq-fzf() {
  local dir=$(ghq list -p | fzf --reverse --preview 'ls -la {}')
  if [ -n "$dir" ]; then
    cd "$dir"
  fi
}
alias g='ghq-fzf'

# z + fzf
function z-fzf() {
  if [ $# -gt 0 ]; then
    _z "$@"
    return
  fi
  local dir=$(_z -l 2>&1 | sed 's/^[0-9. ]*//' | fzf --reverse --tac --preview 'ls -la {}')
  if [ -n "$dir" ]; then
    cd "$dir"
  fi
}
alias z='z-fzf'
alias cc='claude'
alias claude="$HOME/.local/bin/claude"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# マシン固有の設定（git管理外）
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
