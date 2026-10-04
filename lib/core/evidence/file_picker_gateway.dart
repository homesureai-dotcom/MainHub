import 'package:file_picker/file_picker.dart';

import 'file_picker_selection.dart';

/// Small platform boundary around [FilePicker].
///
/// Keeping the Flutter plugin behind this interface allows the evidence
/// capture service to be tested without opening a native file picker or
/// depending on plugin-specific model types.
abstract interface class FilePickerGateway {
  Future<FilePickerSelection?> pickDocument();
}

/// Production implementation backed by the file_picker package.
class PlatformFilePickerGateway implements FilePickerGateway {
  const PlatformFilePickerGateway();

  @override
  Future<FilePickerSelection?> pickDocument() async {
    final file = await FilePicker.pickFile();

    if (file == null) {
      return null;
    }

    return FilePickerSelection(
      name: file.name,
      path: file.path,
    );
  }
}