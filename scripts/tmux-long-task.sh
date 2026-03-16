#!/bin/bash

# tmux-long-task: 在 tmux 中直接启动长任务，并初始化 pane 快照
# 用法: tmux-long-task <session-name> <command> [log-name]

set -euo pipefail

SESSION_NAME="${1:-}"
COMMAND="${2:-}"
LOG_NAME="${3:-${1:-}}"

if [ -z "$SESSION_NAME" ] || [ -z "$COMMAND" ]; then
    echo "用法: tmux-long-task <session-name> <command> [log-name]"
    exit 1
fi

SNAPSHOT_DIR="$HOME/openclaw-logs/snapshots"
CURRENT_SNAPSHOT="$SNAPSHOT_DIR/$LOG_NAME.current"
LAST_SNAPSHOT="$SNAPSHOT_DIR/$LOG_NAME.last"

mkdir -p "$SNAPSHOT_DIR"

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Session '$SESSION_NAME' 已存在，终止旧 session..."
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
    sleep 1
fi

rm -f "$CURRENT_SNAPSHOT" "$LAST_SNAPSHOT"

echo "创建 tmux session: $SESSION_NAME"
tmux new-session -d -s "$SESSION_NAME"
tmux send-keys -t "$SESSION_NAME" "$COMMAND" C-m
sleep 2

if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "❌ tmux 任务启动失败"
    exit 1
fi

tmux capture-pane -t "$SESSION_NAME" -p -S -200 > "$CURRENT_SNAPSHOT" 2>/dev/null || true
cp "$CURRENT_SNAPSHOT" "$LAST_SNAPSHOT" 2>/dev/null || true

echo "✅ tmux 任务已成功启动"
echo "Session: $SESSION_NAME"
echo "Log name: $LOG_NAME"
echo "快照目录: $SNAPSHOT_DIR"
echo "实时查看: tmux capture-pane -t $SESSION_NAME -p -S -200"
echo "说明: 该脚本只负责启动 + 初始化快照；每 2 分钟汇报请用 OpenClaw cron/tool 单独创建。"
