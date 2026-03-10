# tmux-long-task

在 tmux 中运行任意长任务，自动记录日志并通过 OpenClaw cron 每 2 分钟汇报进度。

## 功能

- 🎬 在 tmux 中运行长任务（Claude Code、Codex、Python 等）
- 📝 自动将输出记录到日志文件
- ⏰ OpenClaw cron 每 2 分钟自动汇报进度
- 🔔 汇报直接发送到 Discord 频道
- ✅ 自动检测任务完成/错误/卡住状态

## 快速开始

### 1. 安装

```bash
# 克隆仓库
git clone https://github.com/<your-org>/tmux-long-task.git

# 或者添加到你的 skills 目录
ln -s /path/to/tmux-long-task ~/.openclaw/workspace/skills/tmux-long-task
```

### 2. 使用

```bash
# 启动 Claude Code 长任务
./tmux-long-task.sh claude "claude --print --permission-mode bypassPermissions"

# 启动 Codex 长任务
./tmux-long-task.sh codex "codex"

# 启动 Python 脚本
./tmux-long-task.sh scraper "python3 scraper.py"
```

## 命令格式

```
./tmux-long-task.sh <session-name> <command> [log-name]
```

| 参数 | 说明 |
|-----|------|
| session-name | tmux session 名称 |
| command | 要执行的命令（需用引号包裹） |
| log-name | 日志文件名（可选，默认等于 session-name） |

## 输出示例

```
创建 tmux session: claude
✅ tmux 任务已成功启动
📄 日志文件: /Users/xxx/openclaw-logs/claude.log
⏰ 等待日志输出...
✅ Cron job 已创建成功 (每2分钟通过 OpenClaw 汇报)

=== 启动完成 ===
Session: claude
日志: /Users/xxx/openclaw-logs/claude.log
查看实时输出: tmux capture-pane -t claude -p

💡 任务进度会每 2 分钟自动汇报到这个频道
```

## 文件结构

```
tmux-long-task/
├── SKILL.md              # OpenClaw skill 说明
├── README.md             # 本文件
├── tmux-long-task.sh     # 主启动脚本
└── reporter.sh          # 汇报脚本（由 cron 调用）
```

## 日志位置

- **目录**: `~/openclaw-logs/`
- **格式**: `<session-name>.log`

## 手动命令

```bash
# 查看 tmux 状态
tmux list-sessions

# 查看实时输出
tmux capture-pane -t <session-name> -p

# 查看日志
tail -f ~/openclaw-logs/<log-name>.log

# 停止任务
tmux kill-session -t <session-name>

# 停止 cron 汇报
openclaw cron rm "tmux-report-<log-name>"
```

## License

MIT
