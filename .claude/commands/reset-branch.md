---
description: main に切り替えて、直前のブランチを削除します
---

main ブランチに戻り、それまで作業していたブランチをコミットや変更ごと削除してください。削除するブランチに紐づくリモートのプルリクエストがあれば、あわせてクローズします。

手順:
1. `git branch --show-current` で現在のブランチを確認する
2. すでに main/master にいる場合は、リセット不要であることをユーザーに伝える
3. フィーチャーブランチにいる場合:
   - 失われるコミットを表示する: `git log main..HEAD --oneline`
   - ブランチ名を控えておく
   - GitHub MCP でこのブランチの PR を探してクローズする: `mcp__github__list_pull_requests`(head ブランチで絞り込み)で見つけ、`mcp__github__update_pull_request` でクローズする
   - main に切り替える: `git checkout main`
   - フィーチャーブランチを削除する: `git branch -D <branch-name>`
   - 作業ディレクトリをクリーンアップする: `git reset --hard HEAD` で追跡ファイルの変更をすべて破棄する
   - 未追跡ファイルを削除する: `git clean -fd` で未追跡のファイルとディレクトリを取り除く
   - 結果を表示する: `git status` と `git branch`

警告: フィーチャーブランチとそのコミット・変更はすべて完全に削除され、リモートの PR もクローズされます。作業ディレクトリの変更もすべて破棄され、未追跡ファイルも削除されます。
