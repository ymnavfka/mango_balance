import '../entities/backup_data.dart';
import '../entities/restore_result.dart';
import '../repositories/import_repository.dart';

class RestoreBackup {
  RestoreBackup(this.repository);

  final ImportRepository repository;

  Future<RestoreResult> call(BackupData data) => repository.restore(data);
}
