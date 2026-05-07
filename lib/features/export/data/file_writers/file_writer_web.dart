import 'dart:typed_data';

Future<void> writeBytesToPath(String path, Uint8List bytes) async {
  // Not used on web — file_picker.saveFile writes the file via blob download.
  throw UnsupportedError('writeBytesToPath is not supported on web');
}
