# tmux-long-task

Run arbitrary long-running tasks in tmux with automatic logging and OpenClaw cron progress reporting every 2 minutes.

## Features

- 🎬 Run long tasks in tmux (Claude Code, Codex, Python, etc.)
- 📝 Automatically log output to file
- ⏰ OpenClaw cron reports progress every 2 minutes
- 🔔 Reports sent directly to Discord channel
- ✅ Auto-detect task completion/errors/stuck states

## Quick Start

### 1. Install

```bash
# Clone the repo
git clone https://github.com/<your-org>/tmux-long-task.git

# Or link to your skills directory
ln -s /path/to/tmux-long-task ~/.openclaw/workspace/skills/tmux-long-task
```

### 2. Usage

```bash
# Start Claude Code long task
./tmux-long-task.sh claude "claude --print --permission-mode bypassPermissions"

# Start Codex long task
./tmux-long-task.sh codex "codex"

# Start Python script
./tmux-long-task.sh scraper "python3 scraper.py"
```

## Command Format

```
./tmux-long-task.sh <session-name> <command> [log-name]
```

| Parameter | Description |
|-----------|-------------|
| session-name | tmux session name |
| command | Command to execute (must be quoted) |
| log-name | Log file name (optional, defaults to session-name) |

## Output Example

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

## File Structure

```
tmux-long-task/
├── SKILL.md              # OpenClaw skill definition
├── README.md             # This file
├── README_CN.md          # 中文版本
├── tmux-long-task.sh     # Main startup script
└── reporter.sh          # Reporter script (called by cron)
```

## Log Location

- **Directory**: `~/openclaw-logs/`
- **Format**: `<session-name>.log`

## Manual Commands

```bash
# Check tmux status
tmux list-sessions

# View real-time output
tmux capture-pane -t <session-name> -p

# View log
tail -f ~/openclaw-logs/<log-name>.log

# Stop task
tmux kill-session -t <session-name>

# Stop cron reporting
openclaw cron rm "tmux-report-<log-name>"
```

## License

MIT
