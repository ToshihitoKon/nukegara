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
- `master status` で競合ファイルと env だけにあるファイルの一覧、`master diff` で競合ファイルの中身の差分を確認でき、`master apply` で master の内容を env に反映できる
- `master promote` で env の内容を master に昇格できる（引数なし: 全競合ファイル、パス指定: 特定ファイル、`-i`: fzf で選んだファイル）

### 環境ブランチでの作業
- 各環境ブランチは独立していて、独自のドットファイルを持つ
- 複数の環境を同時に扱うには `git worktree` を使う
- 同期方向はコマンドで制御する:
  - `local pull`: ローカル → worktree
  - `local apply`: worktree → ローカル

### ドライランと --execute フラグ
- デフォルトはドライラン（変更内容を表示するだけ）
- `--execute` を付けると確認プロンプトの後に実際にファイルをコピーする
- `-i` を付けたときは、`--execute` なしで確認プロンプトまで進む（次節）

### -i でファイルを選んで同期する
- `local pull` / `local apply` / `master promote` / `master apply` に `-i`（`--interactive`）を付けると、そのコマンドで書き換わるファイルを fzf で一覧し、選んだファイルだけを同期する
  - space で選んで Enter で確定すると、`--execute` と同じ確認（対象一覧と `Proceed with N change(s)? [y/N]`）に進み、y で実行する
    - 一覧で選ぶ操作と y/N の確認をドライランの代わりにするため、`--execute` は要らない
  - 1 つも選ばずに Enter を押すと、カーソルのある 1 ファイルが対象になる（fzf の標準の挙動）
  - Esc / ctrl-c で中断したときや、1 つも選ばず絞り込みで 1 件も残らないまま Enter を押したときは、何も書き換えない
    - 選んだファイルは、絞り込みで一覧から消えても選んだまま残る
  - 確認に出す一覧は、選んだ順ではなく fzf に渡した元の一覧の順（`status` と同じ並び）に並べる
    - 検索語を入れたあとの画面上の並びとは違うことがある
  - キーマップは fzf の標準のまま変えない。space だけは選択の切り替えに割り当て、押してもカーソルを動かさない（`--bind space:toggle`）
    - fzf の標準で選択に使う Tab は、HHKB などのキーボードで押しにくいため
    - Tab も fzf の標準どおり（選択を切り替えて次の行へ移る）使える
    - space を選択に使うため、絞り込みの検索語に空白は打てない
  - 画面の見た目
    - header には操作名（例: `master promote: env -> master`）だけを出し、一覧との間に区切り線を引く。キーの説明は区切り線上のラベルに出す
    - 選んだ行には太字の緑の `+` を付け、背景を暗い緑（256 色の 22）にする
      - 背景色に灰色を使わないのは、カーソル行の背景が灰色のため。赤系を使わないのは、`[conflict]` のラベルが赤のため
    - カーソル行ではカーソルの背景が選択の背景より優先されるため、選んだかどうかは `+` のマーカーだけで見分ける
      - fzf の配色には、カーソル行かつ選択中の行に使う色がない
  - 候補があるのに fzf が無いときや、fzf がエラーで終わったときは、エラーで終了する
- `master promote -i` は、差分のある競合ファイルに加えて env だけにあるファイルも候補にする
  - 引数なしの promote は競合ファイルだけを対象にするが、パスを指定した promote は env だけにあるファイルも受け付けるため、それに合わせる
  - パスと `-i` は同時に渡せない
- preview には、書き込み先の今の中身から書き込まれる中身への diff を `git diff --no-index` で出す
  - `+` の行が書き込まれる内容になる
    - `local apply -i` と `master apply -i` では、`local diff` / `master diff` と左右が逆になる
    - preview の枠線上のラベルにも `+` の意味を出す
  - fzf の各行に 2 つのパスを持たせ、preview では git だけを実行する
    - カーソルを動かすたびに `nukegara.rb` を起動しないため
  - シンボリックリンクは `File.realpath` でリンク先のパスにしてから渡す
    - `git diff --no-index` はシンボリックリンクをリンクそのものとして比べるため
  - 書き込み先が無いファイルや、リンク切れなどで解決できないパスは `/dev/null` として渡す
  - `diff` コマンドと違ってコピーを挟まないため、中身と一緒に権限も違うファイルでは `old mode` / `new mode` の行も出る
  - preview は一覧の右に半分の幅で置き、その幅が 80 桁未満（端末の幅がおよそ 160 桁未満）のときは一覧の下に置く

### status と diff
- `status` はファイルごとに `[differ]` や `[conflict]` などの種類とパスだけを 1 行で出し、中身は出さない
  - `local status`: local と env で中身が違うファイルと、片側にしかないファイル
  - `master status`: master と env で中身が違う競合ファイルと、env だけにあるファイル
- `local diff` / `master diff` は差分のあるファイルの diff を `git diff --no-index` で出す
  - パスを渡すとそのファイルだけ、渡さなければ全ファイル分を出す
    - パスは `status` に出る形（env worktree からの相対パス。例: `config/nvim/init.lua`）で渡す
    - `master diff` が受け付けるのは `[conflict]` のパスだけ
  - 比べるファイルを一時ディレクトリの `worktree/` と `local/`（master は `master/` と `env/`）にコピーし、2 つのディレクトリを git で 1 回だけ比べる
    - git をファイルごとに実行すると、ファイルごとに pager が開くため
    - pager や色付けは、ユーザーの git 設定（global）どおりに効く
  - 比べるのは中身だけで、ファイルの権限の違いは diff に出さない（`status` も中身だけで比べる）
  - ファイルへのシンボリックリンクは、リンク先の中身で diff を出す
    - コピーにはリンク先の中身が入るため、`status` や pull/apply と同じ中身で比べられる
    - リンク切れなど読めないファイルは、無いものとして diff を出す

### 次の操作の案内
- 続けて実行すべき操作があるとき、各コマンドは最後に `Next:` ブロックで次に実行するコマンドを表示する
  - 表示は `NukegaraHelpers#print_next_steps`（順に実行する案内）と `#print_next_choices`（どちらか一方を選ぶ案内）に集約している
  - 案内するコマンドは PATH 上の `nukegara`（`nukegara.rb` へのシンボリックリンク）で書く
- 説明の行とコマンドの行を分け、コマンドは 1 行に 1 つだけ出す
  - コマンドの行をそのままコピペして実行できるようにする
  - 行末に `# 説明` を付けると、`interactive_comments` が無効な zsh では引数として渡ってしまう
  - 例外として、`status` の後の `diff` の案内はパスを `<path>` のプレースホルダーで書く
    - `status` に出たパスに置き換えて実行する
- 同期の向きのように、どちらか一方だけを選ぶ案内は見出しを `Next (pick one):` にする
  - 見出しが `Next:` の案内は、上から順に実行するものとして並べる
- `--execute` を取るコマンドは、ドライランの後の案内でだけ `--execute` 付きで出し、それ以外の案内ではフラグなしで出す
- 次に必要な操作がないときは `Next:` ブロックを出さない
  - 例: 差分がないとき、`local apply --execute`・`master promote --execute`・`git push` の後
- `health` は `git fetch` してから env worktree の未コミット・ahead・behind も数え、案内では env <-> remote を最初に出す
  - リモートより古い env のまま local と同期すると、別マシンからの push と食い違う
  - fetch に失敗したときはサマリに `(fetch failed)` を付け、手元のリモート追跡ブランチで数える
- 差分の案内は `health` → `status` → `diff` の順につなぎ、同期（pull/apply、promote/apply）は `diff` の後に案内する
  - `master diff` にパスを渡したときは、promote の案内もそのパスに絞る
    - 1 ファイルだけ見た直後に全競合ファイルの promote を案内すると、見ていないファイルまで env の内容で上書きしかねないため
    - パスを渡さないときは全ファイル分の diff を出すので、promote の案内は絞らない

## よく使うコマンド

```bash
# ホストの MD5 ハッシュを取得する
ruby -e "require 'digest/md5'; puts Digest::MD5.hexdigest(\`uname -n\`.strip)"

# fetch してから local <-> env <-> master と env <-> remote の差分有無を1行サマリで確認する
# （差分があれば次に実行するコマンドも表示する）
ruby nukegara.rb health

# ローカルと worktree で差分のあるファイルを一覧する
ruby nukegara.rb local status

# 差分のある全ファイルの diff を pager で見る（パスを渡すとそのファイルだけ）
ruby nukegara.rb local diff
ruby nukegara.rb local diff config/nvim/init.lua

# ローカル → worktree に同期する（ドライラン）
ruby nukegara.rb local pull

# ローカル → worktree に同期する（実行）
ruby nukegara.rb local pull --execute

# worktree → ローカルに反映する（実行）
ruby nukegara.rb local apply --execute

# 同期するファイルを fzf で選び、確認の後に実行する
ruby nukegara.rb local pull -i
ruby nukegara.rb local apply -i

# master と env で競合しているファイルと env だけにあるファイルを一覧する
ruby nukegara.rb master status

# 競合している全ファイルの diff を pager で見る（パスを渡すとそのファイルだけ）
ruby nukegara.rb master diff
ruby nukegara.rb master diff config/nvim/init.lua

# master の内容を env に反映する（実行）
ruby nukegara.rb master apply --execute

# env の内容を master に昇格する（全競合ファイル、ドライラン）
ruby nukegara.rb master promote

# env の内容を master に昇格する（実行）
ruby nukegara.rb master promote --execute

# 特定のファイルを master に昇格する（実行）
ruby nukegara.rb master promote config/nvim/init.lua --execute

# 昇格・反映するファイルを fzf で選び、確認の後に実行する
ruby nukegara.rb master promote -i
ruby nukegara.rb master apply -i

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

# env worktree のブランチを pull する
ruby nukegara.rb git pull

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
   # 差分のあるファイルを確認する
   ruby nukegara.rb local status

   # 中身の差分を確認する
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
   ruby nukegara.rb git pull
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
    - 全コマンド（status/diff/pull/apply/promote）に一貫して効く
    - `*` は `/` をまたがない。サブディレクトリ以下も含めるには `**/*.log` のように書く
    - 例: `"**/*.log"`（全階層の `.log`）、`"*.tmp"`（直下のみの `.tmp`）

## 開発メモ

- このリポジトリは環境ごとにブランチを分ける戦略を採用している
- main ブランチには共通ツール（`nukegara.rb`、`targets.yaml`）とドキュメントが含まれる
- 環境ブランチは独立していて環境固有の内容を持つ
- 複数の環境を同時に扱うには git worktree を使う
- `nukegara.rb` は Thor フレームワークを使ったサブコマンド CLI として実装されている
