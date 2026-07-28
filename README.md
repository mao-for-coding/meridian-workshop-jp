# Meridian ワークショップ

Claude Code のワークショップです。あなたはコンサルタントとして RFP に応札し、その後、受注した案件を実際に遂行します。

## 事前準備

以下をあらかじめインストールしてください。

- **Claude Code**:[docs.claude.com/claude-code](https://docs.claude.com/en/docs/claude-code/overview)
- **Node.js 18 以上**:[nodejs.org](https://nodejs.org)
- **uv**(Python パッケージマネージャー):`curl -LsSf https://astral.sh/uv/install.sh | sh`
- **git**

## セットアップ

ワークショップの最後に PR を作成するため、**まずこのリポジトリを fork** し、その fork をクローンしてください。

```bash
git clone https://github.com/<your-username>/meridian-workshop-jp.git
cd meridian-workshop-jp
claude
```

準備はこれだけです。あとは Claude に挨拶すれば、そこから先は Claude が案内してくれます。

## 途中で接続が切れてしまったら

このディレクトリでもう一度 `claude` を実行し、どこまで進んでいたかを Claude に伝えてください。

## リポジトリの構成

- `docs/rfp/`:RFP とクライアントの背景資料
- `proposal/`:提案書の置き場所(最初は空です)
- `client/`、`server/`:第2幕で扱うアプリケーション本体
- `.claude/`:前任ベンダーが残したプロジェクトレベルの Claude Code 設定(エージェント、コマンド、スキル)
