---
description: フロントエンドとバックエンドのサーバーを停止します
---

ポート 3000(フロントエンド)と 8001(バックエンド)で動いているプロセスを見つけて停止してください。

- macOS/Linux: `lsof -ti:3000,8001 | xargs kill 2>/dev/null || true`
- Windows: `netstat -aon | findstr :PORT` で PID を調べてから `taskkill /F /PID <pid>`
