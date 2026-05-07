import 'dart:typed_data';

import '../entities/export_options.dart';

class ExportPayload {
  const ExportPayload({
    required this.bytes,
    required this.profileName,
    required this.exportedTransactions,
  });

  final Uint8List bytes;
  final String profileName;
  final int exportedTransactions;
}

abstract class ExportRepository {
  Future<ExportPayload> buildXlsx(ExportOptions options);
}
