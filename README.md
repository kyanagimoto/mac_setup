# mac_setup

このリポジトリは、macOS 開発環境の素早いセットアップを補助するものです。

ルートに Brewfile があり、Homebrew（未導入であれば自動でインストール）を使って一括でパッケージを導入できます。

また、Colima + k3s の自動起動設定も含まれており、macOS起動時に自動的に Colima k3s が起動するようにセットアップできます。

## 使い方

1. リポジトリをクローンします

   ```bash
   git clone https://github.com/kyanagimoto/mac_setup.git
   cd mac_setup
   ```

2. スクリプトに実行権限を付与して実行します

   ```bash
   chmod +x install.sh
   ./install.sh
   ```

## スクリプトの説明

### install.sh
  - Homebrew がインストールされていない場合は公式インストーラーを実行します。
  - brew bundle を使ってルートの Brewfile から formula/cask/mas を一括インストールします（Brewfile が存在する場合）。
  - brew cleanup を実行します。
  - **Colima の設定と自動起動**: `colima.yaml` をコピーし、macOS LaunchAgent を設定して、起動時に自動的に Colima が起動するようにします。

### colima.yaml
  - Colima と k3s の設定ファイルです。CPU、メモリ、ディスク容量などをカスタマイズできます。
  - デフォルトで k3s が有効になっており、kubectl でアクセス可能です。

## 注意点

- mac App Store のアプリを自動でインストールするには 'mas' を Brewfile に追加し、App Store へサインインしておく必要があります（例: mas "497799835" など）。
- Apple Silicon と Intel の両アーキテクチャに対応するため、brew のパス設定をスクリプト内で試みますが、シェルの初期化ファイル（~/.zprofile や ~/.bash_profile など）に `eval "$(brew shellenv)"` を追加することをお勧めします。
- スクリプトは重要な操作を行います。実行前に Brewfile の内容を確認し、必要に応じてパッケージを編集してください。
- Colima の自動起動は LaunchAgent で管理されます。ログは `/var/log/colima.log` で確認できます。

## Colima コマンド

- 手動で起動: `colima start`
- 停止: `colima stop`
- ステータス確認: `colima status`
- LaunchAgent の状態確認: `launchctl list | grep colima`

Brewfile の内容例はリポジトリルートの Brewfile を参照してください。
