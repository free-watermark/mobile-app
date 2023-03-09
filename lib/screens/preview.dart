
import 'dart:io' as io;
import 'dart:async' as asyncx;

import 'package:flutter/material.dart' as fm;
import 'package:flutter_bloc/flutter_bloc.dart' as fb;

import '../blocs/image_processing.dart';

class PreviewScreen extends fm.StatefulWidget {
  const PreviewScreen({ super.key });

  @override
  fm.State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends fm.State<PreviewScreen> {
  final fm.TextEditingController _watermarkingTextInputController =
    fm.TextEditingController(text: 'my-watermark@date@reason');

  late final ImageProcessingBloc _imageProcessBloc;

  asyncx.Timer? _watermarkingTextInputDebounce;

  fm.Widget _featureButton(fm.Widget icon, Function() func) {
    return fm.GestureDetector(
      onTap: () {
        if (_imageProcessBloc.isGrayscaling() || _imageProcessBloc.isLoadingImage()) {
          return;
        }

        func();
      },
      child: icon,
    );
  }

  @override
  void initState() {
    super.initState();

    _imageProcessBloc = context.read<ImageProcessingBloc>();

    _imageProcessBloc.add(LoadImage());
  }

  @override
  void dispose() {
    _watermarkingTextInputDebounce?.cancel();

    _imageProcessBloc.dispose();

    super.dispose();
  }

  @override
  fm.Widget build(fm.BuildContext context) {
    return fm.Scaffold(
      appBar: fm.AppBar(
        backgroundColor: const fm.Color(0xff000000),
        actions: [
          fm.TextButton(
            onPressed: () {},
            child: fm.Row(
              children: const [
                fm.Text('Save', style: fm.TextStyle(fontSize: 16, color: fm.Color(0xffffffff))),

                fm.SizedBox(width: 4),

                fm.Icon(fm.Icons.done, size: 26, color: fm.Color(0xffffffff)),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const fm.Color(0xff000000),
      body: fm.ListView(
        children: [
          fm.Container(
            padding: const fm.EdgeInsets.all(8.0),
            height: fm.MediaQuery.of(context).size.height * 0.64,
            decoration: const fm.BoxDecoration(
              color: fm.Color(0xff000000),
            ),
            child: fm.Center(
              child: fb.BlocBuilder<ImageProcessingBloc, ImageProcessingState>(
                bloc: _imageProcessBloc,
                buildWhen: (_, curr) => curr is ImageLoaded || curr is ImageGrayscaling || curr is ImageGrayscaleToggled,
                builder: (context, state) {
                  final imageProcess = context.read<ImageProcessingBloc>();

                  if (state is ImageLoaded) {
                    return fm.Image.file(io.File(imageProcess.getOriginalImagePath()));
                  }

                  if (state is ImageGrayscaling) {
                    return const fm.Text('grayscaling image', style: fm.TextStyle(fontSize: 16, color: fm.Color(0xffffffff)));
                  }

                  if (state is ImageGrayscaleToggled) {
                    if (_imageProcessBloc.isToggleGrayscaled()) {
                      return fm.Image.file(io.File(imageProcess.getGrayscaledImagePath()));
                    }

                    return fm.Image.file(io.File(imageProcess.getOriginalImagePath()));
                  }
                  
                  return const fm.Text('opening image', style: fm.TextStyle(fontSize: 16, color: fm.Color(0xffffffff)));
                },
              ),
            ),
          ),

          const fm.SizedBox(height: 16),

          const fm.Divider(height: 8, color: fm.Color(0xffffffff)),

          const fm.SizedBox(height: 16),

          fb.BlocBuilder<ImageProcessingBloc, ImageProcessingState>(
            bloc: _imageProcessBloc,
            buildWhen: (_, curr) => curr is EditModeChanged,
            builder: (context, state) {
              final EditMode currentEditMode = _imageProcessBloc.currentEditMode();

              switch (currentEditMode) {
                case EditMode.text:
                  return fm.Padding(
                    padding: const fm.EdgeInsets.symmetric(horizontal: 16),
                    child: fm.TextField(
                      autofocus: true,
                      autocorrect: false,
                      controller: _watermarkingTextInputController,
                      style: const fm.TextStyle(color: fm.Color(0xffffffff)),
                      keyboardType: fm.TextInputType.text,
                      decoration: const fm.InputDecoration(
                        enabledBorder: fm.UnderlineInputBorder(
                          borderSide: fm.BorderSide(
                            color: fm.Color(0xfff56300),
                          ),
                        ),
                        focusedBorder: fm.UnderlineInputBorder(
                          borderSide: fm.BorderSide(
                            color: fm.Color(0xfff56300),
                          ),
                        ),
                      ),
                      cursorColor: const fm.Color(0xfff56300),
                      onChanged: (val) {
                        if (_watermarkingTextInputDebounce?.isActive ?? false) {
                          _watermarkingTextInputDebounce!.cancel();
                        }

                        _watermarkingTextInputDebounce = asyncx.Timer(const Duration(milliseconds: 640), () {
                          _imageProcessBloc.add(WatermarkingTextChange(val));
                        });
                      },
                    ),
                );
                case EditMode.zoom:
                case EditMode.angle:
                case EditMode.opacity: {
                  return fb.BlocBuilder<ImageProcessingBloc, ImageProcessingState>(
                    buildWhen: (_, curr) => curr is AngleChanged || curr is OpacityChanged || curr is ZoomChanged,
                    builder: (context, state) {
                      double max = 100;
                      double value = 0;

                      Function(double)? updateVal;

                      if (currentEditMode == EditMode.angle) {
                        max = 360;
                        value = _imageProcessBloc.angleValue();

                        updateVal = (newVal) {
                          _imageProcessBloc.add(AngleChange(newVal));
                        };
                      }

                      if (currentEditMode == EditMode.zoom) {
                        value = _imageProcessBloc.zoomValue();

                        updateVal = (newVal) {
                          _imageProcessBloc.add(ZoomChange(newVal));
                        };
                      }

                      if (currentEditMode == EditMode.opacity) {
                        value = _imageProcessBloc.opacityValue();

                        updateVal = (newVal) {
                          _imageProcessBloc.add(OpacityChange(newVal));
                        };
                      }

                      return fm.Slider(
                        min: 0,
                        max: max,
                        value: value,
                        thumbColor: const fm.Color(0xfff56400),
                        activeColor: const fm.Color(0xfff56400),
                        inactiveColor: const fm.Color(0xffffffff),
                        secondaryActiveColor: const fm.Color(0xffffffff),
                        onChanged: updateVal,
                      );
                    },
                  ); 
                }
              }
            },
          ),

          const fm.SizedBox(height: 16),

          fm.SizedBox(
            height: 64,
            width: double.infinity,
            child: fm.Center(child:
              fm.ListView(
                shrinkWrap: true,
                scrollDirection: fm.Axis.horizontal,
                children: [
                  fb.BlocBuilder<ImageProcessingBloc, ImageProcessingState>(
                    bloc: _imageProcessBloc,
                    buildWhen: (_, curr) => curr is EditModeChanged,
                    builder: (context, _) {
                      return fm.Row(
                        children: [
                          _featureButton(fm.Padding(
                            padding: const fm.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: fm.Icon(
                              fm.Icons.font_download,
                              size: 32,
                              color: _imageProcessBloc.currentEditMode() == EditMode.text
                                ? const fm.Color(0xfff56300)
                                : const fm.Color(0xffffffff),
                            ),
                          ), () {
                            _imageProcessBloc.add(ChangeEditMode(EditMode.text));
                          }),

                          _featureButton(fm.Padding(
                            padding: const fm.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: fm.Icon(
                              fm.Icons.opacity,
                              size: 32,
                              color: _imageProcessBloc.currentEditMode() == EditMode.opacity
                                ? const fm.Color(0xfff56300)
                                : const fm.Color(0xffffffff),
                            ),
                          ), () {
                            _imageProcessBloc.add(ChangeEditMode(EditMode.opacity));
                          }),

                          _featureButton(fm.Padding(
                            padding: const fm.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: fm.Icon(
                              fm.Icons.rotate_left,
                              size: 32,
                              color: _imageProcessBloc.currentEditMode() == EditMode.angle
                                ? const fm.Color(0xfff56300)
                                : const fm.Color(0xffffffff),
                            ),
                          ), () {
                            _imageProcessBloc.add(ChangeEditMode(EditMode.angle));
                          }),

                          _featureButton(fm.Padding(
                            padding: const fm.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: fm.Icon(
                              fm.Icons.zoom_in_map_rounded,
                              size: 32,
                              color: _imageProcessBloc.currentEditMode() == EditMode.zoom
                                ? const fm.Color(0xfff56300)
                                : const fm.Color(0xffffffff),
                            ),
                          ), () {
                            _imageProcessBloc.add(ChangeEditMode(EditMode.zoom));
                          }),
                        ],
                      );
                    },
                  ),

                  _featureButton(fm.Padding(
                    padding: const fm.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: fb.BlocSelector<ImageProcessingBloc, ImageProcessingState, bool>(
                      bloc: _imageProcessBloc,
                      selector: (_) => _imageProcessBloc.isToggleGrayscaled(),
                      builder: (context, state) {
                        return fm.Icon(
                          fm.Icons.brightness_medium_outlined,
                          size: 32,
                          color: _imageProcessBloc.isToggleGrayscaled()
                            ? const fm.Color(0xfff56300)
                            : const fm.Color(0xffffffff),
                        );
                      }
                    ),
                  ), () {
                    final imageProcess = context.read<ImageProcessingBloc>();

                    if (imageProcess.isGrayscaled()) {
                      imageProcess.add(ImageGrayscaleToggle());
                      return;
                    }

                    imageProcess.add(ImageGrayscale());
                  }),
                ],
              ),
            ),
          ), 
        ],
      ),
    );
  }
}
