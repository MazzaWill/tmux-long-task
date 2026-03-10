#!/bin/bash

# tmux-long-task: 在 tmux 中运行长任务，自动记录日志并定时汇报
# 用法: tmux-long-task <session-name> <command> [log-name]

set -e

SESSION_NAME="$1"
COMMAND="$2"
LOG_NAME="${3:-$1}"

if [ -z "$SESSION_NAME" ] || [ -z "$COMMAND" ]; then
    echo "用法: tmux-long-task <session-name> <command> [log-name>"
    exit 1
fi

LOG_DIR="$HOME/openclaw-logs"
LOG_FILE="$LOG_DIR/$LOG_NAME.log"
MARKER_FILE="$LOG_DIR/$LOG_NAME.lastline"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 如果 session 已存在，先杀掉
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Session '$SESSION_NAME' 已存在，终止旧 session..."
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
    sleep 1
fi

# 清理旧的 cron job（如果存在）
openclaw cron rm "tmux-report-$LOG_NAME" 2>/dev/null || true

# 创建新 session 并启动命令，使用 script 命令记录输出
echo "创建 tmux session: $SESSION_NAME"
tmux new-session -d -s "$SESSION_NAME"

# 使用 script 命令将输出同时显示和记录到日志
tmux send-keys -t "$SESSION_NAME" "script -q -a '$LOG_FILE' $COMMAND" C-m

# 等待任务启动
sleep 2

# 检查 session 是否在运行
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "✅ tmux 任务已成功启动"
else
    echo "❌ tmux 任务启动失败"
    exit 1
fi

echo "📄 日志文件: $LOG_FILE"
echo "⏰ 等待日志输出..."

# 初始化上次汇报行数
echo "0" > "$MARKER_FILE"

# 添加 OpenClaw cron job（每 2 分钟汇报）
# cron 会触发 subagent 读取日志并汇报
echo "添加 OpenClaw cron job..."

openclaw cron add \
    --name "tmux-report-$LOG_NAME" \
    --every "2m" \
    --message "读取日志文件 $LOG_FILE 的最后 100 行，检测任务状态（是否完成/有错误/卡住），输出汇报。日志目录: $HOME/openclaw-logs/" \
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
echo "日志: $LOG_FILE"
echo "查看实时输出: tmux capture-pane -t $SESSION_NAME -p"
echo ""
echo "💡 任务进度会每 2 分钟自动汇报到这个频道"
