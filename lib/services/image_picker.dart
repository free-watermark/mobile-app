
import 'package:image_picker/image_picker.dart' as imgp;

abstract class ImagePicker {
  Future<imgp.XFile?> pickImage({required imgp.ImageSource source});
}

class ImagePickerService implements ImagePicker {
  final imgp.ImagePicker _imagePicker = imgp.ImagePicker();

  @override
  Future<imgp.XFile?> pickImage({required imgp.ImageSource source}) {
    return _imagePicker.pickImage(source: source);
  }
}

typedef FilePathSupplier = Future<String> Function();

class ImagePickerMockService implements ImagePicker {
  final FilePathSupplier filePathSupplier;

  ImagePickerMockService({
    required this.filePathSupplier,
  });

  @override
  Future<imgp.XFile?> pickImage({required imgp.ImageSource source}) async =>
    Future.value(imgp.XFile(await filePathSupplier()));
}
