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

# 履歴をタブ間・ペイン間で共有
export HISTFILE=~/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000
setopt share_history

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

# Keep Git branch names untruncated in the Powerlevel10k prompt.
if [[ -n ${functions[my_git_formatter]:-} ]]; then
  function my_git_formatter() {
    emulate -L zsh

    if [[ -n $P9K_CONTENT ]]; then
      typeset -g my_git_format=$P9K_CONTENT
      return
    fi

    if (( $1 )); then
      local       meta='%244F'
      local      clean='%76F'
      local   modified='%178F'
      local  untracked='%39F'
      local conflicted='%196F'
    else
      local       meta='%244F'
      local      clean='%244F'
      local   modified='%244F'
      local  untracked='%244F'
      local conflicted='%244F'
    fi

    local res

    if [[ -n $VCS_STATUS_LOCAL_BRANCH ]]; then
      local branch=${(V)VCS_STATUS_LOCAL_BRANCH}
      res+="${clean}${(g::)POWERLEVEL9K_VCS_BRANCH_ICON}${branch//\%/%%}"
    fi

    if [[ -n $VCS_STATUS_TAG && -z $VCS_STATUS_LOCAL_BRANCH ]]; then
      local tag=${(V)VCS_STATUS_TAG}
      (( $#tag > 32 )) && tag[13,-13]=".."
      res+="${meta}#${clean}${tag//\%/%%}"
    fi

    [[ -z $VCS_STATUS_LOCAL_BRANCH && -z $VCS_STATUS_TAG ]] &&
      res+="${meta}@${clean}${VCS_STATUS_COMMIT[1,8]}"

    if [[ -n ${VCS_STATUS_REMOTE_BRANCH:#$VCS_STATUS_LOCAL_BRANCH} ]]; then
      res+="${meta}:${clean}${(V)VCS_STATUS_REMOTE_BRANCH//\%/%%}"
    fi

    if [[ $VCS_STATUS_COMMIT_SUMMARY == (|*[^[:alnum:]])(wip|WIP)(|[^[:alnum:]]*) ]]; then
      res+=" ${modified}wip"
    fi

    if (( VCS_STATUS_COMMITS_AHEAD || VCS_STATUS_COMMITS_BEHIND )); then
      (( VCS_STATUS_COMMITS_BEHIND )) && res+=" ${clean}<${VCS_STATUS_COMMITS_BEHIND}"
      (( VCS_STATUS_COMMITS_AHEAD && !VCS_STATUS_COMMITS_BEHIND )) && res+=" "
      (( VCS_STATUS_COMMITS_AHEAD  )) && res+="${clean}>${VCS_STATUS_COMMITS_AHEAD}"
    elif [[ -n $VCS_STATUS_REMOTE_BRANCH ]]; then
      :
    fi

    (( VCS_STATUS_PUSH_COMMITS_BEHIND )) && res+=" ${clean}<-${VCS_STATUS_PUSH_COMMITS_BEHIND}"
    (( VCS_STATUS_PUSH_COMMITS_AHEAD && !VCS_STATUS_PUSH_COMMITS_BEHIND )) && res+=" "
    (( VCS_STATUS_PUSH_COMMITS_AHEAD  )) && res+="${clean}->${VCS_STATUS_PUSH_COMMITS_AHEAD}"
    [[ -n $VCS_STATUS_ACTION ]] && res+=" ${conflicted}${VCS_STATUS_ACTION}"
    (( VCS_STATUS_NUM_CONFLICTED )) && res+=" ${conflicted}~${VCS_STATUS_NUM_CONFLICTED}"
    (( VCS_STATUS_NUM_STAGED     )) && res+=" ${modified}+${VCS_STATUS_NUM_STAGED}"
    (( VCS_STATUS_NUM_UNSTAGED   )) && res+=" ${modified}!${VCS_STATUS_NUM_UNSTAGED}"
    (( VCS_STATUS_NUM_UNTRACKED  )) && res+=" ${untracked}${(g::)POWERLEVEL9K_VCS_UNTRACKED_ICON}${VCS_STATUS_NUM_UNTRACKED}"
    (( VCS_STATUS_HAS_UNSTAGED == -1 )) && res+=" ${modified}-"

    typeset -g my_git_format=$res
  }

  functions -M my_git_formatter 2>/dev/null
fi

# マシン固有の設定（git管理外）
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
