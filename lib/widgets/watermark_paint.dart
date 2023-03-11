
import 'package:flutter/material.dart' as fm;

void paintWatermark({
  double fontSize = 16,
  required double zoom,
  required String? text,
  required double angle,
  required double width,
  required double height,
  required double opacity,
  required fm.Canvas canvas,
}) {
  final double gapSizeX = width * 0.04;
  final double gapSizeY = height * 0.04;

  final double fontSizex = fontSize * (1 + zoom / 100);

  final textStyle = fm.TextStyle(
    fontSize: fontSizex,
    color: fm.Colors.white.withAlpha(255 * opacity ~/ 100),
  );

  final textSpan = fm.TextSpan(text: text, style: textStyle);

  final textPainter = fm.TextPainter(
    text: textSpan,
    textDirection: fm.TextDirection.ltr,
  );

  textPainter.layout();

  final textSize = textPainter.size;

  final middleOffsetSize = textSize.width / 2;

  const int additionalSizeTextcount = 4;

  final realWidth = textSize.width * additionalSizeTextcount + width + gapSizeX + middleOffsetSize;
  final realHeight = textSize.height * additionalSizeTextcount + height + gapSizeY + middleOffsetSize;

  final int colCount = (realWidth / textSize.width).round(); 
  final int rowCount = (realHeight / textSize.height).round();

  final halfWidth = width / 2;
  final halfHeight = height / 2;

  final fm.Offset center = fm.Offset(halfWidth, halfHeight);

  canvas.save();

  canvas.translate(center.dx, center.dy);

  canvas.rotate(angle * 3.14 / 180);

  canvas.translate(-center.dx, -center.dy);

  for (int rIdx = -additionalSizeTextcount; rIdx < rowCount; rIdx++) {
    for (int cIdx = -additionalSizeTextcount; cIdx < colCount; cIdx++) { 
      textPainter.paint(
        canvas, fm.Offset(
          cIdx * (textSize.width + gapSizeX),
          rIdx * (textSize.height + gapSizeY),
        ),
      );
    }
  }

  canvas.restore();
}

class WatermarkPaint extends fm.CustomPainter {
  final String text;
  final double zoom;
  final double width;
  final double angle;
  final double height;
  final double opacity;
  final double fontSize;

  const WatermarkPaint({
    required this.text,
    required this.zoom,
    required this.angle,
    required this.width,
    required this.height,
    required this.opacity,
    required this.fontSize,
  });

  @override
  void paint(fm.Canvas canvas, fm.Size size) {
    paintWatermark(
      zoom: zoom,
      text: text,
      angle: angle,
      width: width,
      height: height,
      canvas: canvas,
      opacity: opacity,
      fontSize: fontSize,
    );
  }

  @override
  bool shouldRepaint(covariant fm.CustomPainter oldDelegate) => this != oldDelegate;
}
