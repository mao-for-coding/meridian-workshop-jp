# CLAUDE.md - Client

このファイルは、Claude Code (claude.ai/code) が Vue 3 フロントエンドを扱う際のガイドラインです。

## クライアントの起動

```bash
# From client directory
npm run dev
# Runs on http://localhost:3000
```

## 開発のベストプラクティス

### Vue 3 Composition API のパターン

**コンポーネントの構造:**
```vue
<template>
  <!-- Template: Keep clean and declarative -->
</template>

<script>
import { ref, computed, watch, onMounted } from 'vue'

export default {
  name: 'ComponentName',
  props: {
    // Define props with types and defaults
  },
  setup(props) {
    // Reactive state
    const data = ref([])
    const loading = ref(false)

    // Computed properties
    const filteredData = computed(() => {
      return data.value.filter(/* logic */)
    })

    // Methods
    const loadData = async () => {
      // Implementation
    }

    // Lifecycle
    onMounted(() => {
      loadData()
    })

    // Return everything used in template
    return {
      data,
      loading,
      filteredData,
      loadData
    }
  }
}
</script>

<style scoped>
  /* Scoped styles */
</style>
```

**Composition API を使う理由:**
- 機能単位でコードを整理しやすい
- ロジックの切り出しと再利用が容易
- TypeScript のサポート
- バンドルサイズが小さい
- Options API より柔軟性が高い

### リアクティブデータのベストプラクティス

**ref と computed の使い分け:**
- 代入によって変化する値には `ref()` を使います
- 他のリアクティブデータをもとに算出される値には `computed()` を使います
- computed プロパティは依存先が変化するまでキャッシュされます
- computed プロパティを直接変更してはいけません

**例:**
```javascript
// refs - mutable state
const searchQuery = ref('')
const items = ref([])

// computed - derived from refs
const filteredItems = computed(() => {
  if (!searchQuery.value) return items.value
  return items.value.filter(item =>
    item.name.toLowerCase().includes(searchQuery.value.toLowerCase())
  )
})
```

**ref の値へのアクセス:**
- `<script>` 内では `.value` を使います(例: `count.value++`)
- `<template>` 内では `.value` は不要です(自動的にアンラップされます)

### データ読み込みのパターン

**標準的なアプローチ:**
```javascript
const loading = ref(true)
const error = ref(null)
const data = ref([])

const loadData = async () => {
  try {
    loading.value = true
    error.value = null
    data.value = await api.getData(filters)
  } catch (err) {
    error.value = 'Failed to load data'
    console.error('Load error:', err)
  } finally {
    loading.value = false
  }
}
```

**template での状態表示:**
```vue
<div v-if="loading">Loading...</div>
<div v-else-if="error">{{ error }}</div>
<div v-else>
  <!-- Show data -->
</div>
```

### composable によるフィルタ管理

**パターン:**
1. 共有状態のための composable を作る
2. UI にバインドするための ref を export する
3. ヘルパー関数を提供する
4. 変更を watch して副作用を発火させる

**composable の例:**
```javascript
// composables/useFilters.js
import { ref, computed } from 'vue'

const selectedCategory = ref('all')
const selectedWarehouse = ref('all')

export function useFilters() {
  const hasActiveFilters = computed(() => {
    return selectedCategory.value !== 'all' ||
           selectedWarehouse.value !== 'all'
  })

  const resetFilters = () => {
    selectedCategory.value = 'all'
    selectedWarehouse.value = 'all'
  }

  const getCurrentFilters = () => {
    return {
      category: selectedCategory.value,
      warehouse: selectedWarehouse.value
    }
  }

  return {
    selectedCategory,
    selectedWarehouse,
    hasActiveFilters,
    resetFilters,
    getCurrentFilters
  }
}
```

### リアクティビティのベストプラクティス

**v-for の key:**
```vue
<!-- ❌ Bad - using index -->
<div v-for="(item, index) in items" :key="index">

<!-- ✅ Good - using unique ID -->
<div v-for="item in items" :key="item.id">
```

**理由:** index を key に使うと、リストの変更時に Vue が DOM 要素を誤って再利用してしまいます。

**props の変更:**
```javascript
// ❌ Bad - mutating props
props.user.name = 'New Name'

// ✅ Good - emit event to parent
emit('update:user', { ...props.user, name: 'New Name' })
```

**日付の扱い:**
```javascript
// ❌ Bad - no validation
const month = new Date(order.date).getMonth()

// ✅ Good - validate first
const date = new Date(order.date)
if (!isNaN(date.getTime())) {
  const month = date.getMonth()
}
```

### コンポーネント間の通信

**Props は下へ、Events は上へ:**
```javascript
// Parent component
<ChildComponent
  :data="items"
  @update="handleUpdate"
/>

// Child component
props: {
  data: {
    type: Array,
    required: true
  }
},
setup(props, { emit }) {
  const update = () => {
    emit('update', newValue)
  }
}
```

**composable を使うべき場面:**
- 複数のコンポーネントで共有する状態
- 複数の場所で使うロジック
- 認証状態
- グローバルなフィルタ
- テーマや設定

### チャート実装のベストプラクティス

**computed プロパティを使う:**
```javascript
const chartData = computed(() => {
  // Transform raw data for chart
  return rawData.value.map(item => ({
    label: item.month,
    value: item.total
  }))
})
```

**SVG チャート:**
- レスポンシブなスケーリングのために viewBox を定義します
- 位置指定にはできるだけパーセンテージを使います
- データが空の場合も適切に処理します
- アクセシビリティのために ARIA ラベルを付けます

**パフォーマンス:**
- チャートの計算は computed プロパティにまとめます
- レンダリングのたびに再計算しないようにします
- 表示・非表示を頻繁に切り替えるチャートには v-if ではなく v-show を使います
- resize ハンドラは debounce します

### スタイリングのベストプラクティス

**scoped スタイル:**
```vue
<style scoped>
/* Only affects this component */
.card { }
</style>
```

**テーマには CSS 変数を使う:**
```css
:root {
  --primary-color: #3b82f6;
  --danger-color: #ef4444;
}

.button {
  background: var(--primary-color);
}
```

**レスポンシブデザイン:**
- 単位は拡大縮小に強い rem/em を使います
- モバイルファーストで設計します
- レイアウトは CSS Grid で組みます
- コンポーネントの配置には Flexbox を使います

**class のバインディング:**
```vue
<div :class="['card', { 'card-active': isActive }]">
<div :class="{ danger: hasError, success: isComplete }">
```

### パフォーマンスに関する考慮事項

**computed と methods の使い分け:**
- computed: 依存先が変化するまでキャッシュされます(計算に使う)
- methods: アクセスのたびに実行されます(アクションに使う)

**v-show と v-if の使い分け:**
- v-show: CSS の display を切り替えます(頻繁な切り替えに向く)
- v-if: DOM への追加・削除を行います(めったに表示しないコンテンツに向く)

**遅延読み込み:**
```javascript
// Dynamic import for code splitting
const HeavyComponent = defineAsyncComponent(() =>
  import('./components/HeavyComponent.vue')
)
```

**debounce 付きの watch:**
```javascript
import { watchDebounced } from '@vueuse/core'

watchDebounced(
  searchQuery,
  (newValue) => {
    // API call here
  },
  { debounce: 500 }
)
```

### よくある落とし穴

**避けるべきこと:**
- ❌ 配列の index を v-for の key に使う
- ❌ props を直接変更する
- ❌ 日付をパースする前の検証を忘れる
- ❌ 重い計算を computed ではなく methods で行う
- ❌ ローディング状態やエラー状態を処理しない
- ❌ 同じコンポーネント内で Composition API と Options API を混在させる

**推奨すること:**
- ✅ key には一意な ID を使う
- ✅ 親のデータを更新するときは event を emit する
- ✅ 外部データはすべて検証する
- ✅ 他の値から導かれるデータには computed プロパティを使う
- ✅ ローディング状態とエラー状態を必ず表示する
- ✅ プロジェクト全体で Composition API に統一する

### API 連携

**API 呼び出しは一箇所に集約する:**
```javascript
// api.js
import axios from 'axios'

const API_BASE = 'http://localhost:8001/api'

export const api = {
  async getItems(filters) {
    const params = new URLSearchParams()
    if (filters.category !== 'all') {
      params.append('category', filters.category)
    }
    const response = await axios.get(`${API_BASE}/items?${params}`)
    return response.data
  }
}
```

**コンポーネントでの利用:**
```javascript
import { api } from '@/api'

const loadItems = async () => {
  const filters = getCurrentFilters()
  items.value = await api.getItems(filters)
}
```

### 数値のフォーマット

**通貨:**
```javascript
const formatted = value.toLocaleString('en-US', {
  style: 'currency',
  currency: 'USD'
})
// Output: $1,234.56
```

**大きな数値:**
```javascript
const formatted = value.toLocaleString()
// Output: 1,234,567
```

**パーセンテージ:**
```javascript
const formatted = (value * 100).toFixed(1) + '%'
// Output: 45.2%
```

### コンポーネントのテスト

**テストすべき項目:**
- コンポーネントが正しくレンダリングされること
- props が適切に処理されること
- event が正しく emit されること
- computed プロパティが正しく計算されること
- ユーザー操作が期待どおりに動作すること

**例:**
```javascript
import { mount } from '@vue/test-utils'
import MyComponent from './MyComponent.vue'

describe('MyComponent', () => {
  it('displays data correctly', () => {
    const wrapper = mount(MyComponent, {
      props: { items: mockItems }
    })
    expect(wrapper.text()).toContain('Expected text')
  })
})
```

### デバッグ

**Vue DevTools:**
- ブラウザ拡張の Vue DevTools をインストールします
- コンポーネント階層を調べられます
- リアクティブな状態をリアルタイムに確認できます
- event やパフォーマンスを追跡できます

**console でのログ出力:**
```javascript
// In setup()
console.log('Data:', data.value)

// Watch for changes
watch(data, (newVal) => {
  console.log('Data changed:', newVal)
})
```

**よくある問題:**
- リアクティビティが効かない → script 内で `.value` を付け忘れている
- computed が更新されない → 依存先がリアクティブでない
- props がリアクティブでない → setup 内で props を分割代入している
- v-for が更新されない → key の指定が誤っている

### コードの整理

**コンポーネントを切り出す目安:**
- template が 100 行を超える
- ロジックが 150 行を超える
- 複数の場所で再利用されている
- 明確に独立した責務を持っている

**composable を作る目安:**
- 複数のコンポーネントで共有する状態がある
- 再利用できるロジックのパターンがある
- 切り離せる複雑なロジックがある
- API とのやり取りのパターンがある

**ファイル構成:**
```
src/
├── views/           # Page-level components
├── components/      # Reusable UI components
├── composables/     # Shared logic
├── api.js          # API client
└── main.js         # App entry
```

## クイックリファレンス

**開発サーバー起動:** `npm run dev`
**本番用ビルド:** `npm run build`
**コンポーネント構造:** Template → Script (Composition API) → Scoped Styles
**データ読み込み:** loading 状態 → try/catch → finally
**フィルタ:** composable → ref → 変更を watch
**key:** 必ず一意な ID を使い、配列の index は使わない
**API 呼び出し:** api.js に集約し、try/catch で包む
