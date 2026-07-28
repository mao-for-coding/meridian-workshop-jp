---
name: backend-api-test
description: pytest と FastAPI TestClient を使ったバックエンド API テストの作成ガイドライン。tests/backend ディレクトリ内のテストを作成・修正する際に、このスキルを使用してください。
---

# バックエンド API テストのガイドライン

このスキルは、工場在庫管理システムのバックエンド API テストを書くための包括的なガイドラインです。一貫性のある、抜け漏れのないテストカバレッジを実現するために、以下のパターンに従ってください。

## ディレクトリ構成

バックエンドのテストはすべて `tests/backend/` に配置します。

```
tests/backend/
├── conftest.py           # Shared fixtures and test client setup
├── test_inventory.py     # Inventory endpoint tests
├── test_orders.py        # Orders endpoint tests
├── test_dashboard.py     # Dashboard endpoint tests
└── test_misc_endpoints.py # Other endpoint tests
```

## ファイルの整理方法

### 1. ファイル命名
- `test_<feature>.py` という形式を使います(例: `test_inventory.py`、`test_orders.py`)
- 関連する endpoint は同じファイルにまとめます
- API の機能領域が明確に異なる場合は、新しいファイルを作成します

### 2. テストクラスの構成
わかりやすい名前を付けたクラスの中にテストをまとめます。

```python
"""
Tests for <feature> API endpoints.
"""
import pytest


class Test<Feature>Endpoints:
    """Test suite for <feature>-related endpoints."""

    def test_get_all_<resources>(self, client):
        """Test getting all <resources>."""
        # Test implementation
```

## テストの基本パターン

### 1. 基本的な endpoint テスト

**まずは正常系(happy path)からテストします。**

```python
def test_get_all_orders(self, client):
    """Test getting all orders."""
    response = client.get("/api/orders")
    assert response.status_code == 200

    data = response.json()
    assert isinstance(data, list)
    assert len(data) > 0

    # Verify structure of first item
    first_order = data[0]
    assert "id" in first_order
    assert "order_number" in first_order
    # ... other required fields
```

### 2. フィルターのテスト

各クエリパラメータのフィルターを、単独と組み合わせの両方でテストします。

```python
def test_get_orders_by_warehouse(self, client):
    """Test filtering orders by warehouse."""
    response = client.get("/api/orders?warehouse=Tokyo")
    assert response.status_code == 200

    data = response.json()
    assert isinstance(data, list)

    # Verify all results match the filter
    for order in data:
        assert order["warehouse"] == "Tokyo"

def test_get_orders_multiple_filters(self, client):
    """Test filtering orders with multiple filters."""
    response = client.get(
        "/api/orders?warehouse=San Francisco&category=Power Supplies&status=Delivered"
    )
    assert response.status_code == 200

    data = response.json()

    # Verify all results match ALL filters
    for order in data:
        assert order["warehouse"] == "San Francisco"
        assert order["category"].lower() == "power supplies"
        assert order["status"].lower() == "delivered"
```

**テストしておきたい主なフィルター:**
- `warehouse`: 倉庫の所在地でフィルタリング
- `category`: 製品カテゴリでフィルタリング
- `status`: 注文ステータスでフィルタリング(注文のみ)
- `month`: 月でフィルタリング。形式は `YYYY-MM`、または四半期指定の `Q1-2025`

### 3. 単一リソースのテスト

ID を指定して個別のリソースを取得するテストです。

```python
def test_get_order_by_id(self, client):
    """Test getting a specific order by ID."""
    # First get all orders to find a valid ID
    response = client.get("/api/orders")
    all_orders = response.json()
    assert len(all_orders) > 0

    first_order_id = all_orders[0]["id"]

    # Now get that specific order
    response = client.get(f"/api/orders/{first_order_id}")
    assert response.status_code == 200

    order = response.json()
    assert order["id"] == first_order_id

def test_get_nonexistent_order(self, client):
    """Test getting an order that doesn't exist."""
    response = client.get("/api/orders/nonexistent-order-999")
    assert response.status_code == 404

    data = response.json()
    assert "detail" in data
    assert "not found" in data["detail"].lower()
```

### 4. データ構造の検証

レスポンスの構造が API の契約どおりであることを確認します。

```python
def test_order_items_structure(self, client):
    """Test that order items have proper structure."""
    response = client.get("/api/orders")
    data = response.json()

    for order in data:
        assert "items" in order
        assert isinstance(order["items"], list)

        for item in order["items"]:
            assert "sku" in item
            assert "name" in item
            assert "quantity" in item
            assert "unit_price" in item
            assert isinstance(item["quantity"], int)
            assert isinstance(item["unit_price"], (int, float))
```

### 5. データ型の検証

数値フィールドの型が正しく、値が妥当な範囲に収まっていることを確認します。

```python
def test_inventory_quantity_types(self, client):
    """Test that quantity fields are proper numeric types."""
    response = client.get("/api/inventory")
    data = response.json()

    for item in data:
        assert isinstance(item["quantity_on_hand"], int)
        assert isinstance(item["reorder_point"], int)
        assert isinstance(item["unit_cost"], (int, float))
        assert item["quantity_on_hand"] >= 0
        assert item["reorder_point"] >= 0
        assert item["unit_cost"] >= 0
```

### 6. ビジネスロジックの検証

計算値やビジネスルールをテストします。

```python
def test_order_total_value_calculation(self, client):
    """Test that order total values are reasonable."""
    response = client.get("/api/orders")
    data = response.json()

    for order in data:
        assert "total_value" in order
        assert isinstance(order["total_value"], (int, float))
        assert order["total_value"] > 0

        # Verify total makes sense based on items
        calculated_total = sum(
            item["quantity"] * item["unit_price"]
            for item in order["items"]
        )
        # Allow small floating point differences
        assert abs(order["total_value"] - calculated_total) < 0.01
```

### 7. 列挙値・ステータス値の検証

取りうる値が限定されたフィールドについて、値が妥当であることを確認します。

```python
def test_order_status_values(self, client):
    """Test that orders have valid status values."""
    response = client.get("/api/orders")
    data = response.json()

    valid_statuses = ["delivered", "shipped", "processing", "backordered"]

    for order in data:
        assert order["status"].lower() in valid_statuses
```

### 8. 日付フォーマットの検証

日付フィールドが正しい形式であることを確認します。

```python
def test_order_dates_format(self, client):
    """Test that order dates are in proper format."""
    response = client.get("/api/orders")
    data = response.json()

    for order in data:
        assert "order_date" in order
        assert "expected_delivery" in order
        # Date should contain year, month pattern (ISO format)
        assert "2025-" in order["order_date"]
        assert "-" in order["expected_delivery"]
        assert "T" in order["expected_delivery"]  # Has time component
```

### 9. endpoint 間の整合性検証

集計系の endpoint が元データと一致していることをテストします。

```python
def test_dashboard_pending_orders_calculation(self, client):
    """Test that pending orders are calculated correctly."""
    # Get all orders
    orders_response = client.get("/api/orders")
    all_orders = orders_response.json()

    # Count processing and backordered orders
    pending_count = sum(
        1 for order in all_orders
        if order["status"].lower() in ["processing", "backordered"]
    )

    # Get dashboard summary
    dashboard_response = client.get("/api/dashboard/summary")
    dashboard_data = dashboard_response.json()

    assert dashboard_data["pending_orders"] == pending_count
```

## Fixture の使い方

### 利用できる fixture(conftest.py で定義)

1. **`client`**: FastAPI TestClient のインスタンス(すべてのテストで必須)
2. **`sample_inventory_item`**: 在庫アイテムのサンプル構造
3. **`sample_order`**: 注文のサンプル構造

### client fixture の使い方

```python
def test_example(self, client):
    """Every test method needs the client fixture."""
    response = client.get("/api/endpoint")
    assert response.status_code == 200
```

### 新しい fixture の作成

共有する fixture は [conftest.py](tests/backend/conftest.py) に追加します。

```python
@pytest.fixture
def sample_warehouse_data():
    """Sample warehouse data for testing."""
    return {
        "name": "San Francisco",
        "location": "CA",
        # ... other fields
    }
```

## テストの命名規則

何をテストしているのかが一目でわかる名前を付けてください。

- `test_get_all_<resources>`: フィルターなしで全件取得
- `test_get_<resource>_by_<filter>`: 単一フィルターのテスト
- `test_get_<resource>_multiple_filters`: フィルターの組み合わせテスト
- `test_get_<resource>_by_id`: 単一アイテムの取得
- `test_get_nonexistent_<resource>`: 404 処理
- `test_<resource>_<field>_structure`: データ構造の検証
- `test_<resource>_<field>_types`: データ型の検証
- `test_<resource>_<calculation>_calculation`: ビジネスロジックの検証

## よく使う assertion

### ステータスコード
```python
assert response.status_code == 200  # Success
assert response.status_code == 404  # Not found
assert response.status_code == 422  # Validation error
```

### レスポンスの型
```python
data = response.json()
assert isinstance(data, list)    # Array response
assert isinstance(data, dict)    # Object response
assert len(data) > 0             # Has data
```

### フィールドの存在確認
```python
assert "field_name" in data
assert "detail" in error_response  # Error messages
```

### 文字列比較(大文字小文字を区別しない)
```python
assert order["status"].lower() == "delivered"
assert item["category"].lower() == "power supplies"
```

### 浮動小数点数の比較
```python
# Allow small differences for float calculations
assert abs(calculated - expected) < 0.01
```

## API endpoint リファレンス

### 在庫関連の endpoint
- `GET /api/inventory`: 全在庫アイテム
  - フィルター: `warehouse`、`category`
- `GET /api/inventory/{id}`: 単一の在庫アイテム

### 注文関連の endpoint
- `GET /api/orders`: 全注文
  - フィルター: `warehouse`、`category`、`status`、`month`
- `GET /api/orders/{id}`: 単一の注文

### ダッシュボード関連の endpoint
- `GET /api/dashboard/summary`: ダッシュボードサマリー
  - フィルター: `warehouse`、`category`、`status`、`month`

### その他の endpoint
- `GET /api/demand`: 需要予測(フィルターなし)
- `GET /api/backlog`: バックログアイテム(フィルターなし)
- `GET /api/spending/*`: 支出データの各 endpoint

## テストでよく使う値

### 倉庫
- San Francisco
- London
- Tokyo

### カテゴリ
- Circuit Boards
- Sensors
- Power Supplies
- Connectors
- Mechanical Components

### 注文ステータス
- Delivered
- Shipped
- Processing
- Backordered

### 日付フォーマット
- 単月指定: `2025-01`、`2025-02` など
- 四半期指定: `Q1-2025`、`Q2-2025` など
- 全期間: `all`

## ベストプラクティス

1. **1 テスト 1 検証**: 各テストでは 1 つの振る舞いだけを確認します
2. **わかりやすい assertion を書く**: エラーメッセージが明快だとデバッグが楽になります
3. **エッジケースをテストする**: 空の結果、存在しない ID、無効なフィルターなど
4. **データの整合性を確認する**: 型、値の範囲、計算値をチェックします
5. **フィルターは単独でテストしてから組み合わせる**: まず個別に、その後に組み合わせを試します
6. **文字列比較では大文字小文字を区別しない**: status や category のような文字列フィールドに適用します
7. **浮動小数点数には許容誤差を設ける**: 金額計算には `abs(a - b) < 0.01` を使います
8. **エラーレスポンスもテストする**: 404 が正しく返ることを確認します
9. **構造全体を検証する**: 必須フィールドがすべて揃っていることを確認します
10. **endpoint 間で相互検証する**: ダッシュボードの値は元データと一致している必要があります

## テストの実行方法

```bash
# Run all backend tests
pytest tests/backend/

# Run specific test file
pytest tests/backend/test_orders.py

# Run specific test class
pytest tests/backend/test_orders.py::TestOrdersEndpoints

# Run specific test method
pytest tests/backend/test_orders.py::TestOrdersEndpoints::test_get_all_orders

# Run with verbose output
pytest tests/backend/ -v

# Run with coverage
pytest tests/backend/ --cov=server
```

## 例: テストファイル一式のテンプレート

```python
"""
Tests for <feature> API endpoints.
"""
import pytest


class Test<Feature>Endpoints:
    """Test suite for <feature>-related endpoints."""

    def test_get_all_<resources>(self, client):
        """Test getting all <resources>."""
        response = client.get("/api/<resources>")
        assert response.status_code == 200

        data = response.json()
        assert isinstance(data, list)
        assert len(data) > 0

        # Verify structure
        first_item = data[0]
        assert "id" in first_item
        # Add other required fields

    def test_get_<resource>_by_filter(self, client):
        """Test filtering <resources> by <filter>."""
        response = client.get("/api/<resources>?<filter>=<value>")
        assert response.status_code == 200

        data = response.json()

        # Verify filter applied correctly
        for item in data:
            assert item["<filter>"] == "<value>"

    def test_get_<resource>_by_id(self, client):
        """Test getting a specific <resource> by ID."""
        # Get valid ID first
        response = client.get("/api/<resources>")
        all_items = response.json()
        item_id = all_items[0]["id"]

        # Get specific item
        response = client.get(f"/api/<resources>/{item_id}")
        assert response.status_code == 200

        item = response.json()
        assert item["id"] == item_id

    def test_get_nonexistent_<resource>(self, client):
        """Test getting a <resource> that doesn't exist."""
        response = client.get("/api/<resources>/nonexistent-999")
        assert response.status_code == 404

        data = response.json()
        assert "detail" in data
        assert "not found" in data["detail"].lower()
```

## 重要ポイントのまとめ

- **必ず `client` fixture を使う**: API 呼び出しに使う TestClient です
- **フィルターは徹底的にテストする**: 単独のフィルターも、組み合わせも確認します
- **レスポンス構造を検証する**: 必須フィールドがすべて存在することを確認します
- **文字列比較は小文字に揃えて行う**: カテゴリやステータスは大文字小文字が揺れることがあります
- **成功と失敗の両方のパスをテストする**: 200 と 404 のレスポンスを確認します
- **データ型を検証する**: 型チェックには `isinstance()` を使います
- **ビジネスロジックをテストする**: 計算、集計、派生値を確認します
- **テストの独立性を保つ**: 各テストは単独で動作する必要があります
