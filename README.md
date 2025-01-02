このアプリケーションは、flutterとDjangoを使用しています。 なので、このアプリケーションを動かす際は、スマホとパソコンを同期し、 Xcodeというデベロッパーツールをインストールして、 スマホでテストができる環境を作ってください。

用意ができましたら、

backend/processed_photo内で、

`$ python manage.py runserver IPアドレス(例:0.0.0.0:8000)`

と、ターミナルで入力し、

front/take_photoディレクトリ内で、

`$ flutter run`

と、ターミナルで入力すると、アプリケーションが動きます。
