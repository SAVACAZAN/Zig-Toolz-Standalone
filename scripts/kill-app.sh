#!/bin/bash
# Kill all running processes for ZigTrade HTMX Edition (Linux/Mac)

echo "🛑 Killing all app processes..."

# Kill zig build/run processes
pkill -9 -f "zig build run" 2>/dev/null
pkill -9 -f "zig-exchange-server" 2>/dev/null

sleep 2

# Verify processes are killed
REMAINING=$(ps aux | grep -E "zig" | grep -v grep | wc -l)

if [ "$REMAINING" -eq 0 ]; then
  echo "✅ All app processes killed successfully"
  exit 0
else
  echo "⚠️  Still $REMAINING zig processes running, forcing harder kill..."
  pkill -9 zig 2>/dev/null
  sleep 1
  echo "✅ Force kill complete"
  exit 0
fi
