# Prove2Me 用 使い捨てLinode VM 自動化キット

やりたいこと: 「VM作成 → 環境構築 → 作業 → VM削除」を、手作業をなるべく減らして回す。
スクリプト自体の修正は、手作業ではなくWSL2上のClaude Code経由で行う。

## 構成ファイル

- `setup.sh` — VM上で実行される実際の構築処理(Node.js/Claude Code/elan/Prove2Meワークスペース/Mathlibキャッシュ)
- `prove2me-stackscript.sh` — Linode StackScript本体。中身は薄く、起動時に`setup.sh`をGitHubから取得して実行するだけ
- `start.sh` — WSL側で叩く。VMを作成する
- `stop.sh` — WSL側で叩く。VMを削除する(=課金停止)
- `.env.example` — 環境変数のテンプレート

**ポイント:** `prove2me-stackscript.sh`自体はLinode管理画面に一度貼ったら基本触らない。
実際の構築内容を変えたいときは`setup.sh`をGitHub上で直すだけで、次回`start.sh`実行時から反映される。

---

## 0. 事前準備(最初の1回だけ)

### 0-1. WSL2にGit・Node.js・Claude Code・linode-cliを入れる

```bash
# git, python(linode-cli用)
sudo apt-get update
sudo apt-get install -y git python3-pip

# Node.js (Claude Code用)
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# Claude Code
npm install -g @anthropic-ai/claude-code

# linode-cli
pip3 install linode-cli --user
export PATH="$HOME/.local/bin:$PATH"   # ~/.bashrc に追記推奨
```

### 0-2. GitHubリポジトリを作る

このリポジトリ一式(`setup.sh`, `prove2me-stackscript.sh`, `start.sh`, `stop.sh`,
`.gitignore`, `.env.example`, `README.md`)をGitHubの新規リポジトリにpushする。
公開設定は **public** を推奨(中身に秘密情報を含まない設計のため。理由は後述)。

```bash
gh auth login          # 未認証なら
cd prove2me-vm-kit
git init
git add .
git commit -m "Initial commit"
gh repo create prove2me-vm-kit --public --source=. --push
```

### 0-3. `prove2me-stackscript.sh` 内のGitHubパスを自分のものに書き換える

```bash
# prove2me-stackscript.sh の中の
# REPO_RAW_BASE="https://raw.githubusercontent.com/hnagoya/prove2me-vm-kit/master"
# を自分のユーザー名に置き換えて commit & push
```
（この修正自体もClaude Code経由で行ってOK。後述の「日常の使い方」参照）

### 0-4. Linode APIトークンを作成してlinode-cliを設定

Linode Cloud Manager → プロフィールアイコン → **API Tokens** → **Create a Personal Access Token**。
`Linodes` に Read/Write権限を与えて作成。

```bash
linode-cli configure
```

### 0-5. StackScriptをLinodeに登録

1. Linode Cloud Manager → **Compute > StackScripts** → **Create StackScript**
2. `prove2me-stackscript.sh`(0-3で書き換え済みのもの)の中身を貼り付け
3. Target OS: Ubuntu 24.04
4. 保存後に発行される **StackScript ID** を控える

### 0-6. 自己破壊用トークン(任意だが推奨)

0-4と同様に**別の**トークンを作成(`Linodes` Read/Write権限)。専用に用意するのが安全。

### 0-7. .envを作る

```bash
cp .env.example .env
vim .env    # STACKSCRIPT_ID, DESTROY_TOKEN, DESTROY_HOURS を埋める
source .env
```

`.env`は`.gitignore`済みなのでコミットされない。

---

## 1. 日常の使い方

### VMを立てる

```bash
source .env    # 環境変数を読み込む(シェルを開き直した時は毎回)
./start.sh
```

数分待つと、SSH接続先IPとコマンド例が表示される。

### セットアップ完了を確認

```bash
ssh root@<表示されたIP> 'tail -f /var/log/prove2me-setup.log'
```
末尾に `All done. Ready for: claude` と出たら準備完了。

### 作業する

```bash
ssh root@<IP>
claude
```

Claude Code内で:
```
Fetch https://prove2.me/start.md and follow it to set yourself up
for Prove2Me. Log in with my Prove2Me API key <あなたのAPIキー>
```

その後:
```
Work on <ミッション名> on Prove2Me. Pick an open statement from its
frontier and submit a proof.
```

### 終わったらVMを消す

```bash
./stop.sh
```

**電源オフだけでは課金が続くので、必ずこのスクリプトで削除すること。**

---

## 2. スクリプト自体の修正はClaude Code経由で

このリポジトリ自体の修正(`start.sh`のインスタンスサイズを変える、
`setup.sh`に手順を追加する、など)は、WSL2上でこのディレクトリを開いて
Claude Codeに指示するだけで完結する。

```bash
cd ~/prove2me-vm-kit
claude
```

Claude Code内で例えば:
```
stop.sh の実行時に、削除前に確認プロンプトを出すようにして
```
```
setup.sh に、Lean用のVSCode拡張の代わりにCLIだけで完結する
補完チェックコマンドを追加して
```
```
変更をコミットしてpushして
```

これで手作業でのファイル編集・git操作を挟まずに、リポジトリを育てていける。

---

## 3. 安全弁: 自己破壊タイマー

`DESTROY_TOKEN`を設定していれば、VM起動から`DESTROY_HOURS`時間後に
VM自身がLinode APIを呼び出して自分を削除する。`stop.sh`を叩き忘れても、
青天井で課金され続ける事態を防げる。

途中で長時間の作業が必要と分かった場合は、SSH接続後に以下でタイマーを解除できる:
```bash
systemctl stop prove2me-self-destruct.timer 2>/dev/null || true
```

---

## 4. なぜpublicリポジトリで問題ないか

- `setup.sh`・`prove2me-stackscript.sh`には秘密情報を一切含めない設計
- `DESTROY_TOKEN`などの認証情報は`.env`(gitignore済み)経由でのみ実行時に渡す
- Linode側もUDF(StackScript実行時の入力フォーム)経由でのみトークンを受け取るので、
  スクリプトの「中身」自体は公開されても実害がない

---

## 5. カスタマイズ

- `start.sh`内の`TYPE="g6-dedicated-4"`を変更すればインスタンスサイズを調整可能
  (メモリを増やしたい場合は`g6-dedicated-8`など)
- `REGION`は好きなデータセンターに変更可能(`linode-cli regions list`で一覧表示)
- Mathlibキャッシュ取得(`lake exe cache get`)が失敗した場合、初回の
  `lake build`実行時にソースからビルドされる(時間がかかるが動く)
