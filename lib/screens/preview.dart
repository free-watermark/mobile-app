
import 'package:flutter/material.dart' as fm;

class PreviewScreen extends fm.StatelessWidget {
  final dynamic imageFile;

  const PreviewScreen({ required this.imageFile, super.key });

  @override
  fm.Widget build(fm.BuildContext context) {
    return const fm.Scaffold(
      body: fm.Text('hello'),
    );
  }
}
