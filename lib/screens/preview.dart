
import 'dart:io' as io;
import 'dart:isolate' as isl;
import 'dart:convert' as cvrt;
import 'dart:async' as asyncx;

import 'package:image/image.dart' as img;
import 'package:flutter/material.dart' as fm;
import 'package:file_picker/file_picker.dart' as fp;
import 'package:image_picker/image_picker.dart' as imgp;
import 'package:path_provider/path_provider.dart' as pd;
import 'package:flutter_isolate/flutter_isolate.dart' as fi;

class PreviewScreen extends fm.StatefulWidget {
  final dynamic imageFile;

  const PreviewScreen({ required this.imageFile, super.key });

  @override
  fm.State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends fm.State<PreviewScreen> {
  final isl.ReceivePort _mainThreadReceiver = isl.ReceivePort();

  final asyncx.StreamController<String> _workerResponse = asyncx.StreamController<String>();

  late final isl.SendPort _workerThreadSendPort;

  late final fi.FlutterIsolate _workerThread;

  fm.Widget _featureButton(fm.Widget icon) {
    return fm.GestureDetector(
      onTap: () {},
      child: icon,
    );
  }

  @override
  void initState() {
    super.initState();

    fi.FlutterIsolate.spawn(readAndRotateImage, _mainThreadReceiver.sendPort).then((t) async {
      _workerThread = t;

      _mainThreadReceiver.listen((msg) {
        if (msg is isl.SendPort) {
          _workerThreadSendPort = msg;

          final String imgPath = cvrt.base64Encode(cvrt.utf8.encode(widget.imageFile is imgp.XFile
            ? (widget.imageFile as imgp.XFile).path
            : (widget.imageFile as fp.FilePickerResult).paths[0]!));

          _workerThreadSendPort.send('image@read-rotate.$imgPath');
        }

        if (msg is String) {
          _workerResponse.sink.add(msg);
        }
      }); 
    });
  }

  @override
  void dispose() {
    _workerThread.kill();

    _mainThreadReceiver.close();
    _workerResponse.close();

    super.dispose();
  }

  @override
  fm.Widget build(fm.BuildContext context) {
    return fm.Scaffold(
      appBar: fm.AppBar(
        backgroundColor: const fm.Color(0xff000000),
        actions: [
          fm.TextButton(
            onPressed: () {},
            child: fm.Row(
              children: const [
                fm.Text('Save', style: fm.TextStyle(fontSize: 16, color: fm.Color(0xffffffff))),

                fm.SizedBox(width: 4),

                fm.Icon(fm.Icons.done, size: 26, color: fm.Color(0xffffffff)),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const fm.Color(0xff000000),
      body: fm.Column(
        children: [
          fm.Container(
            padding: const fm.EdgeInsets.all(8.0),
            height: fm.MediaQuery.of(context).size.height * 0.64,
            decoration: const fm.BoxDecoration(
              color: fm.Color(0xff000000),
            ),
            child: fm.Center(
              child: fm.StreamBuilder<String>(
                stream: _workerResponse.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.contains('image@read-rotate:done.')) {
                    return fm.Image.file(io.File(
                      String.fromCharCodes(cvrt.base64Decode(snapshot.data!.split('.')[1]))));
                  }

                  return const fm.Text('opening image', style: fm.TextStyle(fontSize: 16, color: fm.Color(0xffffffff)));
                },
              ),
            ),
          ),

          const fm.SizedBox(height: 16),

          const fm.Divider(height: 8, color: fm.Color(0xffffffff)),

          const fm.SizedBox(height: 16),

          fm.SizedBox(
            height: 64,
            width: double.infinity,
            child: fm.Center(child:
              fm.ListView(
                shrinkWrap: true,
                scrollDirection: fm.Axis.horizontal,
                children: [
                  _featureButton(const fm.Padding(
                    padding: fm.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: fm.Icon(fm.Icons.font_download, size: 32, color: fm.Color(0xffffffff)),
                  )),
                  _featureButton(const fm.Padding(
                    padding: fm.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: fm.Icon(fm.Icons.opacity, size: 32, color: fm.Color(0xffffffff)),
                  )),
                  _featureButton(const fm.Padding(
                    padding: fm.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: fm.Icon(fm.Icons.rotate_left, size: 32, color: fm.Color(0xffffffff)),
                  )),
                  _featureButton(const fm.Padding(
                    padding: fm.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: fm.Icon(fm.Icons.zoom_in_map_rounded, size: 32, color: fm.Color(0xffffffff)),
                  )),
                  _featureButton(const fm.Padding(
                    padding: fm.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: fm.Icon(fm.Icons.brightness_medium_outlined, size: 32, color: fm.Color(0xffffffff)),
                  )),
                ],
              ),
            ),
          ), 
        ],
      ),
    );
  }
}

@pragma('vm:entry-point')
void readAndRotateImage(isl.SendPort sendPort) {
  final isl.ReceivePort workerThreadReceiver = isl.ReceivePort();

  sendPort.send(workerThreadReceiver.sendPort);

  workerThreadReceiver.listen((message) async {
    if (message is String && message.contains('image@read-rotate.')) {
      final String imgPath = String.fromCharCodes(cvrt.base64Decode(message.split('.')[1]));

      final img.Image? image = await img.decodeImageFile(imgPath);

      final io.Directory tempDir = await pd.getTemporaryDirectory();

      if (image != null) {
        if (image.width > image.height) {
          await img.encodeJpgFile('${tempDir.path}/working', img.copyRotate(image, angle: -90));
        } else {
          await img.encodeJpgFile('${tempDir.path}/working', image);
        }

        final String data = cvrt.base64Encode(cvrt.utf8.encode('${tempDir.path}/working'));

        sendPort.send('image@read-rotate:done.$data');
      }
    }
  }); 
}
