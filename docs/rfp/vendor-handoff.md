# 引き継ぎメモ:在庫ダッシュボード

*前任ベンダーが契約終了時(2024年11月)に作成。RFP パッケージの一部として Meridian より提供。*

---

## 技術スタック

- フロントエンド:Vue 3 + Composition API + Vite(ポート 3000)
- バックエンド:Python FastAPI(ポート 8001)
- データ:`server/data/` 内の JSON ファイルを `server/mock_data.py` 経由で読み込み(データベースなし)

## 起動方法

```bash
# Backend
cd server && uv run python main.py

# Frontend
cd client && npm install && npm run dev
```

両方をまとめて起動する `scripts/start.sh` もあります。

## API

- `GET /api/inventory`(フィルター:warehouse、category)
- `GET /api/orders`(フィルター:warehouse、category、status、month)
- `GET /api/dashboard/summary`(全フィルター対応)
- `GET /api/demand`、`/api/backlog`(フィルターなし)
- `GET /api/spending/*`(summary、monthly、categories、transactions)

## 実装パターン

- フィルターシステム:4種のフィルター(期間、倉庫、カテゴリー、注文ステータス)をクエリパラメータで適用
- データフロー:Vue のフィルター → `client/src/api.js` → FastAPI → インメモリでのフィルタリング → Pydantic → computed プロパティ
- リアクティビティ:生データは ref に、派生データは computed に保持

## 引き継ぎ時点の既知の問題

- Reports モジュールは開発途中。フィルターの一部が未接続
- 自動テストは未納品
- 一部のビューは旧パターン(Options API)のまま。移行は未完了

## デザイントークン

- カラー:スレート/グレー系(#0f172a、#64748b、#e2e8f0)
- ステータスカラー:緑/青/黄/赤
- チャート:自作 SVG、レイアウトは CSS Grid

## ファイルマップ

- ビュー:`client/src/views/*.vue`
- API クライアント:`client/src/api.js`
- バックエンド:`server/main.py`、`server/mock_data.py`
- データ:`server/data/*.json`
