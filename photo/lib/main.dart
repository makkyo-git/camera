import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_gallery_saver/image_gallery_saver.dart';


Future <void> main() async {
  // main関数内で非同期処理を呼び出すための設定
  WidgetsFlutterBinding.ensureInitialized();

  // デバイスで使用可能なカメラのリストを取得
  final cameras = await availableCameras();

  // 利用可能なカメラのリストから特定のカメラを取得
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));

}

class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
    required this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'カメラ機能',
      theme: ThemeData(),
      home: TakePictureScreen(camera: camera),
    );
  }
}


class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      // カメラを指定
      widget.camera,
      // 解像度を定義
      ResolutionPreset.medium,
    );

    // コントローラーを初期化
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // ウィジェットが破棄されたら、コントローラーを破棄
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendPhoto(File photo) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://IPアドレス(例:0.0.0.0:8000)/process/request/'),);
    request.files.add(http.MultipartFile.fromBytes('photo', await photo.readAsBytes(), filename: 'photo.png',));

    try {
      var response = await request.send();

      if (response.statusCode == 200) {

        var contentBytes = await response.stream.toBytes();
        var base64Image = base64Encode(contentBytes);

        //表示用の画面に移動
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DisplayProcessedPictureScreen(imagePath: 'data:image/png;base64,$base64Image'),
            fullscreenDialog : true,
          ),
        );
      } else {
        // 失敗時の処理
        print('デバッグのコード:レスポンスステータスコード = ${response.statusCode}');
      }
    }  catch (e) {
      // エラー時の処理
      print('デバッグのコード: エラーが発生しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // FutureBuilderで初期化を待ってからプレビューを表示 (それまではインジケータを表示)
        child: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return CameraPreview(_controller);
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 写真を撮る
          final image = await _controller.takePicture();
          await _sendPhoto(File(image.path));
          // 表示用の画面に遷移
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DisplayPictureScreen(imagePath: image.path),
              fullscreenDialog: false,
            ),
          );
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

// 撮影した写真を表示する画面
class DisplayPictureScreen extends StatelessWidget {
  const DisplayPictureScreen({super.key, required this.imagePath})  ;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          '通常',
          style: TextStyle(
            color: Colors.white, // 文字の色を白色に設定
            fontWeight: FontWeight.bold, // 文字を太字
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.file(File(imagePath)),
            SizedBox(
                height: 20,
                width: 80),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: () {
                      // 「保存する」ボタンを押した時の処理
                      _saveImage(context, imagePath);
                    },
                    child: Text(
                      '保存する',
                      style: TextStyle(
                        color: Colors.white, //テキストを白字に設定
                        fontWeight: FontWeight.bold, //テキストを太字
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                    )
                ),
                SizedBox(
                    height: 20,
                    width: 80),
                ElevatedButton(
                    onPressed: () {
                      // 「撮り直す」ボタンが押された時の処理
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      '撮り直す',
                      style: TextStyle(
                        color: Colors.white, //テキストを白字に設定
                        fontWeight: FontWeight.bold, //テキストを太字
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
                    )



                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveImage(BuildContext context, String imagePath) async {
    try {
      final result =await ImageGallerySaver.saveFile(imagePath);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('画像が保存されました')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('画像の保存に失敗しました')),
        );
      }
    } catch (e) {
      print('画像の保存時にエラーが発生しました: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像の保存時にエラーが発生しました')),
      );
    }
  }
}

// 処理後の画像を受け取る
class DisplayProcessedPictureScreen extends StatefulWidget {
  final String imagePath;

  const DisplayProcessedPictureScreen({super.key, required this.imagePath});

  @override
  DisplayProcessedPictureScreenState createState() =>
      DisplayProcessedPictureScreenState();
}

class DisplayProcessedPictureScreenState extends State<DisplayProcessedPictureScreen> {
  Future<http.Response>? _fetchImageFuture;

  @override
  void initState() {
    super.initState();
    _fetchImage();
  }

  Future<void> _fetchImage() async {
    final base64Image = widget.imagePath
        .split(',')
        .last;

    final decodedBytes = base64Decode(base64Image);

    setState(() {
      _fetchImageFuture =
          Future.value(http.Response.bytes(decodedBytes, 200, headers: {
            HttpHeaders.contentTypeHeader: 'image/png',
          }));
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.redAccent,
          title: const Text(
              'ノスタルジック',
              style: TextStyle(
                color: Colors.white, // 文字の色を白に設定
                fontWeight: FontWeight.bold, // 文字を太字
              ))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            FutureBuilder<http.Response>(
              future: _fetchImageFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final response = snapshot.data!;
                  if (response.statusCode == 200) {
                    final responseData = response.bodyBytes;
                    return Transform.rotate(
                      angle: 90 * pi /180,
                      child:// 反時計回りに90度回転
                      Image.memory(
                        responseData,
                        fit: BoxFit
                            .contain,
                      ),  // 画像をウィジェット内に適切に表示させるために適応させるfitパラメータを追加
                      alignment: Alignment.center, //回転の中心を設定
                    );
                  } else {
                    // レスポンスが不正なステイタスコードを返した場合のエラーメッセージ
                    return Text('画像の取得中にエラーが発生しました。');
                  }
                }
                return const CircularProgressIndicator();
              },
            ),
            SizedBox(height: 80),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // 「保存する」ボタンを押した時の処理
                    _savedImage(context, widget.imagePath);
                  },
                  child: Text(
                    '保存する',
                    style: TextStyle(
                      color: Colors.white, // テキストを白字に設定
                      fontWeight: FontWeight.bold, // テキストを太字
                    ),
                  ),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.blue), //ボタンの背景色を青色に設定
                  ),

                ),
              ],

            ),
            SizedBox(height: 10),

            ElevatedButton(
                onPressed: () {
                  // 「撮り直す」ボタンが押された時の処理
                  Navigator.of(context).pop();
                },
                child:Text(
                  '破棄',
                  style: TextStyle(
                    color: Colors.white, // テキストを白色に設定
                    fontWeight: FontWeight.bold, // テキストを太字
                  ),
                ),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.red), //ボタンの背景色を赤色に設定
                )
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savedImage(BuildContext context, String imagePath) async {
    try {
      final base64Image = widget.imagePath
          .split(',')
          .last;

      final decodedBytes = base64Decode(base64Image);

      final rotatedBytes = await _rotatedImage(decodedBytes, 90);


      // 画像を保存
      final result = await ImageGallerySaver.saveImage(rotatedBytes);

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('画像が保存されました')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('画像の保存に失敗しました')),
        );
      }
    } catch (e) {
      print('画像の保存時にエラーが発生しました: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像の保存時にエラーが発生しました')),
      );
    }
  }
  Future<Uint8List> _rotatedImage(Uint8List imageBytes, double angle) async {
    // 画像をデコード
    final image = await decodeImageFromList(imageBytes);

    // 回転後のサイズを計算
    final double radians = angle * ( pi / 180);
    final double sine = sin(radians);
    final double cosin = cos(radians);
    final double newWidth = (image.width * cosin + image.height * sine).abs();
    final double newHeight = (image.width * sine + image.height * cosin).abs();

    // 新しいサイズのキャンバスを作成
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromPoints(Offset(0.0,0.0), Offset(newWidth, newHeight)));

    // 画像を描画して回転
    canvas.translate(newWidth / 2, newHeight / 2);
    canvas.rotate(radians);
    canvas.drawImage(image, Offset(-image.width / 2, -image.height / 2), Paint());

    // キャンバスを終了し、画像を取得
    final picture = recorder.endRecording();
    final img = await picture.toImage(newWidth.toInt(), newHeight.toInt());
    final byteData = await img.toByteData(format: ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }
}