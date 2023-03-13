
import 'dart:io' as io;

import 'package:get_it/get_it.dart' as gi;
import 'package:flutter/material.dart' as fm;
import 'package:flutter/cupertino.dart' as fc;
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter_bloc/flutter_bloc.dart' as fb;
import 'package:image_picker/image_picker.dart' as imgp;

import 'preview.dart';
import '../services/image_picker.dart';
import '../blocs/image_processing.dart';

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

    dynamic img;

    try {
      img = await picker();
    } catch (err) {
      _isPickingImage = false;

      if (io.Platform.isIOS) {
        await fc.showCupertinoDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            return const fc.CupertinoAlertDialog(
              content: fm.Text('please try another one or from other source'),
              title: fm.Text('fail to pick an image'),
            );
          }
        );
        return;
      }

      await fm.showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return const fm.AlertDialog(
            content: fm.Text('please try another one or from other source'),
            title: fm.Text('fail to pick an image'),
          );
        },
      );

      return;
    }

    _isPickingImage = false;

    if (img == null) {
      return;
    }

    final error = await navigator.push<String>(fm.MaterialPageRoute(builder: (context) {
      return fb.BlocProvider(
        create: (_) => ImageProcessingBloc(img),
        child: const PreviewScreen(),
      );
    }));

    if (error != null && error.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 128), () async {
        if (io.Platform.isIOS) {
          await fc.showCupertinoDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) {
              return const fc.CupertinoAlertDialog(
                title: fm.Text('fail to read image'),
                content: fm.Text('something went wrong'),
              );
            }
          );
          return;
        }

        await fm.showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            return const fm.AlertDialog(
              title: fm.Text('fail to read image'),
              content: fm.Text('something went wrong'),
            );
          },
        );
      });
    }
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
