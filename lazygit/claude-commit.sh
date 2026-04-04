#!/bin/bash
trap "tput cnorm 2>/dev/null" EXIT INT TERM

spinner() {
  local pid=$1 msg=$2 frames="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏" i=0
  tput civis 2>/dev/null
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r${frames:$((i % ${#frames})):1} $msg"
    sleep 0.1
    ((i++))
  done
  tput cnorm 2>/dev/null
  printf "\r"
}

if [ -z "$(git diff --staged)" ]; then
  echo "ステージされた変更がありません"
  exit 1
fi

git diff --staged > /tmp/claude_diff.txt
claude -p "以下のdiffからコミットメッセージを生成してください。Conventional Commits形式で、本文は日本語で簡潔に。コミットメッセージのみを出力してください。コードブロックで囲わないでください。" < /tmp/claude_diff.txt > /tmp/claude_commit_msg.txt &
CLAUDE_PID=$!
spinner $CLAUDE_PID "Claudeがコミットメッセージを生成中..."
wait $CLAUDE_PID || { echo "エラー: 生成に失敗しました"; read -p "Enterで終了..."; exit 1; }
git commit -e -F /tmp/claude_commit_msg.txt
