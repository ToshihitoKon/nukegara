# CLAUDE.md

このファイルは、このリポジトリのコードを扱う Claude Code (claude.ai/code) へのガイダンスを提供する。

## リポジトリの概要

このリポジトリは Git ブランチを使って環境ごとのドットファイルを管理する。各ブランチには特定の環境の設定ファイルが含まれており、メインブランチにはホスト自動識別に基づいてローカルシステムから適切な Git worktree にドットファイルを同期するための管理スクリプト（`run.rb` と `targets.yaml`）が含まれる。

## ブランチ構成

- **main ブランチ**: ドットファイル設定を適用するための管理スクリプトを含む
- **環境ブランチ**: 各ブランチには特定の環境のドットファイルと設定が含まれる
  - `environments/macbook/2025`: macOS 設定（2025年版）
  - `environments/macbook/202410`: macOS 設定（2024年10月版）
  - `win11-kaede-arch`: Windows 11 + Arch Linux サブシステム設定
  - `warabi`: 開発・テスト環境

## 仕組み

### ホスト自動識別
- 各ホストはホスト名の MD5 ハッシュで識別される
- `run.rb` スクリプトが現在のホストを自動検出し、`targets.yaml` から一致する設定を探す
- ローカルシステムから適切な Git worktree ディレクトリにファイルが同期される

### 設定管理
- `targets.yaml`: ホスト設定、ブランチマッピング、対象ファイルを定義する
- 各ホスト設定で指定するもの:
  - `md5`: ホスト識別用のホスト名 MD5 ハッシュ
  - `branch`: 環境のドットファイルを含む Git ブランチ
  - `targets`: 同期するファイル/ディレクトリのリスト

### 環境ブランチでの作業
- 各環境ブランチは独立していて、独自のドットファイルを持つ
- 複数の環境を同時に扱うには `git worktree` を使う
- 変更はローカルシステム → worktree の方向で同期され、その後ブランチにコミットする

## よく使うコマンド

```bash
# ホストの MD5 ハッシュを取得する
ruby -e "require 'digest/md5'; puts Digest::MD5.hexdigest(\`hostname\`.strip)"

# 全ブランチ（環境ブランチ含む）を一覧表示する
git branch -a

# 特定の環境の worktree を作成する
git worktree add environments/<environment-branch> <environment-branch>

# ローカルのドットファイルを worktree に同期する（ホスト自動検出）
ruby run.rb

# 全 worktree を一覧表示する
git worktree list

# worktree を削除する
git worktree remove environments/<environment-branch>
```

## 典型的なワークフロー

1. **初期セットアップ**:
   ```bash
   # ホストの MD5 ハッシュを取得する
   ruby -e "require 'digest/md5'; puts Digest::MD5.hexdigest(\`hostname\`.strip)"

   # 環境ブランチを作成する（必要な場合）
   git checkout -b environments/macbook/2025
   git push -u origin environments/macbook/2025
   git checkout main

   # worktree を作成する
   git worktree add environments/macbook/2025 environments/macbook/2025

   # targets.yaml に設定を追加する
   # （md5、branch、対象ファイルを指定する）
   ```

2. **ローカルの変更を worktree に同期する**:
   ```bash
   # ホスト名に基づいて自動的に同期する
   ruby run.rb
   ```

3. **変更をコミット・プッシュする**:
   ```bash
   cd environments/macbook/2025
   git add .
   git commit -m "update dotfiles"
   git push
   cd ../..
   ```

4. **別のマシンにデプロイする**:
   ```bash
   # 同じ環境設定を持つマシン上で実行する
   git worktree add environments/macbook/2025 environments/macbook/2025
   cd environments/macbook/2025
   git pull
   # 手動でホームディレクトリにファイルをコピーするか、デプロイスクリプトを使う
   ```

## targets.yaml の設定

設定構造の例:

```yaml
hosts:
  - md5: e7d8577877bbfda3608a3c2679e56a18
    branch: environments/macbook/2025
    targets:
      - target: "~/.tmux.conf"
        nukegara: "tmux.conf"
      - target: "~/.zshrc"
        nukegara: "zshrc"
      - target: "~/.config/nvim"
        nukegara: "config/nvim"
      - target: "~/.config/alacritty"
        nukegara: "config/alacritty"
```

- `md5`: ホスト名の MD5 ハッシュ（上のコマンドで取得する）
- `branch`: この環境のドットファイルを保存する Git ブランチ
- `targets`: ファイル/ディレクトリのマッピングリスト
  - `target`: ローカルシステム上のパス（`~` でホームディレクトリを指定可）
  - `nukegara`: worktree 内の相対パス

## 開発メモ

- このリポジトリは環境ごとにブランチを分ける戦略を採用している
- main ブランチには共通ツール（`run.rb`、`targets.yaml`）とドキュメントが含まれる
- 環境ブランチは独立していて環境固有の内容を持つ
- 複数の環境を同時に扱うには git worktree を使う
- 同期はローカルシステム → worktree の一方向のみ（ホームディレクトリへの自動デプロイはない）
