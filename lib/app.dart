
import 'package:flutter/material.dart' as fm;

import 'screens/home.dart';


class App extends fm.StatelessWidget {
  const App({ super.key });

  @override
  fm.Widget build(fm.BuildContext context) {
    return const fm.MaterialApp(
      title: 'FreeWatermark',
      home: HomeScreen(),
    );
  }
}
