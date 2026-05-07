import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'file_writer_stub.dart'
    if (dart.library.io) 'file_writer_io.dart'
    if (dart.library.html) 'file_writer_web.dart';

class XlsxFileSaver {
  Future<String?> save({
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return FilePicker.platform.saveFile(
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: bytes,
      );
    }

    final path = await FilePicker.platform.saveFile(
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (path == null) return null;

    final pathWithExtension = path.toLowerCase().endsWith('.xlsx')
        ? path
        : '$path.xlsx';
    await writeBytesToPath(pathWithExtension, bytes);
    return pathWithExtension;
  }
}
