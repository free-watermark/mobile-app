import 'dart:io' as io;
import 'dart:ui' as ui;
import 'dart:async' as asyncx;

import 'package:image/image.dart' as img;
import 'package:flutter/widgets.dart' as fw;
import 'package:flutter/material.dart' as fm;
import 'package:flutter/cupertino.dart' as fc;
import 'package:share_plus/share_plus.dart' as sp;
import 'package:flutter_bloc/flutter_bloc.dart' as fb;
import 'package:image_picker/image_picker.dart' as imgp;

import '../utils/image.dart';
import '../blocs/image_processing.dart';
import '../widgets/watermark_paint.dart';

class PreviewScreen extends fm.StatefulWidget {
  const PreviewScreen({super.key});

  @override
  fm.State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends fm.State<PreviewScreen> {
  final fm.TextEditingController _watermarkingTextInputController =
      fm.TextEditingController();

  late final ImageProcessingBloc _imageProcessBloc;

  final fw.GlobalKey _imageKey = fw.GlobalKey();

  asyncx.Timer? _watermarkingTextInputDebounce;

  late final asyncx.StreamSubscription _listenOnImageLoadFailure;

  @override
  void initState() {
    super.initState();

    _imageProcessBloc = context.read<ImageProcessingBloc>();

    _listenOnImageLoadFailure = _imageProcessBloc.stream.listen((event) {
      if (event is ImageLoadFailed) {
        fm.Navigator.of(context).pop<String>(event.error);
        return;
      }

      if (event is ImageLoaded) {
        _listenOnImageLoadFailure.cancel();
      }
    });

    _imageProcessBloc.add(LoadImage());
  }

  @override
  void dispose() {
    _watermarkingTextInputDebounce?.cancel();

    _listenOnImageLoadFailure.cancel();

    _imageProcessBloc.dispose();

    super.dispose();
  }

  Future<void> _exportImagePreview() async {
    if (_imageProcessBloc.isHasChangesSinceLastProcessedBeingRendered()) {
      _imageProcessBloc.add(FinalProcessing());

      late Function popDialogContext;

      if (io.Platform.isIOS) {
        fc.showCupertinoDialog(
          context: context,
          builder: (context) {
            popDialogContext = () => fc.Navigator.of(context).pop();

            return const fc.PopScope(
                canPop: false,
                child: fc.CupertinoAlertDialog(
                  title: fc.Text('exporting watermarked image'),
                  content: fc.CupertinoActivityIndicator(radius: 16),
                ));
          },
        );
      } else {
        fm.showDialog(
          context: context,
          builder: (context) {
            popDialogContext = () => fm.Navigator.of(context).pop();

            return fm.PopScope(
              canPop: false,
              child: fm.AlertDialog(
                title: const fm.Text('exporting watermarked image'),
                content: fm.Container(
                  width: 64,
                  height: 64,
                  alignment: fm.Alignment.center,
                  child: const fm.CircularProgressIndicator(
                      color: fm.Color(0xfff56300)),
                ),
              ),
            );
          },
        );
      }

      final imageWidth = _imageProcessBloc.originalImageSize().width *
          _imageProcessBloc.finalProcessingSizeReductionTo() ~/
          100;
      final imageHeight = _imageProcessBloc.originalImageSize().height *
          _imageProcessBloc.finalProcessingSizeReductionTo() ~/
          100;

      img.Image imageToProcess = (await img.decodeImageFile(
          _imageProcessBloc.isToggleGrayscaled()
              ? _imageProcessBloc.getGrayscaledImagePath()
              : _imageProcessBloc.getOriginalImagePath()))!;

      if (_imageProcessBloc.finalProcessingSizeReductionTo() < 100) {
        imageToProcess = img.copyResize(
          imageToProcess,
          width: imageWidth,
          height: imageHeight,
        );
      }

      final ui.Image image = await convertImageToFlutterUi(imageToProcess);

      final ui.PictureRecorder recorder = ui.PictureRecorder();

      fm.Canvas canvas = fm.Canvas(recorder);

      canvas.drawImage(image, fw.Offset.zero, fm.Paint());

      paintWatermark(
        canvas: canvas,
        fontSize: imageWidth * 0.04,
        width: imageWidth.toDouble(),
        height: imageHeight.toDouble(),
        zoom: _imageProcessBloc.zoomValue(),
        angle: _imageProcessBloc.angleValue(),
        opacity: _imageProcessBloc.opacityValue(),
        text: _imageProcessBloc.watermarkingTextValue(),
      );

      final ui.Image processedUiImage = await recorder.endRecording().toImage(
            imageWidth,
            imageHeight,
          );

      final img.Image processedImage = img.Image.fromBytes(
        numChannels: 4,
        width: processedUiImage.width,
        height: processedUiImage.height,
        bytes: (await processedUiImage.toByteData())!.buffer,
      );

      await img.encodeJpgFile(
        _imageProcessBloc.getProcessedImagePath(),
        processedImage,
        quality: _imageProcessBloc.finalProcessingQuality().toInt(),
      );

      popDialogContext();

      _imageProcessBloc.add(DoneFinalProcessing());
    }

    await sp.Share.shareXFiles(
      [imgp.XFile(_imageProcessBloc.getProcessedImagePath())],
    );
  }

  fm.Widget _featureButton(fm.IconData icon, EditMode editMode,
      {fm.Widget? child, Function? func}) {
    return fm.GestureDetector(
      onTap: () {
        if (_imageProcessBloc.isGrayscaling() ||
            _imageProcessBloc.isLoadingImage() ||
            _imageProcessBloc.isFinalProcessing()) {
          return;
        }

        func == null ? _imageProcessBloc.add(ChangeEditMode(editMode)) : func();
      },
      child: fm.Padding(
        padding: const fm.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: child ??
            fm.Icon(
              icon,
              size: 32,
              color: _imageProcessBloc.currentEditMode() == editMode
                  ? const fm.Color(0xfff56300)
                  : const fm.Color(0xffffffff),
            ),
      ),
    );
  }

  fm.Widget _imagePreview() {
    return fm.Container(
      alignment: fm.Alignment.center,
      padding: const fm.EdgeInsets.all(8.0),
      height: fm.MediaQuery.of(context).size.height * 0.64,
      decoration: const fm.BoxDecoration(
        color: fm.Color(0xff000000),
      ),
      child: fb.BlocBuilder<ImageProcessingBloc, ImageProcessingState>(
        bloc: _imageProcessBloc,
        buildWhen: (_, curr) =>
            curr is ImageLoaded ||
            curr is ImageGrayscaling ||
            curr is ImageGrayscaleToggled,
        builder: (context, state) {
          if (state is ImageLoaded || state is ImageGrayscaleToggled) {
            return fm.Stack(
              clipBehavior: fm.Clip.hardEdge,
              children: [
                fm.Image.file(
                    io.File(
                      _imageProcessBloc.isToggleGrayscaled()
                          ? _imageProcessBloc.getGrayscaledImagePath()
                          : _imageProcessBloc.getOriginalImagePath(),
                    ),
                    fit: fm.BoxFit.contain,
                    key: _imageKey),
                fb.BlocBuilder<ImageProcessingBloc, ImageProcessingState>(
                  bloc: _imageProcessBloc,
                  buildWhen: (_, curr) =>
                      curr is SetRenderedImageSizeDone ||
                      curr is OpacityChanged ||
                      curr is ZoomChanged ||
                      curr is AngleChanged ||
                      curr is WatermarkingTextChanged,
                  builder: (context, state) {
                    if (_imageProcessBloc.renderedImageSize() != null) {
                      if (_imageProcessBloc
                          .watermarkingTextValue()
                          .isNotEmpty) {
                        return fm.Container(
                          width: _imageProcessBloc.renderedImageSize()!.width,
                          height: _imageProcessBloc.renderedImageSize()!.height,
                          clipBehavior: fm.Clip.hardEdge,
                          decoration: const fm.BoxDecoration(),
                          child: fm.CustomPaint(
                            painter: WatermarkPaint(
                              zoom: _imageProcessBloc.zoomValue(),
                              angle: _imageProcessBloc.angleValue(),
                              opacity: _imageProcessBloc.opacityValue(),
                              text: _imageProcessBloc.watermarkingTextValue(),
                              width:
                                  _imageProcessBloc.renderedImageSize()!.width,
                              height:
                                  _imageProcessBloc.renderedImageSize()!.height,
                              fontSize:
                                  _imageProcessBloc.renderedImageSize()!.width *
                                      0.04,
                            ),
                          ),
                        );
                      }
                    } else {
                      fm.WidgetsBinding.instance.addPostFrameCallback((_) {
                        final fm.RenderBox? renderBox = _imageKey.currentContext
                            ?.findRenderObject() as fm.RenderBox?;

                        if (renderBox?.size == null ||
                            renderBox!.size.width == 0) {
                          return;
                        }

                        _imageProcessBloc
                            .add(SetRenderedImageSize(renderBox.size));
                      });
                    }

                    return const fm.Material(color: fm.Colors.transparent);
                  },
                ),
              ],
            );
          }

          return const fm.Center(
            child: fm.Text('processing image',
                style: fm.TextStyle(fontSize: 16, color: fm.Color(0xffffffff))),
          );
        },
      ),
    );
  }

  fm.Widget _effectEditControl() {
    return fb.BlocBuilder<ImageProcessingBloc, ImageProcessingState>(
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
                  hintText: 'my-watermark@date@reason',
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

                  _watermarkingTextInputDebounce =
                      asyncx.Timer(const Duration(milliseconds: 640), () {
                    _imageProcessBloc.add(WatermarkingTextChange(val));
                  });
                },
              ),
            );
          case EditMode.zoom:
          case EditMode.angle:
          case EditMode.opacity:
          case EditMode.quality:
          case EditMode.sizeReduction:
            {
              return fb.BlocBuilder<ImageProcessingBloc, ImageProcessingState>(
                buildWhen: (_, curr) =>
                    curr is AngleChanged ||
                    curr is OpacityChanged ||
                    curr is ZoomChanged ||
                    curr is FinalProcessQualityChanged ||
                    curr is FinalProcessSizeReductionToChanged,
                builder: (context, state) {
                  int? divisions;
                  double min = 0;
                  double max = 100;
                  double value = 0;

                  Function(double)? updateVal;

                  late String leftIndicatorText;
                  late String rightIndicatorText;
                  late String middleIndicatorText;

                  if (currentEditMode == EditMode.angle) {
                    max = 360;
                    divisions = 360;
                    value = _imageProcessBloc.angleValue();
                    updateVal =
                        (newVal) => _imageProcessBloc.add(AngleChange(newVal));

                    leftIndicatorText = "Rotate Left";
                    rightIndicatorText = "Rotate Right";
                    middleIndicatorText = "Watermark Rotation";
                  }

                  if (currentEditMode == EditMode.zoom) {
                    min = -32;
                    divisions = 132;
                    value = _imageProcessBloc.zoomValue();
                    updateVal =
                        (newVal) => _imageProcessBloc.add(ZoomChange(newVal));

                    leftIndicatorText = "Zoom Out";
                    rightIndicatorText = "Zoom In";
                    middleIndicatorText = "Watermark Zoom";
                  }

                  if (currentEditMode == EditMode.opacity) {
                    divisions = 100;
                    value = _imageProcessBloc.opacityValue();
                    updateVal = (newVal) =>
                        _imageProcessBloc.add(OpacityChange(newVal));

                    leftIndicatorText = "Transparent";
                    rightIndicatorText = "Clear";
                    middleIndicatorText = "Watermark Transparency";
                  }

                  if (currentEditMode == EditMode.quality) {
                    value = _imageProcessBloc.finalProcessingQuality();
                    divisions = 100;
                    updateVal = (newVal) =>
                        _imageProcessBloc.add(SetFinalProcessQuality(newVal));

                    leftIndicatorText = "Low";
                    rightIndicatorText = "High";
                    middleIndicatorText = "Image Output Quality";
                  }

                  if (currentEditMode == EditMode.sizeReduction) {
                    divisions = 100;
                    value = _imageProcessBloc.finalProcessingSizeReductionTo();
                    updateVal = (newVal) => _imageProcessBloc
                        .add(SetFinalProcessSizeReductionTo(newVal));

                    leftIndicatorText = "Scale Down";
                    rightIndicatorText = "Scale Up";
                    middleIndicatorText = "Image Output Size Scaling";
                  }

                  return fm.Column(children: [
                    fm.Row(
                      mainAxisAlignment: fm.MainAxisAlignment.center,
                      children: [
                        fm.Text(
                          min.toInt().toString(),
                          style: const fm.TextStyle(
                              fontSize: 16, color: fm.Color(0xfff56300)),
                        ),
                        fm.Expanded(
                          child: fm.Slider(
                            min: min,
                            max: max,
                            value: value,
                            divisions: divisions,
                            onChanged: updateVal,
                            label: value.toInt().toString(),
                            thumbColor: const fm.Color(0xfff56400),
                            activeColor: const fm.Color(0xfff56400),
                            inactiveColor: const fm.Color(0xffffffff),
                            secondaryActiveColor: const fm.Color(0xffffffff),
                          ),
                        ),
                        fm.Text(
                          max.toInt().toString(),
                          style: const fm.TextStyle(
                              fontSize: 16, color: fm.Color(0xfff56300)),
                        ),
                      ],
                    ),
                    fm.Row(
                        crossAxisAlignment: fm.CrossAxisAlignment.center,
                        mainAxisAlignment: fm.MainAxisAlignment.spaceBetween,
                        children: [
                            fm.Text(
                                leftIndicatorText,
                                style: const fm.TextStyle(
                                    fontSize: 8, color: fm.Color(0xfff56300)
                                )
                            ),

                            fm.Text(
                                middleIndicatorText,
                                style: const fm.TextStyle(
                                    fontSize: 8, color: fm.Color(0xfff56300)
                                )
                            ),

                            fm.Text(
                                rightIndicatorText,
                                style: const fm.TextStyle(
                                    fontSize: 8, color: fm.Color(0xfff56300)
                                )
                            ),
                        ]),
                  ]);
                },
              );
            }

          default:
            {
              return const fm.Material();
            }
        }
      },
    );
  }

  fm.Widget _effectEditModes() {
    return fm.SizedBox(
      height: 64,
      width: double.infinity,
      child: fm.Center(
        child: fm.ListView(
          shrinkWrap: true,
          scrollDirection: fm.Axis.horizontal,
          children: [
            fb.BlocBuilder<ImageProcessingBloc, ImageProcessingState>(
              bloc: _imageProcessBloc,
              buildWhen: (_, curr) => curr is EditModeChanged,
              builder: (context, _) {
                return fm.Row(
                  children: [
                    _featureButton(fm.Icons.font_download, EditMode.text),
                    _featureButton(fm.Icons.opacity, EditMode.opacity),
                    _featureButton(fm.Icons.rotate_left, EditMode.angle),
                    _featureButton(fm.Icons.zoom_in_map_rounded, EditMode.zoom),
                    _featureButton(fm.Icons.high_quality, EditMode.quality),
                    _featureButton(fm.Icons.photo_size_select_large_sharp,
                        EditMode.sizeReduction),
                  ],
                );
              },
            ),
            _featureButton(
              fm.Icons.brightness_medium_outlined,
              EditMode.none,
              func: () {
                final imageProcess = context.read<ImageProcessingBloc>();

                if (imageProcess.isGrayscaled()) {
                  imageProcess.add(ImageGrayscaleToggle());
                  return;
                }

                imageProcess.add(ImageGrayscale());
              },
              child: fb.BlocSelector<ImageProcessingBloc, ImageProcessingState,
                      bool>(
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
                  }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  fm.Widget build(fm.BuildContext context) {
    return fm.Scaffold(
      appBar: fm.AppBar(
        backgroundColor: const fm.Color(0xff000000),
        actions: [
          fb.BlocBuilder<ImageProcessingBloc, ImageProcessingState>(
            bloc: _imageProcessBloc,
            buildWhen: (_, curr) =>
                curr is DoingFinalProcessing || curr is FinalProcessed,
            builder: (context, _) {
              return fm.TextButton(
                onPressed: _imageProcessBloc.isFinalProcessing()
                    ? null
                    : _exportImagePreview,
                child: const fm.Row(
                  children: [
                    fm.Text('Done',
                        style: fm.TextStyle(
                            fontSize: 16, color: fm.Color(0xffffffff))),
                    fm.SizedBox(width: 4),
                    fm.Icon(fm.Icons.done,
                        size: 26, color: fm.Color(0xffffffff)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: const fm.Color(0xff000000),
      body: fm.ListView(
        children: [
          _imagePreview(),
          const fm.SizedBox(height: 16),
          const fm.Divider(height: 8, color: fm.Color(0xffffffff)),
          const fm.SizedBox(height: 16),
          _effectEditControl(),
          const fm.SizedBox(height: 16),
          _effectEditModes(),
        ],
      ),
    );
  }
}
