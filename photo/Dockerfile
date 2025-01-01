# Flutter公式アプリのDockerイメージをベースにする
FROM cirrusci/flutter:stable AS builder

# 作業ディレクトリを設定
WORKDIR /app

# ホスト側のプロジェクトファイルをコンテナ内にコピー
COPY . .

# 非rootユーザーを作成
RUN useradd -ms /bin/bash flutteruser

# rootユーザーで実行
USER root

# Androidシュミレータやビルドをサポートするために必要な依存パッケージをインストール
RUN apt-get update && apt-get install -y sudo \
    bash \
    git \
    curl \
    xz-utils \
    libglu1-mesa \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

# CocoaPodsのインストール
RUN gem install cocoapods

# Flutter SDKを一度削除して、再クローン
RUN rm -rf /sdks/flutter && git clone https://github.com/flutter/flutter.git /sdks/flutter

# Flutter SDKの権限を修正 (lockfileの読み書きができるようにする)
RUN chown -R flutteruser: /sdks/flutter

# プロジェクトディレクトリにも書き込み権限を付与
RUN chown -R flutteruser: /app

# flutteruserに切り替え
USER flutteruser

# stable チャンネルに切り替え
RUN cd /sdks/flutter && flutter channel stable

# Flutter SDKとDart SDKのバージョンを確認(アップデート)
RUN cd /sdks/flutter && flutter upgrade

# Flutter SDKの初期設定を行う
RUN cd /sdks/flutter && flutter doctor

# Flutterのキャッシュと依存関係を再取得
WORKDIR /app
RUN flutter clean
RUN flutter pub get

# iOSの依存関係を管理するCocoaPodsのインストール
WORKDIR /app/ios
RUN pod cache clean --all
RUN pod install

# XCodeの設定を確認
RUN open ios/Runner.xcworkspace

#  Flutterの依存関係をプロジェクトルート(/app)でインストール
WORKDIR /app
RUN flutter pub get

# エミュレータや`flutter run`を使うために必要な環境変数を設定
ENV DISPLAY=:99

# Flutterエミュレータを起動するために`xvfb-run`(X仮想フレームバッファ)を使用
CMD ["xvfb-run", "flutter", "run", "--web"]
