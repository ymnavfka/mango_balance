import '../entities/export_options.dart';
import '../repositories/export_repository.dart';

class BuildXlsxExport {
  BuildXlsxExport(this.repository);

  final ExportRepository repository;

  Future<ExportPayload> call(ExportOptions options) {
    return repository.buildXlsx(options);
  }
}
