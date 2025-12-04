// Stub implementation for web platform to replace path_provider functionality

/// Web stub for getApplicationDocumentsDirectory
/// This function should never be called on web as we use web-specific recording
Future<Directory> getApplicationDocumentsDirectory() async {
  throw UnsupportedError('getApplicationDocumentsDirectory is not supported on web');
}

/// Mock Directory class for web compilation
class Directory {
  final String path;
  Directory(this.path);
}