---
name: tmux-long-task
description: 在 tmux 中运行任意长任务，自动记录日志并通过 OpenClaw cron 每 2 分钟汇报进度。适用于 Claude Code、Codex、Python 脚本等长任务。
---

# tmux 长任务执行 + OpenClaw 日志监控

## 概述

本 skill 提供通用的 tmux 长任务执行方案指定 tmux session：
1. 在 中运行任意长任务
2. 将输出持续记录到日志文件
3. 使用 **OpenClaw cron** 每 2 分钟自动汇报进度到当前频道

## 特点

- **OpenClaw cron**: 定时任务由 OpenClaw 管理，汇报直接发送到 Discord 频道
- **自动检测**: 检测任务完成/错误/卡住状态
- **增量汇报**: 只汇报新增的日志内容

## 使用方法

### 基本命令格式

```
tmux-long-task <session-name> <command> [log-name]
```

**参数说明：**
- `session-name`: tmux session 名称
- `command`: 要执行的命令（需要用引号包裹）
- `log-name`（可选）: 日志文件名，默认使用 session-name

### 示例

```bash
# 启动 Claude Code 长任务
tmux-long-task claude "claude --print --permission-mode bypassPermissions"

# 启动 Codex 长任务
tmux-long-task codex "codex"

# 启动 Python 脚本任务
tmux-long-task scraper "python3 scraper.py"

# 启动自定义任务
tmux-long-task mytask "some-command" my-log-name
```

## 工作流程

### A. tmux 任务启动

1. 如果 session 已存在，先终止
2. 创建新 session 并执行命令
3. 使用 `script` 命令同时显示和记录输出

### B. 日志落盘

- **目录**: `~/openclaw-logs/`
- **文件**: `~/openclaw-logs/<log-name>.log`

### C. 定时汇报 (OpenClaw cron)

1. 使用 `openclaw cron add` 创建定时任务
2. 每 2 分钟触发一个 isolated agent
3. agent 读取日志文件并输出汇报
4. 汇报直接发送到当前 Discord 频道
5. 任务完成后自动删除 cron job

### D. 输出内容

启动时会告知：
1. ✅ tmux 任务是否已成功启动
2. 📄 日志文件路径
3. ⏰ cron job 是否已创建成功

## 脚本位置

| 脚本 | 路径 |
|-----|------|
| 启动脚本 | `~/.openclaw/workspace/skills/claude-tmux/scripts/tmux-long-task.sh` |

## 手动控制命令

### 查看 tmux 状态
```bash
tmux list-sessions
tmux capture-pane -t <session-name> -p
```

### 查看日志
```bash
tail -f ~/openclaw-logs/<log-name>.log
```

### 停止任务
```bash
tmux kill-session -t <session-name>
```

### 停止 cron 汇报
```bash
openclaw cron rm "tmux-report-<log-name>"
```

### 查看 cron 任务
```bash
openclaw cron list
```

## 状态检测

汇报时会自动检测：
- ✅ 完成: `complete`, `done`, `finished`, `success`, `sautéed for`
- ⚠️ 错误: `error`, `failed`, `exception`, `crash`
- ⏸️ 卡住: 长时间无输出
