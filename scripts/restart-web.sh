#!/usr/bin/env bash
set -e
WORKTREE=~/development/projects/valgate-monorepo/apps/web
PIDFILE=/tmp/valgate-web.pid

echo "=== Valgate Web Restart ==="

# Kill existing server if running
if [ -f "$PIDFILE" ]; then
  OLD_PID=$(cat "$PIDFILE" 2>/dev/null) || true
  if kill -0 "$OLD_PID" 2>/dev/null; then
    echo "Killing existing server (PID $OLD_PID)..."
    kill "$OLD_PID" 2>/dev/null || true
    sleep 2
  fi
fi

# Start new server
echo "Starting server from $WORKTREE..."
cd "$WORKTREE"
node node_modules/.bin/next start > /tmp/next-web-stdout.log 2> /tmp/next-web-stderr.log &
NEW_PID=$!
echo "$NEW_PID" > "$PIDFILE"
echo "Server started (PID $NEW_PID)"
echo "Logs: /tmp/next-web-stdout.log /tmp/next-web-stderr.log"
echo "Test: curl https://srv1839855.tail98085b.ts.net/app"
