
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

  @override
  fm.Widget build(fm.BuildContext context) {
    return fm.Scaffold(
      appBar: fm.AppBar(backgroundColor: const fm.Color(0xff000000)),
      body: fm.Column(
        children: [
          fm.Container(
            padding: const fm.EdgeInsets.all(8.0),
            decoration: const fm.BoxDecoration(
              color: fm.Color(0xff000000),
            ),
            child: fm.Image.file(_getImageFile()),
          ),
        ],
      ),
    );
  }
}
