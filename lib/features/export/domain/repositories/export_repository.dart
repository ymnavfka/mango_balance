import 'dart:typed_data';

import '../entities/export_options.dart';

class ExportPayload {
  const ExportPayload({
    required this.bytes,
    required this.profileNames,
    required this.transactionsCount,
  });

  final Uint8List bytes;
  final List<String> profileNames;
  final int transactionsCount;

  int get profilesCount => profileNames.length;
}

abstract class ExportRepository {
  Future<ExportPayload> buildXlsx(ExportOptions options);
}
