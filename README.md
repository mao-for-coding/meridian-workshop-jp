# Meridian ワークショップ

コンサルタントになったつもりで RFP に応札し、受注した案件を納品まで仕上げる。その一連の流れを通して Claude Code を学ぶワークショップです。

## 事前準備

次のツールをあらかじめインストールしておいてください。

- **Claude Code**:[docs.claude.com/claude-code](https://docs.claude.com/en/docs/claude-code/overview)
- **Node.js 18 以上**:[nodejs.org](https://nodejs.org)
- **uv**(Python パッケージマネージャー):`curl -LsSf https://astral.sh/uv/install.sh | sh`
- **git**

## セットアップ

ワークショップの最後に PR を作成するので、**最初にこのリポジトリを fork** してから、自分の fork をクローンしてください。

```bash
git clone https://github.com/<your-username>/meridian-workshop-jp.git
cd meridian-workshop-jp
claude
```

準備はこれで完了です。あとは Claude に一声かければ、続きは Claude が案内してくれます。

## 途中で接続が切れてしまったら

同じディレクトリでもう一度 `claude` を実行し、どこまで進んでいたかを Claude に伝えてください。そこから再開できます。

## リポジトリの構成

- `docs/rfp/`:RFP とクライアントの背景資料
- `proposal/`:提案書の置き場所(最初は空です)
- `client/`、`server/`:第2幕で手を入れるアプリケーション本体
- `.claude/`:前任ベンダーが残したプロジェクトレベルの Claude Code 設定(エージェント、コマンド、スキル)
