
import 'package:flutter/material.dart' as fm;
import 'package:file_picker/file_picker.dart' as fp;
import 'package:image_picker/image_picker.dart' as imgp;

import 'preview.dart';

class HomeScreen extends fm.StatefulWidget {
  const HomeScreen({super.key});

  @override
  fm.State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends fm.State<HomeScreen> {
  bool _isPickingImage = false;

  final imgp.ImagePicker _imagePicker = imgp.ImagePicker();

  _openPicker(Function picker) async {
    final navigator = fm.Navigator.of(context);

    if (_isPickingImage) {
      return;
    }

    _isPickingImage = true;

    final dynamic img = await picker();

    _isPickingImage = false;

    if (img == null) {
      return;
    }

    await navigator.push(fm.MaterialPageRoute(builder: (context) {
      return PreviewScreen(imageFile: img);
    }));
  }

  @override
  fm.Widget build(fm.BuildContext context) {
    const imageIcon = fm.Icon(fm.Icons.image, size: 64);
    const cameraIcon = fm.Icon(fm.Icons.camera, size: 64);
    const fileIcon = fm.Icon(fm.Icons.file_open, size: 64);

    return fm.Scaffold(
      body: fm.Center(
        child: fm.Column(
          mainAxisAlignment: fm.MainAxisAlignment.center,
          crossAxisAlignment: fm.CrossAxisAlignment.center,
          children: [
            fm.GestureDetector( 
              onTap: () => _openPicker(() => _imagePicker.pickImage(source: imgp.ImageSource.gallery)),
              child: imageIcon,
            ),

            const fm.SizedBox(height: 8),

            fm.GestureDetector( 
              onTap: () => _openPicker(() => _imagePicker.pickImage(source: imgp.ImageSource.camera)),
              child: cameraIcon,
            ),

            const fm.SizedBox(height: 8),

            fm.GestureDetector( 
              onTap: () => _openPicker(() => fp.FilePicker.platform.pickFiles(
                type: fp.FileType.custom, allowedExtensions: ['.jpg', '.png'])),
              child: fileIcon,
            ),

            const fm.SizedBox(height: 8),

            const fm.Text('Choose an image for watermarking'),
          ],
        ),
      ),
    );
  }
}
