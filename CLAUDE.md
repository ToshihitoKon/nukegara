# CLAUDE.md

このファイルは、このリポジトリのコードを扱う Claude Code (claude.ai/code) へのガイダンスを提供する。

## リポジトリの概要

このリポジトリは Git ブランチを使って環境ごとのドットファイルを管理する。各ブランチには特定の環境の設定ファイルが含まれており、main ブランチにはホスト自動識別に基づいてローカルシステムと Git worktree の間でドットファイルを同期するための管理スクリプト（`nukegara.rb` と `targets.yaml`）が含まれる。

## ブランチ構成

- **main ブランチ**: ドットファイル設定を適用するための管理スクリプトを含む
- **環境ブランチ**: 各ブランチには特定の環境のドットファイルと設定が含まれる
  - `environments/macbook/2025`: macOS 設定（2025年版）
  - `environments/macbook/202410`: macOS 設定（2024年10月版）
  - `win11-kaede-arch`: Windows 11 + Arch Linux サブシステム設定
  - `warabi`: 開発・テスト環境

## 仕組み

### ホスト自動識別
- 各ホストはホスト名（`uname -n`）の MD5 ハッシュで識別される
- `nukegara.rb` スクリプトが現在のホストを自動検出し、`targets.yaml` から一致する設定を探す
- ローカルシステムと適切な Git worktree ディレクトリの間でファイルが同期される

### 設定管理
- `targets.yaml`: ホスト設定、ブランチマッピング、対象ファイルを定義する
- 各ホスト設定で指定するもの:
  - `md5`: ホスト識別用のホスト名 MD5 ハッシュ
  - `branch`: 環境のドットファイルを含む Git ブランチ
  - `targets`: 同期するファイル/ディレクトリのリスト

### master/ ディレクトリ
- `targets.yaml` の `master.path` で設定する共通設定ディレクトリ
- 複数の環境に共通して適用したいファイルを置く場所
- env ブランチと master の同名ファイルは `conflict` として検出される
- `master diff` で差分確認、`master apply` で master の内容を env に反映できる
- `master promote` で env の内容を master に昇格できる（引数なし: 全競合ファイル、パス指定: 特定ファイル）

### 環境ブランチでの作業
- 各環境ブランチは独立していて、独自のドットファイルを持つ
- 複数の環境を同時に扱うには `git worktree` を使う
- 同期方向はコマンドで制御する:
  - `local pull`: ローカル → worktree
  - `local apply`: worktree → ローカル

### ドライランと --execute フラグ
- デフォルトはドライラン（変更内容を表示するだけ）
- `--execute` を付けると確認プロンプトの後に実際にファイルをコピーする

## よく使うコマンド

```bash
# ホストの MD5 ハッシュを取得する
ruby -e "require 'digest/md5'; puts Digest::MD5.hexdigest(\`uname -n\`.strip)"

# 3ステージ（local <-> env <-> master）の差分有無を1行サマリで確認
ruby nukegara.rb health

# ローカルと worktree の差分確認
ruby nukegara.rb local diff

# ローカル → worktree に同期する（ドライラン）
ruby nukegara.rb local pull

# ローカル → worktree に同期する（実行）
ruby nukegara.rb local pull --execute

# worktree → ローカルに反映する（実行）
ruby nukegara.rb local apply --execute

# master と env の差分確認
ruby nukegara.rb master diff

# master の内容を env に反映する（実行）
ruby nukegara.rb master apply --execute

# env の内容を master に昇格する（全競合ファイル、ドライラン）
ruby nukegara.rb master promote

# env の内容を master に昇格する（実行）
ruby nukegara.rb master promote --execute

# 特定のファイルを master に昇格する（実行）
ruby nukegara.rb master promote config/nvim/init.lua --execute

# env worktree の git status を確認する
ruby nukegara.rb git status

# env worktree の変更を全 add する（git add -A）
ruby nukegara.rb git stage

# ステージ済みの変更をコミットする（メッセージ省略時は "update dotfiles"）
# 事前に git stage していないとエラーで終了する
ruby nukegara.rb git commit
ruby nukegara.rb git commit -m "fix tmux config"

# env worktree のブランチを push する
ruby nukegara.rb git push

# このホストの設定ブランチの worktree を作成する（必要ならブランチ作成・push も行う）
ruby nukegara.rb git setup

# 全ブランチ（環境ブランチ含む）を一覧表示する
git branch -a

# 特定の環境の worktree を作成する
git worktree add environments/<environment-branch> <environment-branch>

# 全 worktree を一覧表示する
git worktree list

# worktree を削除する
git worktree remove environments/<environment-branch>
```

## 典型的なワークフロー

1. **初期セットアップ**:
   ```bash
   # ホストの MD5 ハッシュを取得する
   ruby -e "require 'digest/md5'; puts Digest::MD5.hexdigest(\`uname -n\`.strip)"

   # targets.yaml に設定を追加する
   # （md5、branch、対象ファイルを指定する）

   # 設定したブランチの worktree を作成する
   # （ブランチが未作成ならブランチ作成と push も自動で行う）
   ruby nukegara.rb git setup
   ```

2. **ローカルの変更を worktree に同期する**:
   ```bash
   # 差分確認
   ruby nukegara.rb local diff

   # 同期実行
   ruby nukegara.rb local pull --execute
   ```

3. **変更をコミット・プッシュする**:
   ```bash
   # worktree の状態を確認する
   ruby nukegara.rb git status

   # 全変更を add する
   ruby nukegara.rb git stage

   # ステージ済みの変更をコミットする（メッセージは省略可）
   ruby nukegara.rb git commit -m "update dotfiles"

   # push する
   ruby nukegara.rb git push
   ```

4. **別のマシンにデプロイする**:
   ```bash
   # 同じ環境設定を持つマシン上で実行する
   ruby nukegara.rb git setup
   git -C environments/macbook/2025 pull
   ruby nukegara.rb local apply --execute
   ```

## targets.yaml の設定

設定構造の例:

```yaml
master:
  path: master/

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
        exclude:
          - "**/*.log"
      - target: "~/.config/alacritty"
        nukegara: "config/alacritty"
```

- `master.path`: master ディレクトリのパス（省略可）
- `md5`: ホスト名の MD5 ハッシュ（`uname -n` ベース）
- `branch`: この環境のドットファイルを保存する Git ブランチ
- `targets`: ファイル/ディレクトリのマッピングリスト
  - `target`: ローカルシステム上のパス（`~` でホームディレクトリを指定可）
  - `nukegara`: worktree 内の相対パス
  - `exclude`: 同期対象から除外する glob パターンのリスト（省略可）
    - `File.fnmatch` の構文で、各ファイルの base からの相対パスにマッチさせる
    - log ファイルなど worktree に含めたくないファイルを除外するのに使う
    - 全コマンド（diff/pull/apply/promote）に一貫して効く
    - `*` は `/` をまたがない。サブディレクトリ以下も含めるには `**/*.log` のように書く
    - 例: `"**/*.log"`（全階層の `.log`）、`"*.tmp"`（直下のみの `.tmp`）

## 開発メモ

- このリポジトリは環境ごとにブランチを分ける戦略を採用している
- main ブランチには共通ツール（`nukegara.rb`、`targets.yaml`）とドキュメントが含まれる
- 環境ブランチは独立していて環境固有の内容を持つ
- 複数の環境を同時に扱うには git worktree を使う
- `nukegara.rb` は Thor フレームワークを使ったサブコマンド CLI として実装されている
