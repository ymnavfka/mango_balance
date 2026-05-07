import '../../domain/entities/import_result.dart';
import '../../domain/entities/parsed_import.dart';

enum ImportStatus { idle, parsing, ready, importing, success, failure }

class ImportState {
  ImportState({
    required this.status,
    required this.fileName,
    required this.parsed,
    required this.result,
    required this.errorMessage,
  });

  factory ImportState.initial() {
    return ImportState(
      status: ImportStatus.idle,
      fileName: null,
      parsed: null,
      result: null,
      errorMessage: null,
    );
  }

  final ImportStatus status;
  final String? fileName;
  final ParsedImport? parsed;
  final ImportResult? result;
  final String? errorMessage;

  ImportState copyWith({
    ImportStatus? status,
    String? fileName,
    ParsedImport? parsed,
    ImportResult? result,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ImportState(
      status: status ?? this.status,
      fileName: fileName ?? this.fileName,
      parsed: parsed ?? this.parsed,
      result: result ?? this.result,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
