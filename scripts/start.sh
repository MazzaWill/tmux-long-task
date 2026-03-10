#!/bin/bash
# Start Claude Code in tmux session

SESSION_NAME="claude"

# Check if session exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Session '$SESSION_NAME' already exists. Attaching..."
    tmux attach -t "$SESSION_NAME"
else
    echo "Creating new session '$SESSION_NAME'..."
    tmux new-session -d -s "$SESSION_NAME" "claude"
    tmux attach -t "$SESSION_NAME"
fi
