import '../entities/import_result.dart';
import '../entities/parsed_import.dart';
import '../repositories/import_repository.dart';

class ImportToProfile {
  ImportToProfile(this.repository);

  final ImportRepository repository;

  Future<ImportResult> call({
    required int profileId,
    required ParsedImport data,
  }) {
    return repository.import(profileId: profileId, data: data);
  }
}
