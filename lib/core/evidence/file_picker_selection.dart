/// Represents a document selected through the platform file picker.
///
/// This model deliberately does not expose file_picker plugin types to the
/// evidence domain or application layer.
class FilePickerSelection {
  final String name;
  final String? path;

  const FilePickerSelection({
    required this.name,
    required this.path,
  });
}