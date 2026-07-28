# CLAUDE.md - Server

このファイルは、Claude Code (claude.ai/code) が FastAPI バックエンドを扱う際のガイドラインです。

## サーバーの起動

```bash
# From server directory
uv run python main.py
# Server runs on http://localhost:8001
# API docs at http://localhost:8001/docs
```

## 開発のベストプラクティス

### API 設計の原則

**RESTful な設計:**
- HTTP メソッドは用途に応じて使い分けます(取得は GET、作成は POST など)
- 適切なステータスコードを返します(200, 201, 404, 400, 500)
- リソースの endpoint には複数形の名詞を使います(`/api/order` ではなく `/api/orders`)
- URL はシンプルで予測しやすい形に保ちます

**リクエスト/レスポンス:**
- 入力は必ず Pydantic モデルで検証します
- レスポンスの構造は一貫させます
- エラーレスポンスにはエラーの詳細を含めます
- 日付は ISO 8601 形式を使います(YYYY-MM-DD または YYYY-MM-DDTHH:MM:SS)

### 新しい endpoint の追加

**手順:**
1. データ検証用の Pydantic モデルを定義する
2. 分かりやすい名前で endpoint 関数を作成する
3. パスを明示した route デコレータを付ける
4. ビジネスロジックを実装する
5. エラーを適切に処理する
6. `tests/backend/` にテストを書く

**実装パターンの例:**
```python
class MyModel(BaseModel):
    id: str
    name: str
    value: float

@app.get("/api/resource", response_model=List[MyModel])
def get_resources(
    filter_param: Optional[str] = None,
    category: Optional[str] = None
):
    """Get resources with optional filtering."""
    results = all_resources

    if filter_param and filter_param != 'all':
        results = [r for r in results if r['field'] == filter_param]

    if category and category != 'all':
        results = [r for r in results if r['category'].lower() == category.lower()]

    return results
```

### データモデルのベストプラクティス

**Pydantic モデル:**
- 一度だけ定義して、あらゆる場所で使い回します
- 任意項目は `Optional[Type]` と明示します
- フィールド名は内容が伝わるものにします
- 適切な箇所にはデフォルト値を設定します
- モデルは使用箇所の近くに置きます

**モデルの更新:**
- JSON データにフィールドを追加したら、Pydantic モデルも更新します
- フィールドを削除する場合は、まず Optional にしてから削除します
- 後方互換性を考慮します
- モデルを変更したらテストも更新します

### フィルタリングのベストプラクティス

**標準パターン:**
- フィルタパラメータは省略可能な query パラメータとして受け取ります
- 値が 'all' の場合はそのフィルタをスキップします
- 大文字小文字を区別せずに比較したい場合は、小文字に揃えてから比較します
- コードの見通しをよくするため、フィルタは順番に適用します
- 元データは変更せず、コピーに対してフィルタします

**フィルタの実装:**
```python
def filter_data(data, warehouse=None, category=None):
    """Filter data by multiple criteria."""
    filtered = data

    if warehouse and warehouse != 'all':
        filtered = [item for item in filtered
                   if item.get('warehouse') == warehouse]

    if category and category != 'all':
        filtered = [item for item in filtered
                   if item.get('category', '').lower() == category.lower()]

    return filtered
```

**日付・時刻のフィルタリング:**
- 月の直接指定(2025-01)と四半期指定(Q1-2025)の両方に対応します
- 日付文字列は安全にパースします
- 日付が欠損・null の場合も適切に処理します
- 実際のデータベースを導入する場合はタイムゾーンも考慮します

### エラー処理

**HTTPException を使う:**
```python
from fastapi import HTTPException

@app.get("/api/item/{item_id}")
def get_item(item_id: str):
    item = find_item(item_id)
    if not item:
        raise HTTPException(
            status_code=404,
            detail=f"Item {item_id} not found"
        )
    return item
```

**ベストプラクティス:**
- 「見つからない」エラーには 404 を返します
- 不正な入力や検証エラーには 400 を返します
- サーバーエラーには 500 を返します(FastAPI に任せて構いません)
- 原因の手がかりになるエラーメッセージを含めます
- デバッグのためにエラーをログに残します

### モックデータの管理

**パターン:**
- すべてのデータは起動時に JSON ファイルから読み込みます
- データはサーバー稼働中、メモリ上に保持されます
- 変更は永続化されません(再起動するとファイルから再読み込み)
- JSON ファイルは整形し、検証を通した状態に保ちます

**新しいデータの追加:**
1. `server/data/` の JSON ファイルを更新する
2. 構造が変わった場合は Pydantic モデルも更新する
3. サーバーを再起動してデータを再読み込みする
4. API docs(/docs endpoint)で確認する

**データの整合性:**
- 注文内の SKU が有効な在庫アイテムを参照していることを確認します
- カテゴリ名はデータファイル間で一貫させます
- 日付フォーマットはすべての箇所で統一します
- コミット前に JSON の構造を検証します

### CORS の設定

**開発時:**
- 開発中はすべてのオリジンを許可します(`allow_origins=["*"]`)
- フロントエンドの開発サーバーが別ポートで動く場合に便利です

**本番環境:**
- 特定のオリジンのみに制限します
- 例: `allow_origins=["https://yourdomain.com"]`
- 本番でワイルドカード(*)は絶対に使いません
- デプロイ環境に応じて設定します

### API endpoint のテスト

**FastAPI Docs を使う場合:**
1. サーバーを起動する
2. http://localhost:8001/docs を開く
3. endpoint をクリックして展開する
4. "Try it out" をクリックする
5. パラメータを入力する
6. 実行してレスポンスを確認する

**pytest を使う場合:**
```python
def test_endpoint(client):
    response = client.get("/api/endpoint?param=value")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) > 0
```

**テストすべき項目:**
- 正常なリクエストが 200 を返すこと
- 無効な ID が 404 を返すこと
- フィルタが正しく機能すること
- レスポンス構造がモデルと一致すること
- 計算結果が正確であること
- エッジケース(空の結果、不正な入力)

### パフォーマンスに関する考慮事項

**インメモリデータ:**
- 読み取りが高速です(データベースクエリなし)
- デモ用途ではインデックスは不要です
- フィルタリングはすべて Python 内で行います
- 小規模なデータセット(1 万件未満)であれば十分実用的です

**スケールさせる場合:**
- データベースを導入する(PostgreSQL, MongoDB)
- ページネーションを実装する
- キャッシュ層を追加する(Redis)
- よく使うフィルタにはデータベースのインデックスを使う
- 非同期のデータベースクエリを検討する

### コードの整理

**切り出しの目安:**
- 複数の endpoint で使うフィルタリングロジック → ユーティリティ関数に切り出す
- 複雑なビジネスロジック → 別モジュールに移す
- Pydantic では足りないデータ検証 → カスタムバリデータを作る
- 繰り返し出てくる計算 → ヘルパー関数に切り出す

**成長を見据えたモジュール構成:**
```
server/
├── main.py           # API endpoints only
├── models.py         # Pydantic models
├── services/         # Business logic
│   ├── inventory.py
│   └── orders.py
├── utils/            # Helper functions
│   └── filters.py
└── data/             # JSON data files
```

### よくある落とし穴

**避けるべきこと:**
- ❌ グローバルなデータを直接変更する(コピーに対してフィルタすること)
- ❌ JSON を変更したのに Pydantic モデルを更新し忘れる
- ❌ endpoint ごとにフィルタパラメータ名がバラバラになる
- ❌ Pydantic モデルではなく生の dict を返す
- ❌ データ内の None/null 値を処理しない

**推奨すること:**
- ✅ すべての入力を Pydantic で検証する
- ✅ 型付きのレスポンスを返す(response_model)
- ✅ 省略可能なパラメータを適切に処理する
- ✅ endpoint は目的を絞ってシンプルに保つ
- ✅ 新しい endpoint にはテストを書く

### デバッグ

**テクニック:**
- FastAPI の自動生成 docs を使ってさっと動作確認する
- endpoint 関数内で print する(ターミナルに表示されます)
- レスポンスに含まれる Pydantic の検証エラーを確認する
- Python のデバッガを使う(`import pdb; pdb.set_trace()`)
- JSON データファイルの構造に問題がないか確認する

**よくある問題:**
- データが読み込まれない → JSON ファイルのパスを確認
- 検証エラー → Pydantic モデルとデータが一致しているか確認
- 結果が空になる → フィルタロジックとデータを確認
- 404 エラー → route のパスと HTTP メソッドを確認

### セキュリティに関する注意

**本番環境に向けて:**
- 認証・認可を追加する
- すべての入力を検証・サニタイズする
- HTTPS のみを使う
- レート制限を実装する
- 入力サイズの上限を設ける
- 機密性のある設定には環境変数を使う
- シークレットを git にコミットしない

**現在の状態:**
- 認証なし(デモ用のため)
- CORS はすべてのオリジンを許可
- レート制限なし
- 型以外の入力検証なし
- ローカル開発でのみ使用可能な状態です

## クイックリファレンス

**サーバー起動:** `uv run python main.py`
**API docs:** http://localhost:8001/docs
**テスト実行:** `cd ../tests && uv run pytest backend/ -v`
**endpoint 追加:** モデルを定義 → route を追加 → テストを書く
**フィルタ追加:** query パラメータを追加 → 'all' 値をチェック → データをフィルタ
