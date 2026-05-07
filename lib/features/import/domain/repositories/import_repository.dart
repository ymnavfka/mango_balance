import '../entities/import_result.dart';
import '../entities/parsed_import.dart';

abstract class ImportRepository {
  Future<ImportResult> import({
    required int profileId,
    required ParsedImport data,
  });
}
