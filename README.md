# nukegara - 環境別ドットファイル管理

Git ブランチを使って環境ごとのドットファイルを管理するシステム。MD5 ベースのホスト自動識別と、master ディレクトリによる共通設定配布をサポートする。

## 概要

`nukegara` は Git ブランチで複数環境のドットファイルを管理する。各環境は独自のブランチを持ち、main ブランチの管理スクリプトがホストを自動識別して適切な worktree との同期を行う。

## 特徴

- **ホスト自動識別**: ホスト名の MD5 ハッシュでマシンを識別
- **ブランチ = 環境**: 環境ごとに独立した Git ブランチで管理
- **git worktree 活用**: 複数環境を同時に扱える
- **スマートな差分同期**: 変更があったファイルのみコピー
- **ドライランモード**: デフォルトは確認のみ、`--execute` で実行

## リポジトリ構造

```
.
├── run.rb              # メイン管理スクリプト
├── targets.yaml        # ホスト設定・対象ファイル定義
├── master/             # 全環境共通のマスター設定（任意）
└── environments/       # Git worktree（.gitignore 推奨）
    └── macbook/2025/
```

## 設定

### targets.yaml

```yaml
master:
  path: master/         # master ディレクトリのパス（省略可）

hosts:
  - md5: e7d8577877bbfda3608a3c2679e56a18  # ホスト名の MD5 ハッシュ
    branch: environments/macbook/2025       # この環境の Git ブランチ
    targets:
      - target: "~/.tmux.conf"             # ローカルのパス
        nukegara: "tmux.conf"              # worktree 内の相対パス
      - target: "~/.config/nvim"           # ディレクトリも指定可
        nukegara: "config/nvim"
```

### ホストの MD5 ハッシュ取得

```bash
ruby -e "require 'digest/md5'; puts Digest::MD5.hexdigest(\`uname -n\`.strip)"
```

### master/ ディレクトリ

複数の環境に共通して適用したいファイルを置く場所。

- `nukegara diff` で master と各 env の差分を確認（競合は赤表示）
- `nukegara apply` で master の内容を env worktree に反映（競合は master で上書き）
- env にしか存在しないファイルは `[env-only]` として表示（変更されない）

## セットアップ

1. **環境ブランチを作成する**:

```bash
git checkout -b environments/macbook/2025
git push -u origin environments/macbook/2025
git checkout main
```

2. **worktree を作成する**:

```bash
git worktree add environments/macbook/2025 environments/macbook/2025
```

3. **targets.yaml に設定を追加する**:

- MD5 ハッシュ、ブランチ名、対象ファイルを記載する

4. **ローカルから worktree に同期する**:

```bash
ruby run.rb local pull --execute
```

## 使い方

### local サブコマンド - ローカル ↔ env worktree

```bash
# ローカル → worktree（ドライラン）
ruby run.rb local pull

# ローカル → worktree（実行）
ruby run.rb local pull --execute

# worktree → ローカル（ドライラン）
ruby run.rb local apply

# worktree → ローカル（実行）
ruby run.rb local apply --execute

# ローカルと worktree の差分確認
ruby run.rb local diff
```

### nukegara サブコマンド - master ↔ env worktree

```bash
# master と env の差分確認（競合は赤、env-only は水色）
ruby run.rb nukegara diff

# master の内容を env に反映（ドライラン）
ruby run.rb nukegara apply

# master の内容を env に反映（実行）
ruby run.rb nukegara apply --execute
```

## 典型的なワークフロー

1. ローカルのドットファイルを編集する（例: `~/.tmux.conf`）
2. 変更を確認する: `ruby run.rb local diff`
3. worktree に同期する: `ruby run.rb local pull --execute`
4. worktree でコミット・プッシュする:
   ```bash
   cd environments/macbook/2025
   git add .
   git commit -m "update dotfiles"
   git push
   ```
5. 別のマシンで反映する: `ruby run.rb local apply --execute`
