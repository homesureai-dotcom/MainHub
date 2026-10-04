/// Represents a photograph selected or captured through the platform
/// image picker.
///
/// This model deliberately does not expose image_picker plugin types to
/// the evidence domain or application layer.
class ImagePickerSelection {
  final String? path;
  final String? name;

  const ImagePickerSelection({
    required this.path,
    this.name,
  });
}