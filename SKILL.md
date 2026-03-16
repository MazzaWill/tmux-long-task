---
name: tmux-long-task
description: 在 tmux 中直接启动 Claude Code CLI、Codex、Python 脚本等长任务，并基于 tmux capture-pane 做快照监控；适用于“在 tmux 里跑命令，然后每 2 分钟汇报一次真实 pane 日志”的场景。用户明确要求 tmux 长任务、固定节奏进度汇报、持续监控 pane 输出时使用。
---

# tmux 长任务 SOP

按下面流程执行，不要套额外 runner。

## 标准 SOP

1. **直接在 tmux 里启动真实命令**
   - 用 `tmux new-session -d -s <session>` 创建 session。
   - 用 `tmux send-keys` 把真实命令送进去执行。
   - 不要把命令再包一层 `job_runner.sh`。
   - 对 Claude Code CLI，默认就是直接跑 `claude -p ...`。

2. **初始化快照**
   - 快照目录：`~/openclaw-logs/snapshots/`
   - 用 `tmux capture-pane -t <session> -p -S -200` 抓取初始 pane 内容。
   - 保存为 `<log-name>.current` 和 `<log-name>.last`。

3. **每 2 分钟汇报一次**
   - 用 OpenClaw `cron`（不是 shell 里瞎猜 CLI 参数）创建每 2 分钟任务。
   - 监控逻辑：
     - 检查 tmux session 是否仍存在
     - 抓 pane 快照
     - 对比上次快照
     - 过滤空行、spinner、ANSI 噪音
     - 给当前线程发送简短进度
   - 如果 2 分钟内没明显变化，就明确说“仍在运行，过去 2 分钟无明显新进展”。

4. **完成判定**
   - 优先看 tmux pane 是否已经回到 shell prompt，或 session 已结束。
   - 不要只靠 exit code 宣布业务成功。
   - 完成时汇报最后一段有意义输出。

5. **收尾**
   - 用户要求清理时，再删除 tmux session 和监控 cron。
   - 默认不要抢着自动删，避免用户还想回看 pane。

## 启动命令模板

```bash
tmux new-session -d -s "$SESSION"
tmux send-keys -t "$SESSION" "$COMMAND" C-m
```

Claude Code CLI 示例：

```bash
SESSION="claude-task"
COMMAND="claude -p --model sonnet '你的 prompt'"
tmux new-session -d -s "$SESSION"
tmux send-keys -t "$SESSION" "$COMMAND" C-m
```

## 监控要点

### 查看 session 是否还活着

```bash
tmux has-session -t "$SESSION"
```

### 抓当前 pane 内容

```bash
tmux capture-pane -t "$SESSION" -p -S -200
```

### 判断任务是否结束

出现下面任一情况即可认为 CLI 任务已结束：
- pane 已回到 shell prompt
- tmux session 已不存在
- pane 中明确出现任务完成总结，随后回到提示符

## 汇报格式

默认发简洁中文：

- **有新进展**：贴最后 10-20 行有意义的新输出
- **无新进展**：`仍在运行，过去 2 分钟无明显新进展`
- **已结束**：说明任务结束，并附最后关键输出摘要
- **有错误**：直接贴关键错误行

## 禁止事项

- 不要用 `job_runner.sh` 再包一层
- 不要把“进程退出码 0”当成“用户目标成功”
- 不要写死 Discord 频道 id
- 不要依赖 `script` 命令抓 TUI 日志
- 不要在没确认 pane 内容的情况下说“完成了”

## bundled scripts

- `scripts/tmux-long-task.sh`：仅负责启动 tmux session + 初始化快照；不负责自己创建 cron
- `scripts/reporter.sh`：只负责输出一次监控摘要，适合被 cron 或人工调用
