
import 'package:flutter/material.dart' as fm;
import 'package:flutter_bloc/flutter_bloc.dart' as fb;

import 'screens/home.dart';
import 'blocs/image_picking.dart';


class App extends fm.StatelessWidget {
  const App({ super.key });

  @override
  fm.Widget build(fm.BuildContext context) {
    return fb.BlocProvider(
      create: (_) => ImagePickingBloc(),
      child: const fm.MaterialApp(
        title: 'FreeWatermark',
        home: HomeScreen(),
      ),
    );
  }
}
