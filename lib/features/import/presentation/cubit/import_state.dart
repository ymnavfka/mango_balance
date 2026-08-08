import '../../domain/entities/import_result.dart';
import '../../domain/entities/parsed_file.dart';
import '../../domain/entities/restore_result.dart';

enum ImportStatus { idle, parsing, ready, importing, success, failure }

class ImportState {
  ImportState({
    required this.status,
    required this.fileName,
    required this.parsed,
    required this.result,
    required this.restoreResult,
    required this.errorMessage,
  });

  factory ImportState.initial() {
    return ImportState(
      status: ImportStatus.idle,
      fileName: null,
      parsed: null,
      result: null,
      restoreResult: null,
      errorMessage: null,
    );
  }

  final ImportStatus status;
  final String? fileName;
  final ParsedFile? parsed;
  final ImportResult? result;
  final RestoreResult? restoreResult;
  final String? errorMessage;

  bool get isBackup => parsed?.isBackup ?? false;

  ImportState copyWith({
    ImportStatus? status,
    String? fileName,
    ParsedFile? parsed,
    ImportResult? result,
    RestoreResult? restoreResult,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ImportState(
      status: status ?? this.status,
      fileName: fileName ?? this.fileName,
      parsed: parsed ?? this.parsed,
      result: result ?? this.result,
      restoreResult: restoreResult ?? this.restoreResult,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
