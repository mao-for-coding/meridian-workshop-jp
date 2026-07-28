#!/bin/bash

# 工場在庫管理システム - 停止スクリプト
# バックエンドとフロントエンドの両サーバーを停止します

set -e  # エラー時に終了

# 出力用のカラー定義
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # 色なし

echo -e "${YELLOW}工場在庫管理システムを停止しています...${NC}\n"

# PID ファイルの有無を確認
if [ -f /tmp/inventory-backend.pid ]; then
    BACKEND_PID=$(cat /tmp/inventory-backend.pid)
    if kill -0 $BACKEND_PID 2>/dev/null; then
        echo -e "${YELLOW}バックエンドサーバーを停止しています (PID: $BACKEND_PID)${NC}"
        kill $BACKEND_PID
    fi
    rm -f /tmp/inventory-backend.pid
fi

if [ -f /tmp/inventory-frontend.pid ]; then
    FRONTEND_PID=$(cat /tmp/inventory-frontend.pid)
    if kill -0 $FRONTEND_PID 2>/dev/null; then
        echo -e "${YELLOW}フロントエンドサーバーを停止しています (PID: $FRONTEND_PID)${NC}"
        kill $FRONTEND_PID
    fi
    rm -f /tmp/inventory-frontend.pid
fi

# フォールバック: ポート上に残っているプロセスを停止
echo -e "${YELLOW}残っているプロセスをクリーンアップしています...${NC}"

# ポート 8001(バックエンド)のプロセスを停止
BACKEND_PIDS=$(lsof -ti:8001 2>/dev/null || true)
if [ ! -z "$BACKEND_PIDS" ]; then
    echo "$BACKEND_PIDS" | xargs kill 2>/dev/null || true
fi

# ポート 3000(フロントエンド)のプロセスを停止
FRONTEND_PIDS=$(lsof -ti:3000 2>/dev/null || true)
if [ ! -z "$FRONTEND_PIDS" ]; then
    echo "$FRONTEND_PIDS" | xargs kill 2>/dev/null || true
fi

# ログファイルを削除
rm -f /tmp/inventory-backend.log
rm -f /tmp/inventory-frontend.log

echo -e "\n${GREEN}✓ すべてのサーバーを停止しました${NC}"
