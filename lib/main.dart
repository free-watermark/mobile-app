
import 'package:get_it/get_it.dart' as gi;
import 'package:flutter/material.dart' show runApp;

import 'app.dart';
import './services/image_picker.dart';

void main() {
  gi.GetIt.I.registerSingleton<ImagePicker>(ImagePickerService());

  runApp(const App());
}
