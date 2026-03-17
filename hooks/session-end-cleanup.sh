#!/usr/bin/env bash
# Kill leaked MCP stdio processes from previous sessions
pkill -f "dbhub" 2>/dev/null || true
pkill -f "figma-developer-mcp" 2>/dev/null || true
pkill -f "mcp-server-sequential-thinking" 2>/dev/null || true
pkill -f "mcp-atlassian" 2>/dev/null || true
pkill -f "jira-cache-server/server.py" 2>/dev/null || true
echo '{"ok": true}'
