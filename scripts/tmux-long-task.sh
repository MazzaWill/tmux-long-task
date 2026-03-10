#!/bin/bash

# tmux-long-task: 在 tmux 中运行长任务，自动记录快照并定时汇报
# 用法: tmux-long-task <session-name> <command> [log-name]

set -e

SESSION_NAME="$1"
COMMAND="$2"
LOG_NAME="${3:-$1}"

if [ -z "$SESSION_NAME" ] || [ -z "$COMMAND" ]; then
    echo "用法: tmux-long-task <session-name> <command> [log-name>"
    exit 1
fi

SNAPSHOT_DIR="$HOME/openclaw-logs/snapshots"
CURRENT_SNAPSHOT="$SNAPSHOT_DIR/$LOG_NAME.current"
LAST_SNAPSHOT="$SNAPSHOT_DIR/$LOG_NAME.last"

# 创建快照目录
mkdir -p "$SNAPSHOT_DIR"

# 如果 session 已存在，先杀掉
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Session '$SESSION_NAME' 已存在，终止旧 session..."
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
    sleep 1
fi

# 清理旧的 cron job（如果存在）
openclaw cron rm "tmux-report-$LOG_NAME" 2>/dev/null || true

# 清理旧的快照
rm -f "$CURRENT_SNAPSHOT" "$LAST_SNAPSHOT"

# 创建新 session 并启动命令（不使用 script，直接运行）
echo "创建 tmux session: $SESSION_NAME"
tmux new-session -d -s "$SESSION_NAME"

# 直接发送命令到 tmux，不使用 script 包裹
tmux send-keys -t "$SESSION_NAME" "$COMMAND" C-m

# 等待任务启动
sleep 2

# 检查 session 是否在运行
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "✅ tmux 任务已成功启动"
else
    echo "❌ tmux 任务启动失败"
    exit 1
fi

echo "📸 快照目录: $SNAPSHOT_DIR"
echo "⏰ 等待任务输出..."

# 初始化：创建初始快照
tmux capture-pane -t "$SESSION_NAME" -p -S -200 > "$CURRENT_SNAPSHOT" 2>/dev/null || true
cp "$CURRENT_SNAPSHOT" "$LAST_SNAPSHOT"

# 添加 OpenClaw cron job（每 2 分钟汇报）
# cron 会触发 isolated agent 执行 reporter.sh
REPORTER_PATH="$(cd "$(dirname "$0")" && pwd)/reporter.sh"
echo "添加 OpenClaw cron job..."

openclaw cron add \
    --name "tmux-report-$LOG_NAME" \
    --every "2m" \
    --message "执行 $REPORTER_PATH $LOG_NAME。session: $SESSION_NAME, 快照目录: $SNAPSHOT_DIR" \
    --session "isolated" \
    --timeout-seconds 60 \
    --description "tmux 任务进度汇报: $LOG_NAME" \
    --to "channel:1480811886361710663" \
    --announce

# 检查 cron job 是否创建成功
if openclaw cron list 2>/dev/null | grep -q "tmux-report-$LOG_NAME"; then
    echo "✅ Cron job 已创建成功 (每2分钟通过 OpenClaw 汇报)"
else
    echo "⚠️ Cron job 可能创建失败，请检查"
fi

echo ""
echo "=== 启动完成 ==="
echo "Session: $SESSION_NAME"
echo "快照目录: $SNAPSHOT_DIR"
echo "查看实时输出: tmux capture-pane -t $SESSION_NAME -p"
echo ""
echo "💡 任务进度会每 2 分钟自动汇报到这个频道"
