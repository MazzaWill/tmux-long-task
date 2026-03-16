#!/bin/bash

# reporter.sh: 输出一次 tmux pane 监控摘要
# 用法: reporter.sh <log-name> [session-name]

set -euo pipefail

LOG_NAME="${1:-}"
SESSION_NAME="${2:-${1:-}}"

if [ -z "$LOG_NAME" ]; then
    echo "❌ 用法: reporter.sh <log-name> [session-name]"
    exit 1
fi

SNAPSHOT_DIR="$HOME/openclaw-logs/snapshots"
CURRENT_SNAPSHOT="$SNAPSHOT_DIR/$LOG_NAME.current"
LAST_SNAPSHOT="$SNAPSHOT_DIR/$LOG_NAME.last"

strip_ansi() {
    sed -E 's/$//; s//
/g' | sed -E 's/\x1b\[[0-9;?]*[ -\/]*[@-~]//g'
}

clean_content() {
    grep -v -E '^(Running\.\.\.|ctrl\+[a-z]|Pouncing|Spinning|✻|✽|✢|✳|·|❯|· Spinning|· Cogitated|· ⏵⏵)' | \
    grep -v -E '^[[:space:]]*$' || true
}

if [ ! -d "$SNAPSHOT_DIR" ]; then
    echo "📋 快照目录不存在，任务可能未启动"
    exit 0
fi

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux capture-pane -t "$SESSION_NAME" -p -S -200 > "$CURRENT_SNAPSHOT" 2>/dev/null || true
else
    echo "=== 📊 $SESSION_NAME 任务汇报 ==="
    echo "状态: 已结束（tmux session 不存在）"
    if [ -f "$CURRENT_SNAPSHOT" ]; then
        echo
        echo "📝 最后快照 (最后 20 行):"
        echo "---"
        cat "$CURRENT_SNAPSHOT" | strip_ansi | clean_content | tail -20
        echo "---"
    fi
    exit 0
fi

if [ ! -f "$LAST_SNAPSHOT" ]; then
    cp "$CURRENT_SNAPSHOT" "$LAST_SNAPSHOT"
    echo "📸 初始快照已保存"
    exit 0
fi

CONTENT_CURRENT=$(cat "$CURRENT_SNAPSHOT" | strip_ansi | clean_content)
CONTENT_LAST=$(cat "$LAST_SNAPSHOT" | strip_ansi | clean_content)

if [ "$CONTENT_CURRENT" = "$CONTENT_LAST" ]; then
    echo "⏳ $SESSION_NAME 仍在运行，过去 2 分钟无明显新进展"
    exit 0
fi

cp "$CURRENT_SNAPSHOT" "$LAST_SNAPSHOT"
NEW_CONTENT=$(echo "$CONTENT_CURRENT" | tail -20)

STATUS="🔄 进行中"
if echo "$NEW_CONTENT" | grep -qiE 'fatal|failed to|cannot find|permission denied|ENOENT|Traceback|Exception'; then
    STATUS="⚠️ 有错误"
fi
if echo "$NEW_CONTENT" | grep -qiE 'workspace %$|%$|[$#] $|所有步骤完成|任务完成|已完成|complete|finished|done'; then
    STATUS="✅ 可能已结束"
fi

echo "=== 📊 $SESSION_NAME 任务汇报 ==="
echo "状态: $STATUS"
echo
echo "📝 最新输出 (最后 20 行):"
echo "---"
echo "$NEW_CONTENT"
echo "---"
