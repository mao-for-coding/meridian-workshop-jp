# Claude Code フック

このディレクトリには、開発中のタスクを自動化する Claude Code のフックが入っています。

## 利用可能なフック

### 1. ツール使用ロガー(`post-tool-use.sh`)

**目的**: すべてのツール使用をログに記録し、デバッグや Claude の動作の追跡に役立てます。

**トリガー**: 毎回のツール呼び出し(Read、Write、Edit、Bash など)の後に実行されます。

**設定**: `.claude/settings.local.json` の `hooks.PostToolUse` セクションで有効化されています。

**ログの場所**: `.claude/logs/tool-usage-YYYY-MM-DD.log`

**ログのフォーマット**:
```
=== ツール使用: 2025-10-16 09:15:23 ===
ツール: Read
セッション: abc123
入力: {"file_path": "/path/to/file.js"}
レスポンス: {"content": "..."}
```

**特徴**:
- タイムスタンプつきの日次ログファイルを作成します
- JSON のパースには `jq` を使います(jq がなければ生ログにフォールバック)
- ツール名、セッション ID、入力パラメータ、レスポンスを記録します
- ツールの実行を妨げることはありません

**使い方**:
設定が済んでいれば、フックは自動で実行されます。ログの確認方法:
```bash
# View today's log
cat .claude/logs/tool-usage-$(date +%Y-%m-%d).log

# View logs with live updates
tail -f .claude/logs/tool-usage-$(date +%Y-%m-%d).log

# Search logs for specific tool
grep "ツール: Bash" .claude/logs/*.log
```

**必要なもの**:
- 任意: JSON を見やすく整形するための `jq`(macOS では `brew install jq`)

### 2. プロンプト送信フック(`user-prompt-submit.sh`)

**目的**: Claude がコミットを作成する際に、コミット前のリントチェックを実行します。

**トリガー**: ユーザーのプロンプトに "commit" または "git commit" が含まれるときに実行されます。

**特徴**:
- Python ファイルを `ruff` でリントします
- JavaScript/Vue ファイルを `eslint` でリントします
- リントに失敗した場合はコミットをブロックします

## フックの無効化

フックを一時的に無効化する方法は次の 3 つです:

1. **設定から外す**: `.claude/settings.local.json` を編集してフックの設定を削除する
2. **実行権限を外す**: `chmod -x .claude/hooks/post-tool-use.sh`
3. **フックファイルを削除する**: `rm .claude/hooks/post-tool-use.sh`

## カスタムフックの作成

カスタムフックの作り方は、[Claude Code フックのドキュメント](https://docs.claude.com/en/docs/claude-code/hooks.md)を参照してください。

### 利用可能なフックイベント:
- `PreToolUse` - ツール実行の前
- `PostToolUse` - ツール実行の後
- `UserPromptSubmit` - ユーザーがプロンプトを送信したとき
- `Stop` - エージェントの応答が終わったとき
- `SubagentStop` - サブエージェントが終了したとき
- `SessionStart` - セッション開始時
- `SessionEnd` - セッション終了時

### フックの終了コード:
- `0` - 成功、処理を続行させる
- `2` - 処理をブロックし、エラーメッセージを表示する
- その他の非ゼロ - エラーが発生した

## トラブルシューティング

**フックが実行されない場合**
- フックファイルが実行可能か確認する: `ls -l .claude/hooks/`
- `.claude/settings.local.json` の設定を確認する
- Claude Code のログでエラーを確認する

**権限エラーが出る場合**
- フックスクリプトに実行権限があるか確認する: `chmod +x .claude/hooks/*.sh`

**ログが見つからない場合**
- ログは `.claude/logs/` ディレクトリに作成されます
- 環境変数 `CLAUDE_PROJECT_DIR` が正しく設定されているか確認する
- フックを手動で実行して動作を試す: `./.claude/hooks/post-tool-use.sh`
