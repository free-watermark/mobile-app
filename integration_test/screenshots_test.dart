
import 'dart:io' as io;
import 'dart:typed_data' as td;

import 'package:get_it/get_it.dart' as gi;
import 'package:flutter/material.dart' as fm;
import 'package:flutter/services.dart' as fts;
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:path_provider/path_provider.dart' as pd;
import 'package:integration_test/integration_test.dart' as itgt;

import 'package:free_watermark/app.dart' show App;
import 'package:free_watermark/services/image_picker.dart' show ImagePicker, ImagePickerMockService;

void main() {
  final itgt.IntegrationTestWidgetsFlutterBinding binding =
    itgt.IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late final String platform;

  const watermarkText = 'web:register@web.com@20260609'; 

  fm.WidgetsApp.debugAllowBannerOverride = false; 

  ft.setUpAll(() async {
    gi.GetIt.I.registerSingleton<ImagePicker>(ImagePickerMockService(
      filePathSupplier: () async {
      final io.Directory tempDir = await pd.getTemporaryDirectory(); 

        final td.ByteData data = await fts.rootBundle.load('assets/test-img.jpg');

        final td.Uint8List bytes = data.buffer.asUint8List();

        await io.File('${tempDir.path}/test-img.jpg').writeAsBytes(bytes);

        return '${tempDir.path}/test-img.jpg';
      },
    ));
  });

  ft.testWidgets('screenshots', (ft.WidgetTester tester) async {
    await tester.pumpWidget(const App());

    platform = io.Platform.isAndroid ? 'android' : 'ios';

    if (platform == 'android') {
      await binding.convertFlutterSurfaceToImage();
    }

    await tester.pumpAndSettle();

    await binding.takeScreenshot('$platform.home');

    await tester.tap(ft.find.text('Gallery'));

    await tester.pumpAndSettle(const Duration(seconds: 2));

    ft.expect(ft.find.text('processing image'), ft.findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 16));

    ft.expect(ft.find.byType(fm.Image), ft.findsOneWidget);

    await tester.tap(ft.find.byIcon(fm.Icons.font_download));

    await tester.pumpAndSettle(const Duration(seconds: 4));

    await tester.enterText(ft.find.byType(fm.TextField), watermarkText);

    await tester.testTextInput.receiveAction(ft.TextInputAction.done);

    await tester.pumpAndSettle(const Duration(seconds: 4));

    ft.expect(ft.find.text('processing image'), ft.findsNothing);

    ft.expect(ft.find.byType(fm.CustomPaint), ft.findsWidgets);

    await tester.pumpAndSettle(const Duration(seconds: 4));

    await binding.takeScreenshot('$platform.watermarking');

    await tester.tap(ft.find.byIcon(fm.Icons.opacity));

    await tester.pumpAndSettle(const Duration(seconds: 4));

    await tester.drag(ft.find.byType(fm.Slider), const fm.Offset(-64, 0));

    await tester.pumpAndSettle(const Duration(seconds: 4));

    await tester.tap(ft.find.byIcon(fm.Icons.rotate_left));

    await tester.pumpAndSettle(const Duration(seconds: 4));

    await tester.drag(ft.find.byType(fm.Slider), const fm.Offset(-49, 0));

    await tester.pumpAndSettle(const Duration(seconds: 4));

    await binding.takeScreenshot('$platform.applied-some-effects');

    await tester.drag(
      ft.find.descendant(of: ft.find.byType(fm.ListView), matching: ft.find.byType(fm.ListView)),
      const fm.Offset(-6969, 0),
    );

    await tester.pumpAndSettle(const Duration(seconds: 4));

    await tester.tap(ft.find.byIcon(fm.Icons.brightness_medium_outlined));

    await tester.pumpAndSettle(const Duration(seconds: 4));

    ft.expect(ft.find.text('processing image'), ft.findsNothing);

    await Future.delayed(const Duration(seconds: 4));

    await tester.pumpAndSettle(const Duration(seconds: 4));

    await binding.takeScreenshot('$platform.grayscale');
  });
}

