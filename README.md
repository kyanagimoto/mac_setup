# mac_setup

このリポジトリは、macOS 開発環境の素早いセットアップを補助するものです。

Homebrew、Colima + k3s、zsh の統合設定で、開発環境を一気にセットアップできます。

## 📦 セットアップ内容

- **Homebrew**: パッケージマネージャー（Git、Node.js、Python など）
- **Colima + k3s**: Docker & Kubernetes（macOS起動時に自動起動）
- **GitHub Copilot CLI**: ターミナルから使えるAIコーディングエージェント
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
- NVM 統合
- 便利なシェル関数

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
