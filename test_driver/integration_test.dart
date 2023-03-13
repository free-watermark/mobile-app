
import 'dart:io' as io;

import 'package:integration_test/integration_test_driver_extended.dart' as itgtde;

Future<void> main() async {
  await itgtde.integrationDriver(
    onScreenshot: (String name, List<int> bytes) async {
      final data = name.split('.');

      await io.File('generated/screenshots/${data[0]}/${data[1]}.png').writeAsBytes(bytes);

      return true;
    },
  );
}
