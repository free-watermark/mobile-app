
import 'dart:io' as io;

import 'package:flutter/material.dart' as fm;
import 'package:file_picker/file_picker.dart' as fp;
import 'package:image_picker/image_picker.dart' as imgp;

class PreviewScreen extends fm.StatelessWidget {
  final dynamic imageFile;

  const PreviewScreen({ required this.imageFile, super.key });

  io.File _getImageFile() {
    if (imageFile is imgp.XFile) {
      return io.File((imageFile as imgp.XFile).path);
    }

    return io.File((imageFile as fp.FilePickerResult).paths[0]!);
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
            child: fm.Center(child: fm.Image.file(_getImageFile())),
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
