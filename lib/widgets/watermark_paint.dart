
import 'package:flutter/material.dart' as fm;

class WatermarkPaint extends fm.CustomPainter {
  final String text;
  final double zoom;
  final double width;
  final double height;

  const WatermarkPaint({
    required this.text,
    required this.zoom,
    required this.width,
    required this.height,
  });

  @override
  void paint(fm.Canvas canvas, fm.Size size) {
    const double gapSize = 16;

    final textStyle = fm.TextStyle(color: fm.Colors.white, fontSize: (8 + 4) * (1 + zoom / 100));

    final textSpan = fm.TextSpan(text: text, style: textStyle);

    final textPainter = fm.TextPainter(
      text: textSpan,
      textDirection: fm.TextDirection.ltr,
    );

    textPainter.layout();

    final textSize = textPainter.size;

    final middleOffsetSize = textSize.width / 2;

    const int additionalSizeTextcount = 4;

    final realWidth = textSize.width * additionalSizeTextcount + width + gapSize + middleOffsetSize;
    final realHeight = textSize.height * additionalSizeTextcount + height + gapSize + middleOffsetSize;

    final int colCount = (realWidth / textSize.height).round();
    final int rowCount = (realHeight / textSize.width).round();

    for (int rIdx = -additionalSizeTextcount; rIdx < rowCount; rIdx++) {
      for (int cIdx = -additionalSizeTextcount; cIdx < colCount; cIdx++) {
        textPainter.paint(
          canvas, fm.Offset(
            rIdx * (textSize.width + gapSize),
            cIdx * (textSize.height + gapSize),
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant fm.CustomPainter oldDelegate) => this != oldDelegate;
}
