
import 'dart:ui' as ui;
import 'dart:typed_data' as td;

import 'package:image/image.dart' as img;
import 'package:flutter/material.dart' as fm;
import 'package:flutter/foundation.dart' as ff;
import 'package:file_picker/file_picker.dart' as fp;
import 'package:image_picker/image_picker.dart' as imgp;

import '../utils/image.dart';

class PreviewScreen extends fm.StatefulWidget {
  final dynamic imageFile;

  const PreviewScreen({ required this.imageFile, super.key });

  @override
  fm.State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends fm.State<PreviewScreen> {
  late img.Image _image;

  Future<img.Image?> _getImageFile() async {
    img.Image? image = await img.decodeImageFile(
      widget.imageFile is imgp.XFile
        ? (widget.imageFile as imgp.XFile).path
        : (widget.imageFile as fp.FilePickerResult).paths[0]!
    );

    if (image == null) {
      return null;
    }

    if (image.width > image.height) {
      _image = img.copyRotate(image, angle: -90);
    } else {
      _image = image;
    }

    return _image;
  }

  fm.Widget _featureButton(fm.Widget icon) {
    return fm.GestureDetector(
      onTap: () {},
      child: icon,
    );
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
              child: fm.FutureBuilder<img.Image?>(
                future: _getImageFile(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return fm.FutureBuilder<ui.Image>(
                      future: convertImageToFlutterUi(snapshot.data!),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return fm.FutureBuilder<td.ByteData?>(
                            future: snapshot.data!.toByteData(format: ui.ImageByteFormat.png),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return fm.Image.memory(ff.Uint8List.view(snapshot.data!.buffer));
                              }

                              return const fm.Text('showing image', style: fm.TextStyle(fontSize: 16, color: fm.Color(0xffffffff)));
                            },
                          );
                        }

                        return const fm.Text('reading image and rotate if landscape', style: fm.TextStyle(fontSize: 16, color: fm.Color(0xffffffff)));
                      },
                    );
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
