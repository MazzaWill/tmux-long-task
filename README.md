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
Creating tmux session: claude
✅ tmux task started successfully
📄 Log file: /Users/xxx/openclaw-logs/claude.log
⏰ Waiting for log output...
✅ Cron job created (reporting every 2 minutes via OpenClaw)

=== Startup Complete ===
Session: claude
Log: /Users/xxx/openclaw-logs/claude.log
View real-time output: tmux capture-pane -t claude -p

💡 Task progress will be reported to this channel every 2 minutes
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
