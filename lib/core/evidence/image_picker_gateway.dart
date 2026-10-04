import 'package:image_picker/image_picker.dart';

import 'image_picker_selection.dart';

/// Provides access to the platform image picker.
///
/// The evidence layer depends on this gateway rather than directly on
/// image_picker plugin types.
abstract interface class ImagePickerGateway {
  Future<ImagePickerSelection?> pickPhotograph();

  Future<ImagePickerSelection?> captureVideo();
}

/// Production implementation backed by the image_picker package.
class PlatformImagePickerGateway implements ImagePickerGateway {
  final ImagePicker _picker;

  PlatformImagePickerGateway({
    ImagePicker? picker,
  }) : _picker = picker ?? ImagePicker();

  @override
  Future<ImagePickerSelection?> pickPhotograph() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
    );

    if (image == null) {
      return null;
    }

    return ImagePickerSelection(
      path: image.path,
      name: image.name,
    );
  }

  @override
  Future<ImagePickerSelection?> captureVideo() async {
    final video = await _picker.pickVideo(
      source: ImageSource.camera,
    );

    if (video == null) {
      return null;
    }

    return ImagePickerSelection(
      path: video.path,
      name: video.name,
    );
  }
}