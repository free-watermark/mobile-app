
import 'dart:io' as io;
import 'dart:isolate' as isl;
import 'dart:convert' as cvrt;

import 'package:image/image.dart' as img;
import 'package:nanoid/nanoid.dart' as nid;
import 'package:equatable/equatable.dart' as eq;
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter_bloc/flutter_bloc.dart' as fb;
import 'package:image_picker/image_picker.dart' as imgp;
import 'package:path_provider/path_provider.dart' as pd;
import 'package:flutter_isolate/flutter_isolate.dart' as fi;

abstract class ImageProcessingState extends eq.Equatable {
  @override
  List<Object> get props => [];
}

class ImageLoading extends ImageProcessingState {}

class ImageLoaded extends ImageProcessingState {}

class ImageGrayscaling extends ImageProcessingState {}

class ImageGrayscaled extends ImageProcessingState {}

class ImageGrayscaleToggled extends ImageProcessingState {
  final bool isGrayscaled;

  ImageGrayscaleToggled(this.isGrayscaled);

  @override
  List<Object> get props => [isGrayscaled];
}

abstract class ImageProcessingEvent {}

class LoadImage extends ImageProcessingEvent {}

class ImageGrayscale extends ImageProcessingEvent {}

class ImageGrayscaleToggle extends ImageProcessingEvent {}

class LoadImageDone extends ImageProcessingEvent {}

class ImageGrayscaleDone extends ImageProcessingEvent {}

class ImageProcessingBloc extends fb.Bloc<ImageProcessingEvent, ImageProcessingState> {
  bool _isGrayscaled = false;
  bool _isGrayscaling = false;
  bool _isImageLoaded = false;
  bool _isLoadingImage = true;
  bool _grayscaleToggled = false;

  final dynamic imageFile;

  final isl.ReceivePort _mainThreadReceiver = isl.ReceivePort();

  late final io.Directory _workingDir;
  late final String _workingFileTempId;
  late final fi.FlutterIsolate _workerThread;
  late final isl.SendPort _workerThreadSendPort;

  bool isLoadingImage() {
    return _isLoadingImage;
  }

  bool isGrayscaling() {
    return _isGrayscaling;
  }

  bool isGrayscaled() {
    return _isGrayscaled;
  }

  bool isToggleGrayscaled() {
    return _grayscaleToggled;
  }

  String getOriginalImagePath() {
    return '${_workingDir.path}/$_workingFileTempId';
  }

  String getGrayscaledImagePath() {
    return '${getOriginalImagePath()}-grayscale';
  }

  void dispose() {
    _workerThread.kill();
    _mainThreadReceiver.close();
  }

  ImageProcessingBloc(this.imageFile): super(ImageLoading()) {
    on<LoadImageDone>((_, emit) {
      _isImageLoaded = true;
      _isLoadingImage = false;

      emit(ImageLoaded());
    });

    on<ImageGrayscaleDone>((_, emit) {
      _isGrayscaled = true;
      _isGrayscaling = false;

      emit(ImageGrayscaled());

      _grayscaleToggled = !_grayscaleToggled;

      emit(ImageGrayscaleToggled(_grayscaleToggled));
    });

    on<LoadImage>((_, emit) async {
      await fi.FlutterIsolate.spawn(readAndRotateImage, _mainThreadReceiver.sendPort).then((t) async {
        _workerThread = t;

        _workingDir = await pd.getTemporaryDirectory();

        _mainThreadReceiver.listen((msg) {
          if (msg is isl.SendPort) {
            _workerThreadSendPort = msg;

            final String imgPath = cvrt.base64Encode(cvrt.utf8.encode(imageFile is imgp.XFile
              ? (imageFile as imgp.XFile).path
              : (imageFile as fp.FilePickerResult).paths[0]!));

            _workerThreadSendPort.send('image@read-rotate.$imgPath');
          }

          if (msg is String && msg.contains('working-file-temp-id@set.')) {
            _workingFileTempId = msg.split('.')[1];
          }

          if (msg is String) {
            if (msg == 'image@grayscale:done') {
              add(ImageGrayscaleDone()); 
            }

            if (msg == 'image@read-rotate:done') {
              add(LoadImageDone());
            }
          }
        });
      });
    });

    on<ImageGrayscale>((_, emit) {
      if (_isGrayscaled || _isGrayscaling) {
        return;
      }

      _isGrayscaling = true;

      emit(ImageGrayscaling());

      _workerThreadSendPort.send('image@grayscale');
    });

    on<ImageGrayscaleToggle>((_, emit) {
      _grayscaleToggled = !_grayscaleToggled;

      emit(ImageGrayscaleToggled(_grayscaleToggled));
    });
  }
}

@pragma('vm:entry-point')
Future<void> readAndRotateImage(isl.SendPort sendPort) async {
  final isl.ReceivePort workerThreadReceiver = isl.ReceivePort();

  sendPort.send(workerThreadReceiver.sendPort);

  img.Image? image;

  final String tempId = nid.nanoid(16);
  final io.Directory tempDir = await pd.getTemporaryDirectory();

  sendPort.send('working-file-temp-id@set.$tempId');

  workerThreadReceiver.listen((message) async {
    if (message is String && message.contains('image@read-rotate.')) {
      final String imgPath = String.fromCharCodes(cvrt.base64Decode(message.split('.')[1]));

      if (await io.File('${tempDir.path}/$tempId').exists()) {
        return;
      }

      image = await img.decodeImageFile(imgPath);

      if (image != null) {
        if (image!.width > image!.height) {
          image = img.copyRotate(image!, angle: -90);

          await img.encodeJpgFile('${tempDir.path}/$tempId', image!);
        } else {
          await img.encodeJpgFile('${tempDir.path}/$tempId', image!);
        }

        sendPort.send('image@read-rotate:done');
      }
    }

    if (message is String && message == 'image@grayscale') {
      if (await io.File('${tempDir.path}/$tempId-grayscale').exists()) {
        sendPort.send('image@grayscale:done');

        return;
      }

      if (image != null) {
        await img.encodeJpgFile('${tempDir.path}/$tempId-grayscale', img.grayscale(image!));

        sendPort.send('image@grayscale:done');
      }
    }
  });
}
