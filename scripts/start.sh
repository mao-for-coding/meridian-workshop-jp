#!/bin/bash

# 工場在庫管理システム - 起動スクリプト
# バックエンド(FastAPI)とフロントエンド(Vue + Vite)の両サーバーを起動します

set -e  # エラー時に終了

# 出力用のカラー定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # 色なし

echo -e "${BLUE}工場在庫管理システムを起動しています...${NC}\n"

# プロジェクトルートを取得(scripts ディレクトリの親)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# バックエンドの依存関係がインストール済みか確認
if [ ! -d "$PROJECT_ROOT/server/.venv" ]; then
    echo -e "${YELLOW}バックエンドの依存関係が見つかりません。インストールします...${NC}"
    cd "$PROJECT_ROOT/server"
    uv venv
    uv sync
fi

# フロントエンドの依存関係がインストール済みか確認
if [ ! -d "$PROJECT_ROOT/client/node_modules" ]; then
    echo -e "${YELLOW}フロントエンドの依存関係が見つかりません。インストールします...${NC}"
    cd "$PROJECT_ROOT/client"
    npm install
fi

# バックエンドサーバーをバックグラウンドで起動
echo -e "${GREEN}バックエンドサーバーを起動しています: http://localhost:8001${NC}"
cd "$PROJECT_ROOT/server"
uv run python3 main.py > /tmp/inventory-backend.log 2>&1 &
BACKEND_PID=$!

# バックエンドの起動を少し待つ
sleep 2

# フロントエンドサーバーをバックグラウンドで起動
echo -e "${GREEN}フロントエンドサーバーを起動しています: http://localhost:3000${NC}"
cd "$PROJECT_ROOT/client"
npm run dev > /tmp/inventory-frontend.log 2>&1 &
FRONTEND_PID=$!

# フロントエンドの起動を少し待つ
sleep 2

echo -e "\n${GREEN}✓ アプリケーションが起動しました${NC}"
echo -e "${BLUE}フロントエンド:${NC} http://localhost:3000"
echo -e "${BLUE}バックエンド API:${NC} http://localhost:8001"
echo -e "${BLUE}API ドキュメント:${NC} http://localhost:8001/docs"
echo -e "\n${YELLOW}ログ:${NC}"
echo -e "  バックエンド: /tmp/inventory-backend.log"
echo -e "  フロントエンド: /tmp/inventory-frontend.log"
echo -e "\n${YELLOW}サーバーを停止するには次を実行してください:${NC} ./stop.sh"
echo -e "${YELLOW}または Ctrl+C のあと、次を実行してください:${NC} kill $BACKEND_PID $FRONTEND_PID"

# 停止スクリプト用に PID をファイルへ保存
echo "$BACKEND_PID" > /tmp/inventory-backend.pid
echo "$FRONTEND_PID" > /tmp/inventory-frontend.pid

# Ctrl+C を待機
trap "echo -e '\n${YELLOW}サーバーをシャットダウンしています...${NC}'; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; rm -f /tmp/inventory-*.pid; exit 0" INT TERM

echo -e "\n${GREEN}すべてのサーバーを停止するには Ctrl+C を押してください${NC}"
wait
