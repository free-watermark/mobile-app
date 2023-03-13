
import 'package:get_it/get_it.dart' as gi;
import 'package:flutter/material.dart' as fm;
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter_bloc/flutter_bloc.dart' as fb;
import 'package:image_picker/image_picker.dart' as imgp;

import 'preview.dart';
import '../blocs/image_processing.dart';
import '../services/image_picker.dart';

class HomeScreen extends fm.StatefulWidget {
  const HomeScreen({super.key});

  @override
  fm.State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends fm.State<HomeScreen> {
  bool _isPickingImage = false;

  final ImagePicker _imagePicker = gi.GetIt.I.get<ImagePicker>();

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
      return fb.BlocProvider(
        create: (_) => ImageProcessingBloc(img),
        child: const PreviewScreen(),
      );
    }));
  }

  fm.Widget _renderPickFromSourceButton(fm.Icon icon, String text, Function()? onPick) {
    return fm.GestureDetector(
      onTap: onPick,
      child: fm.Row(
        crossAxisAlignment: fm.CrossAxisAlignment.center,
        children: [
          icon,

          const fm.SizedBox(width: 16),

          fm.Text(text),
        ],
      ),
    );
  }

  @override
  fm.Widget build(fm.BuildContext context) {
    final sourceMap = [{
      'label': 'Gallery',
      'icon': const fm.Icon(fm.Icons.image, size: 64),
      'picker': () => _openPicker(() => _imagePicker.pickImage(source: imgp.ImageSource.gallery)),
    }, {
      'label': 'Camera',
      'icon': const fm.Icon(fm.Icons.camera, size: 64),
      'picker': () => _openPicker(() => _imagePicker.pickImage(source: imgp.ImageSource.camera)),
    }, {
      'label': 'Explorer',
      'icon': const fm.Icon(fm.Icons.file_open, size: 64),
      'picker': () => _openPicker(() => fp.FilePicker.platform.pickFiles(
        type: fp.FileType.custom, allowedExtensions: ['jpg', 'png'])),
    }];

    return fm.Scaffold(
      body: fm.Center(
        child: fm.IntrinsicWidth(child: fm.Column(
          mainAxisAlignment: fm.MainAxisAlignment.center,
          crossAxisAlignment: fm.CrossAxisAlignment.center,
          children: [
            ...sourceMap.map<List<fm.Widget>>((s) => [
              _renderPickFromSourceButton(
                s['icon'] as fm.Icon,
                s['label'] as String,
                s['picker'] as Function()?
              ),

              const fm.SizedBox(height: 8),
            ]).expand((elem) => elem).toList(),

            const fm.SizedBox(height: 12),

            const fm.Text('Choose an image for watermarking'),
          ],
        ),),
      ),
    );
  }
}
