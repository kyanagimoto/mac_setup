# mac_setup

このリポジトリは、macOS 開発環境の素早いセットアップを補助するものです。

ルートに Brewfile があり、Homebrew（未導入であれば自動でインストール）を使って一括でパッケージを導入できます。

使い方

1. リポジトリをクローンします

   git clone https://github.com/kyanagimoto/mac_setup.git
   cd mac_setup

2. スクリプトに実行権限を付与して実行します

   chmod +x install.sh
   ./install.sh

スクリプトの説明

- install.sh
  - Homebrew がインストールされていない場合は公式インストーラーを実行します。
  - brew bundle を使ってルートの Brewfile から formula/cask/mas を一括インストールします（Brewfile が存在する場合）。
  - brew cleanup を実行します。

注意点

- mac App Store のアプリを自動でインストールするには 'mas' を Brewfile に追加し、App Store へサインインしておく必要があります（例: mas "497799835" など）。
- Apple Silicon と Intel の両アーキテクチャに対応するため、brew のパス設定をスクリプト内で試みますが、シェルの初期化ファイル（~/.zprofile や ~/.bash_profile）に手動で追加する必要がある場合があります。
- スクリプトは重要な操作を行います。実行前に Brewfile の内容を確認し、必要に応じてパッケージを編集してください。

Brewfile の内容例はリポジトリルートの Brewfile を参照してください。
