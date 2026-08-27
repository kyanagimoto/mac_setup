# mac_setup

このリポジトリは、macOS 開発環境の素早いセットアップを補助するものです。

Homebrew、Colima + k3s、zsh の統合設定で、開発環境を一気にセットアップできます。

## 📦 セットアップ内容

- **Homebrew**: パッケージマネージャー（Git、Node.js、Python など）
- **Colima + k3s**: Docker & Kubernetes（macOS起動時に自動起動）
- **GitHub Copilot CLI**: ターミナルから使えるAIコーディングエージェント
- **Ollama**: ローカルでAIモデルを実行する環境（`gemma4:12b` を推奨）
- **VS Code**: 拡張機能とエディター設定をリポジトリで管理
- **Vim / Neovim**: 共通のおすすめ設定 + vim-plug によるプラグイン自動インストール
- **zsh**: 開発者向けシェル設定
  - kubectl / Docker / Git のエイリアス
  - Starship プロンプト統合
  - NVM (Node Version Manager)
  - 便利なコマンド補完・関数

## 🚀 クイックスタート

### 1. リポジトリをクローン

```bash
git clone https://github.com/kyanagimoto/mac_setup.git
cd mac_setup
```

### 2. インストールスクリプトを実行

```bash
chmod +x install.sh
./install.sh
```

### 3. シェルをリロード

```bash
source ~/.zshrc
```

## 📋 スクリプトの詳細説明

### install.sh の処理フロー

1. **Homebrew インストール**
   - 未導入の場合は公式インストーラーを実行

2. **Brewfile からパッケージをインストール**
   - Git、Node.js、Python、kubectl、Docker、Colima など

3. **Colima セットアップ**
   - `colima.yaml` を `~/.colima/default.yaml` にコピー
   - LaunchAgent を設定して、macOS起動時に自動起動するように構成
   - ログ: `/var/log/colima.log`

4. **zsh 設定のセットアップ**
   - 既存の `.zshrc` をバックアップ
   - リポジトリの `.zshrc` を `~/.zshrc` にコピー

5. **オプショナルツールのインストール**
   - Starship（モダンシェルプロンプト）
   - NVM（Node Version Manager）

6. **GitHub Copilot CLI のインストール**
   - Homebrew cask の `copilot-cli` をインストール

7. **VS Code のセットアップ**
   - Vim 拡張機能と Continue 拡張機能をインストール
   - `.vscode/extensions.json` の推奨拡張機能をインストール
   - `.vscode/settings.json` で Vim モードを有効化

8. **Vim / Neovim のセットアップ**
   - Homebrew で `neovim` / `fzf` / `ripgrep` をインストール
   - `vim/vimrc` を `~/.vimrc` と `~/.config/nvim/init.vim` の両方にコピー（既存設定はバックアップ）
   - プラグインマネージャー [vim-plug](https://github.com/junegunn/vim-plug) を Vim / Neovim 双方に自動インストール
   - `:PlugInstall` をヘッドレス実行し、プラグインを自動ダウンロード

## 📁 ファイル説明

### Brewfile
開発に必要なパッケージを定義。Homebrew + Cask で一括インストール。

### colima.yaml
Colima と k3s の設定ファイル。以下をカスタマイズ可能：
- CPU コア数（デフォルト: 4）
- メモリ（デフォルト: 8GB）
- ディスク容量（デフォルト: 100GB）
- Kubernetes バージョン

### .zshrc
包括的なシェル設定ファイル。以下が含まれます：
- Homebrew 環境設定
- kubectl 補完 & エイリアス
- Docker & Colima のエイリアス
- Git のエイリアス
- Starship プロンプト統合
- Git ブランチと現在の Kubernetes context のプロンプト表示
- NVM 統合
- 便利なシェル関数

### .vscode/extensions.json と .vscode/settings.json
VS Code の拡張機能とワークスペース設定を管理します。Vim モードに加えて Continue を導入します。

新しい環境では `./install.sh` 実行時に拡張機能がインストールされます。VS Code CLI が見つからない場合は、VS Code のコマンドパレットから `Shell Command: Install 'code' command in PATH` を実行してから、再度 `./install.sh` を実行してください。

### vim/vimrc
Vim と Neovim 共通で使う設定ファイル。`install.sh` 実行時に `~/.vimrc` と `~/.config/nvim/init.vim` の両方へコピーされます。

主な内容：
- 行番号・相対行番号・検索・インデントなどの基本設定
- 永続Undo、スワップ/バックアップファイルの一元管理
- OSクリップボードとの連携（`clipboard=unnamed,unnamedplus`）
- [vim-plug](https://github.com/junegunn/vim-plug) によるプラグイン管理
  - `gruvbox`（カラースキーム）、`vim-airline`（ステータスライン）
  - `nerdtree`（ファイルツリー）、`fzf.vim`（あいまい検索、ripgrep連携）
  - `vim-fugitive` / `vim-gitgutter`（Git連携）
  - `vim-surround` / `vim-commentary` / `auto-pairs` / `indentLine`（編集効率化）
  - `coc.nvim`（補完・LSP、Node.jsを利用）

## 🛠️ 便利なコマンド

### Colima

```bash
colima start          # 開始
colima stop           # 停止
colima status         # 状態確認
colima-start          # エイリアス: colima start
colima-stop           # エイリアス: colima stop
colima-status         # エイリアス: colima status
```

### Kubernetes

```bash
k get pods            # ポッド一覧（kubectl get pods の短縮）
k get svc             # サービス一覧
k get nodes           # ノード一覧
kctx                  # 現在のコンテキスト表示
kctx <name>           # コンテキスト切り替え
kgetlogs <deployment> # デプロイメントのログを全ポッドから取得
```

### Docker

```bash
d ps                  # コンテナ一覧
d images              # イメージ一覧
dc up                 # Docker Compose 実行
dockerclean           # コンテナ・イメージ・ボリュームをクリーンアップ
```

### Git

```bash
gs                    # git status
ga                    # git add
gc                    # git commit
gp                    # git push
gl                    # git log --oneline
gb                    # git branch
gco                   # git checkout
```

### GitHub Copilot CLI

初回セットアップ後、プロジェクトのディレクトリで `copilot` を実行します。
未ログインの場合は、Copilot CLI の画面内で `/login` を実行して GitHub アカウントを認証してください。

```bash
copilot               # 対話型CLIを起動
copilot --continue     # 直前のセッションを再開
copilot --version      # バージョン確認
```

Copilot CLI は現在のディレクトリ以下のファイルを読み取り、変更、コマンド実行する場合があります。
信頼できるプロジェクトディレクトリで起動し、表示される権限確認を内容ごとに承認してください。

### Vim / Neovim

```bash
vim                  # 新しい設定でVimを起動
nvim                 # 同じ設定でNeovimを起動
```

エディタ内のキーマップ（リーダーキーは Space）：

| キー | 動作 |
| --- | --- |
| `<Space>e` | NERDTree（ファイルツリー）をトグル |
| `<Space>f` | fzfでファイルをあいまい検索 |
| `<Space>g` | ripgrepでプロジェクト内テキスト検索 |
| `<Space>b` | 開いているバッファ一覧をfzfで表示 |
| `<Space>w` | 保存 |
| `<Space>q` | 終了 |
| `Ctrl+h/j/k/l` | 分割ウィンドウ間の移動 |
| `Esc Esc` | 検索ハイライトを消す |

プラグインの追加・更新：

```vim
:PlugInstall   " vim/vimrc に追加したプラグインをインストール
:PlugUpdate    " プラグインを最新化
:PlugClean     " 使われていないプラグインを削除
```

### Ollama

Ollamaは自動インストールされません。公式サイトまたはHomebrewで導入し、セットアップ後にシェルをリロードしてモデルを取得します。

```bash
brew install ollama
brew services start ollama
source ~/.zshrc
ollama pull gemma4:12b
ollama run gemma4:12b
```

モデルの利用可能なタグは [Ollama Library](https://ollama.com/library) で確認してください。

### Continue と Ollama の接続

Ollama本体とContinueの接続設定は自動化せず、Continueの設定画面で入力します。

設定値は次のとおりです。

| 設定 | 値 |
| --- | --- |
| Provider | `Ollama` |
| Base URL | `http://localhost:11434` |
| Model ID | `gemma4:12b` |
| Thinking / Reasoning | `Off` |

Ollamaが起動している状態でContinueを開きます。利用可能なモデルは `ollama list` で確認できます。

Thinking modeで処理が止まって見える場合は、設定のReasoningを無効にしてください。まず無効状態で接続を確認し、必要な場合だけ有効にします。

手動で設定する場合は、VS Codeの拡張機能ビュー（`⇧⌘X`）から **Continue** を開き、設定画面で同じ3項目を入力します。Continueが表示されない場合は、次のコマンドで拡張機能をインストールしてください。

```bash
code --install-extension Continue.continue
```

### macOS

```bash
ll                    # ls -lah（詳細表示）
la                    # ls -lA
showfiles             # 隠しファイルを表示
hidefiles             # 隠しファイルを非表示
```

## ⚙️ カスタマイズ

### Colima の設定を変更

`colima.yaml` を編集してから `install.sh` を実行：

```yaml
cpu: 8          # コア数を増やす
memory: 16      # メモリを増やす
disk: 200       # ディスク容量を増やす
```

### zsh プロンプトのカスタマイズ

Starship を使用している場合、以下で設定：

```bash
mkdir -p ~/.config/starship
cat > ~/.config/starship.toml << 'EOF'
# Starship 設定
add_newline = true
EOF
```

### 新しいエイリアスを追加

`~/.zshrc` を編集して、以下を追加：

```bash
alias mycommand='your-command'
```

その後、`source ~/.zshrc` でリロード。

## ⚠️ 注意点

- **バックアップ**: 既存の `.zshrc` は自動的に `.zshrc.backup.YYYYMMDD_HHMMSS` としてバックアップされます
- **Colima 自動起動**: LaunchAgent で管理されます。手動でアンロードする場合：
  ```bash
  launchctl unload ~/Library/LaunchAgents/com.mac-setup.colima.plist
  ```
- **App Store アプリ**: `mas` を使用する場合は Brewfile に追加し、App Store にサインイン
- **Apple Silicon & Intel**: 自動検出・対応しています

## 📖 トラブルシューティング

### Colima が起動しない

```bash
# ログを確認
tail -f /var/log/colima.log

# 手動で起動してエラーを確認
colima start
```

### kubectl が見つからない

```bash
# 再度インストール
brew install kubectl

# PATH の確認
which kubectl
```

### zsh の設定が反映されない

```bash
# シェルをリロード
source ~/.zshrc

# または新しいターミナルウィンドウを開く
```

### LaunchAgent のトラブル

```bash
# ステータス確認
launchctl list | grep colima

# 再度ロード
launchctl load ~/Library/LaunchAgents/com.mac-setup.colima.plist

# アンロード
launchctl unload ~/Library/LaunchAgents/com.mac-setup.colima.plist
```

## 🔄 アップデート

セットアップを再度実行する場合：

```bash
git pull origin main
./install.sh
```

## 📝 ライセンス

MIT License

## 🤝 貢献

改善案や問題報告は Issue/PR でお願いします。
