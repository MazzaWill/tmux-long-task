#!/bin/bash

# reporter.sh: 定时汇报 tmux 任务进度 (OpenClaw cron 版本)
# 用法: reporter.sh <log-name>
# 由 OpenClaw cron 每 2 分钟调用

LOG_NAME="$1"
if [ -z "$LOG_NAME" ]; then
    echo "❌ 用法: reporter.sh <log-name>"
    exit 1
fi

LOG_DIR="$HOME/openclaw-logs"
LOG_FILE="$LOG_DIR/$LOG_NAME.log"
MARKER_FILE="$LOG_DIR/$LOG_NAME.lastline"

# 检查日志文件是否存在
if [ ! -f "$LOG_FILE" ]; then
    echo "📋 任务状态: 等待日志输出..."
    exit 0
fi

# 获取日志文件总行数
TOTAL_LINES=$(wc -l < "$LOG_FILE")

# 获取上次汇报的行数
if [ -f "$MARKER_FILE" ]; then
    LAST_LINE=$(cat "$MARKER_FILE")
else
    LAST_LINE=0
fi

# 计算新增行数
if [ "$TOTAL_LINES" -le "$LAST_LINE" ]; then
    # 没有新增内容
    echo "⏳ [$(date '+%H:%M:%S')] 运行中，等待输出..."
    exit 0
fi

# 读取新增内容
NEW_CONTENT=$(tail -n "$TOTAL_LINES" "$LOG_FILE" | tail -n +$((LAST_LINE + 1)))
NEW_LINES=$((TOTAL_LINES - LAST_LINE))

# 更新上次汇报行数
echo "$TOTAL_LINES" > "$MARKER_FILE"

# 检测任务状态
TASK_STATUS="🔄 进行中"
SESSION_RUNNING=""

# 检查 tmux session 是否还在运行
if tmux has-session -t "$LOG_NAME" 2>/dev/null; then
    SESSION_RUNNING="（运行中）"
else
    SESSION_RUNNING="（已结束）"
fi

# 检查是否有错误关键词
if echo "$NEW_CONTENT" | grep -qiE "error|failed|exception|crash"; then
    TASK_STATUS="⚠️ 有错误"
fi

_STATUS="⚠# 检查是否已完成
if echo "$NEW_CONTENT" | grep -qiE "complete|done|finished|success|sautéed for"; then
    TASK_STATUS="✅ 已完成"
    
    # 任务完成后，停止 cron job
    echo "🛑 任务完成，停止 cron job..."
    openclaw cron rm "tmux-report-$LOG_NAME" 2>/dev/null || true
fi

# 输出汇报（OpenClaw cron 会把这个输出发送到频道）
echo ""
echo "=== 📊 $LOG_NAME 任务汇报 $SESSION_RUNNING ==="
echo "状态: $TASK_STATUS"
echo ""

# 只输出最后 100 行新增内容
echo "📝 最新输出 (新增 $NEW_LINES 行):"
echo "---"
echo "$NEW_CONTENT" | tail -100
echo "---"

if [ "$TASK_STATUS" = "✅ 已完成" ]; then
    echo ""
    echo "🎉 任务已完成！"
    echo "📄 完整日志: $LOG_FILE"
fi
