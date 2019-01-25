# KnzkLiveOBSOpener
KnzkLiveのサーバー情報を自動でOBSに設定した上で起動します。

**IMPORTANT**: HSPエディタの仕様上 *.hsp はShift_JISが使用されています。

## License
installer.hsp / obsopener.hsp: MPL-2.0   
modules/*, *.dll: 各プログラム作者に帰属します。

## インストール / 使い方

##### 1. ダウンロード
https://github.com/KnzkDev/KnzkLiveOBSOpener/releases/latest の、`Openerinstall.exe` をダウンロードしてください。

##### 2. Openerインストーラを開く
自動でインストールされます。 `%AppData%\KnzkLiveOBSOpener` にインストールされます。

##### 3. 初期設定をする
デスクトップに作成された `KnzkLive で配信を始める` を開いてください。  
初回起動時は初期設定が行われます。途中ダイアログが表示されますが指示に従ってください。

##### 4. 起動する
`KnzkLive で配信を始める` を開くと、配信枠が既に作成されていればサーバー情報を自動設定した上でOBSが起動します。  
作成されていなければブラウザの配信枠作成画面が開きます。

## アンインストール
`%AppData%\KnzkLiveOBSOpener` を全て削除して、デスクトップのショートカットを削除してください。