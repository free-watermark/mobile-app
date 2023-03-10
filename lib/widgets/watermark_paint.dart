
import 'package:flutter/material.dart' as fm;

class WatermarkPaint extends fm.CustomPainter {
  final String text;

  const WatermarkPaint({ required this.text });

  @override
  void paint(fm.Canvas canvas, fm.Size size) {
    const textStyle = fm.TextStyle(color: fm.Colors.white, fontSize: 16);

    final textSpan = fm.TextSpan(text: text, style: textStyle);

    final textPainter = fm.TextPainter(
      text: textSpan,
      textDirection: fm.TextDirection.ltr,
    );

    textPainter.layout();

    textPainter.paint(canvas, const fm.Offset(16, 16));
  }

  @override
  bool shouldRepaint(covariant fm.CustomPainter oldDelegate) => this != oldDelegate;
}
