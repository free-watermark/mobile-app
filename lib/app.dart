
import 'package:flutter/material.dart' as fm;

class App extends fm.StatelessWidget {
  const App({ super.key });

  _openPhotoLibrary() {
  }

  @override
  fm.Widget build(fm.BuildContext context) {
    return fm.MaterialApp(
      title: 'FreeWatermark',
      home: fm.Scaffold(
        body: fm.Center(
          child: fm.Column(
            mainAxisAlignment: fm.MainAxisAlignment.center,
            crossAxisAlignment: fm.CrossAxisAlignment.center,
            children: [
              fm.GestureDetector( 
                onTap: _openPhotoLibrary,
                child: const fm.Icon(
                  fm.Icons.image,
                  size: 64,
                ),
              ),

              const fm.SizedBox(height: 8),

              const fm.Text('Choose an image for watermarking'),
            ],
          ),
        ),
      ),
    );
  }
}
