#!/bin/bash
set -euo pipefail

TIMEOUT_SECONDS="${OPENAI_COMMIT_TIMEOUT_SECONDS:-45}"
DIFF_FILE="$(mktemp /tmp/lazygit-agent-diff.XXXXXX)"
MSG_FILE="$(mktemp /tmp/lazygit-agent-commit-msg.XXXXXX)"
LOG_FILE="$(mktemp /tmp/lazygit-agent-commit-log.XXXXXX)"
TIMEOUT_FLAG_FILE="$(mktemp /tmp/lazygit-agent-timeout.XXXXXX)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cleanup() {
  tput cnorm 2>/dev/null || true
  if [ -n "${WATCHDOG_PID:-}" ]; then
    kill "$WATCHDOG_PID" 2>/dev/null || true
  fi
  rm -f "$DIFF_FILE" "$MSG_FILE" "$LOG_FILE" "$TIMEOUT_FLAG_FILE"
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

start_watchdog() {
  local target_pid=$1
  (
    sleep "$TIMEOUT_SECONDS"
    echo "timeout" > "$TIMEOUT_FLAG_FILE"
    kill -TERM "$target_pid" 2>/dev/null || true
    sleep 2
    kill -KILL "$target_pid" 2>/dev/null || true
  ) &
  WATCHDOG_PID=$!
}

if ! command -v node >/dev/null 2>&1; then
  echo "node コマンドが見つかりません"
  read -r -p "Enterで終了..."
  exit 1
fi

if [ ! -f "$SCRIPT_DIR/agent-commit.mjs" ]; then
  echo "agent-commit.mjs が見つかりません"
  read -r -p "Enterで終了..."
  exit 1
fi

if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "OPENAI_API_KEY が設定されていません"
  read -r -p "Enterで終了..."
  exit 1
fi

if git diff --staged --quiet; then
  echo "ステージされた変更がありません"
  exit 1
fi

git diff --staged > "$DIFF_FILE"

node "$SCRIPT_DIR/agent-commit.mjs" \
  < "$DIFF_FILE" \
  > "$MSG_FILE" 2> "$LOG_FILE" &
API_PID=$!
start_watchdog "$API_PID"

spinner "$API_PID" "AIがコミットメッセージを生成中..."

if ! wait "$API_PID"; then
  echo "エラー: 生成に失敗しました"
  if [ -s "$TIMEOUT_FLAG_FILE" ]; then
    echo
    echo "OpenAI APIが ${TIMEOUT_SECONDS} 秒以内に終了しなかったため中断しました。"
  fi
  if [ -s "$LOG_FILE" ]; then
    echo
    tail -n 20 "$LOG_FILE"
  fi
  read -r -p "Enterで終了..."
  exit 1
fi

if [ ! -s "$MSG_FILE" ]; then
  echo "エラー: コミットメッセージが空でした"
  if [ -s "$LOG_FILE" ]; then
    echo
    tail -n 20 "$LOG_FILE"
  fi
  read -r -p "Enterで終了..."
  exit 1
fi

git commit -e -F "$MSG_FILE"
