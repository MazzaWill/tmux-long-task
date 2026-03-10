#!/bin/bash

# reporter.sh: 定时汇报 tmux 任务进度 (基于 capture-pane 快照版)
# 用法: reporter.sh <log-name>
# 由 OpenClaw cron 每 2 分钟调用

LOG_NAME="$1"
if [ -z "$LOG_NAME" ]; then
    echo "❌ 用法: reporter.sh <log-name>"
    exit 1
fi

SESSION_NAME="$LOG_NAME"
SNAPSHOT_DIR="$HOME/openclaw-logs/snapshots"
CURRENT_SNAPSHOT="$SNAPSHOT_DIR/$LOG_NAME.current"
LAST_SNAPSHOT="$SNAPSHOT_DIR/$LOG_NAME.last"

# 检查快照目录是否存在
if [ ! -d "$SNAPSHOT_DIR" ]; then
    echo "📋 快照目录不存在，任务可能未启动"
    exit 0
fi

# 检查 tmux session 是否还在运行
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    TASK_STATUS="⚠️ tmux session 已结束"
    
    # 任务结束，清理 cron job
    openclaw cron rm "tmux-report-$LOG_NAME" 2>/dev/null || true
    
    echo ""
    echo "=== 📊 $LOG_NAME 任务汇报 ==="
    echo "状态: $TASK_STATUS"
    echo ""
    echo "🎉 任务已完成！"
    exit 0
fi

# 抓取当前 tmux pane 内容
tmux capture-pane -t "$SESSION_NAME" -p -S -200 > "$CURRENT_SNAPSHOT" 2>/dev/null || true

# 检查是否有新内容
if [ ! -f "$LAST_SNAPSHOT" ]; then
    # 首次运行，保存快照
    cp "$CURRENT_SNAPSHOT" "$LAST_SNAPSHOT"
    echo "📸 初始快照已保存"
    exit 0
fi

# 去除 ANSI 转义序列的函数
strip_ansi() {
    sed -E 's/\x1b\[[0-9;]*[a-zA-Z]//g' | sed -E 's/\x1b\][0-9;]*[^\x1b]*\x1b\\//g' | sed -E 's/\r$//'
}

# 去除 spinner 和噪音行
clean_content() {
    grep -v -E '^(Running\.\.\.|ctrl\+[a-z]|Pouncing|Spinning|✻|✽|✢|✳|·|❯|· Spinning|· Cogitated|· ⏵⏵)' | \
    grep -v -E '^[[:space:]]*$' | \
    sed '/^$/d'
}

# 获取新旧内容
CONTENT_CURRENT=$(cat "$CURRENT_SNAPSHOT" | strip_ansi | clean_content)
CONTENT_LAST=$(cat "$LAST_SNAPSHOT" | strip_ansi | clean_content)

# 简单对比：如果内容完全相同，认为没有新进展
if [ "$CONTENT_CURRENT" = "$CONTENT_LAST" ]; then
    # 检查是否卡住（session 还在运行但内容没变化）
    echo ""
    echo "⏳ [$(date '+%H:%M:%S')] $SESSION_NAME 运行中，过去 2 分钟没有明显新进展"
    echo "（任务可能正在执行耗时操作，如网络请求、页面加载等）"
    exit 0
fi

# 有新内容，提取新增的行（简单方案：取最后 30 行作为"新增"）
NEW_CONTENT=$(echo "$CONTENT_CURRENT" | tail -30)

# 更新快照
cp "$CURRENT_SNAPSHOT" "$LAST_SNAPSHOT"

# 检测任务状态
TASK_STATUS="🔄 进行中"
SESSION_RUNNING="（运行中）"

# 检查是否有错误关键词
if echo "$NEW_CONTENT" | grep -qiE "error|failed|exception|crash|killed"; then
    TASK_STATUS="⚠️ 有错误"
fi

# 检查是否已完成
if echo "$NEW_CONTENT" | grep -qiE "complete|done|finished|success|sautéed for|已处理完毕"; then
    TASK_STATUS="✅ 已完成"
    # 任务完成后，停止 cron job
    openclaw cron rm "tmux-report-$LOG_NAME" 2>/dev/null || true
    SESSION_RUNNING="（已结束）"
fi

# 输出汇报
echo ""
echo "=== 📊 $SESSION_NAME 任务汇报 $SESSION_RUNNING ==="
echo "状态: $TASK_STATUS"
echo ""
echo "📝 最新输出 (最后 30 行):"
echo "---"
echo "$NEW_CONTENT"
echo "---"

if [ "$TASK_STATUS" = "✅ 已完成" ]; then
    echo ""
    echo "🎉 任务已完成！"
    echo "📸 快照目录: $SNAPSHOT_DIR"
fi
