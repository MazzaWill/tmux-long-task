---
name: tmux-long-task
description: 在 tmux 中运行任意长任务，自动快照监控并通过 OpenClaw cron 每 2 分钟汇报进度。适用于 Claude Code、Codex、Python 脚本等长任务。
---

# tmux 长任务执行 + 快照监控

## 概述

本 skill 提供通用的 tmux 长任务执行方案：
1. 在指定 tmux session 中运行任意长任务
2. 使用 `tmux capture-pane` 持续抓取快照
3. 通过 **OpenClaw cron** 每 2 分钟对比快照并汇报进度

## 特点

- **无日志落盘**：不依赖 `script` 命令（对 TUI 支持不好）
- **快照对比**：每次 cron 触发时抓取 pane 内容，与上次对比
- **智能过滤**：去除 ANSI 转义、spinner、噪音行
- **自动检测**：检测任务完成/错误/卡住状态

## 使用方法

### 基本命令格式

```
tmux-long-task <session-name> <command> [log-name]
```

### 示例

```bash
# 启动 Claude Code 长任务
tmux-long-task claude "claude --print --permission-mode bypassPermissions"

# 启动 Codex 长任务
tmux-long-task codex "codex"

# 启动 Python 脚本
tmux-long-task scraper "python3 scraper.py"
```

## 工作流程

### A. tmux 任务启动

1. 如果 session 已存在，先终止
2. 创建新 session 并执行命令（直接运行，不使用 script）
3. 初始化快照

### B. 快照监控

- **快照目录**: `~/openclaw-logs/snapshots/`
- **文件**: `<log-name>.current`, `<log-name>.last`
- 每次 cron 触发时抓取 pane 内容（-S -200 保留 200 行 scrollback）

### C. 定时汇报 (OpenClaw cron)

1. 使用 `openclaw cron add` 创建定时任务
2. 每 2 分钟触发 isolated agent
3. agent 执行 reporter.sh：
   - 用 `tmux capture-pane` 抓取当前 pane 内容
   - 与上次快照对比
   - 去除 ANSI、spinner、噪音
   - 输出新增内容
4. 任务完成后自动删除 cron job

## 修改的文件

| 文件 | 说明 |
|-----|------|
| `scripts/tmux-long-task.sh` | 主启动脚本，改用直接执行命令 |
| `scripts/reporter.sh` | 汇报脚本，改用 capture-pane 快照对比 |

## 手动命令

```bash
# 查看 tmux 状态
tmux list-sessions

# 查看实时输出
tmux capture-pane -t <session-name> -p

# 查看快照目录
ls -la ~/openclaw-logs/snapshots/

# 停止任务
tmux kill-session -t <session-name>

# 停止 cron 汇报
openclaw cron rm "tmux-report-<log-name>"
```

## 状态检测

汇报时会自动检测：
- ✅ 完成: `complete`, `done`, `finished`, `success`, `sautéed for`, `已处理完毕`
- ⚠️ 错误: `error`, `failed`, `exception`, `crash`
- ⏸️ 卡住: 长时间无输出（会提示"过去 2 分钟没有明显新进展"）
