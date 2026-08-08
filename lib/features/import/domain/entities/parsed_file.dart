import 'backup_data.dart';
import 'parsed_import.dart';

/// Результат разбора выбранного файла: либо полный бэкап (новый формат со всеми
/// сущностями), либо устаревший файл только с транзакциями.
class ParsedFile {
  const ParsedFile.backup(BackupData this.backup) : legacy = null;
  const ParsedFile.legacy(ParsedImport this.legacy) : backup = null;

  final BackupData? backup;
  final ParsedImport? legacy;

  bool get isBackup => backup != null;
}
