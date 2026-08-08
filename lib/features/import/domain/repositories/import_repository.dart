import '../entities/backup_data.dart';
import '../entities/import_result.dart';
import '../entities/parsed_import.dart';
import '../entities/restore_result.dart';

abstract class ImportRepository {
  Future<ImportResult> import({
    required int profileId,
    required ParsedImport data,
  });

  /// Восстанавливает полный бэкап: создаёт новые профили (с уникализацией имён
  /// при коллизиях) со всеми счетами, категориями, операциями, бюджетами и
  /// регулярными платежами.
  Future<RestoreResult> restore(BackupData data);
}
