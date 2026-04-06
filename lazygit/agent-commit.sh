#!/bin/bash
set -euo pipefail

DIFF_FILE="$(mktemp /tmp/lazygit-agent-diff.XXXXXX)"
MSG_FILE="$(mktemp /tmp/lazygit-agent-commit-msg.XXXXXX)"
LOG_FILE="$(mktemp /tmp/lazygit-agent-commit-log.XXXXXX)"

cleanup() {
  tput cnorm 2>/dev/null || true
  rm -f "$DIFF_FILE" "$MSG_FILE" "$LOG_FILE"
}

trap cleanup EXIT INT TERM

spinner() {
  local pid=$1 msg=$2 frames=("=" "*" "-") i=0
  tput civis 2>/dev/null || true
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r%s %s" "${frames[$((i % ${#frames[@]}))]}" "$msg"
    sleep 0.08
    ((i++))
  done
  tput cnorm 2>/dev/null || true
  printf "\r"
}

if ! command -v codex >/dev/null 2>&1; then
  echo "codex コマンドが見つかりません"
  read -r -p "Enterで終了..."
  exit 1
fi

if git diff --staged --quiet; then
  echo "ステージされた変更がありません"
  exit 1
fi

git diff --staged > "$DIFF_FILE"

codex exec \
  --ephemeral \
  --color never \
  -s read-only \
  -o "$MSG_FILE" \
  "以下のdiffからコミットメッセージを生成してください。Conventional Commits形式で、本文は日本語で簡潔に。コミットメッセージのみを出力してください。コードブロックで囲わないでください。" \
  < "$DIFF_FILE" \
  > "$LOG_FILE" 2>&1 &
CODEX_PID=$!

spinner "$CODEX_PID" "Codexがコミットメッセージを生成中..."

if ! wait "$CODEX_PID"; then
  echo "エラー: 生成に失敗しました"
  if [ -s "$LOG_FILE" ]; then
    echo
    tail -n 20 "$LOG_FILE"
  fi
  read -r -p "Enterで終了..."
  exit 1
fi

git commit -e -F "$MSG_FILE"
