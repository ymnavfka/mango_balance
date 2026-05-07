import '../../domain/entities/export_result.dart';

enum ExportStatus { idle, working, success, failure, cancelled }

class ExportState {
  ExportState({
    required this.status,
    required this.result,
    required this.errorMessage,
  });

  factory ExportState.initial() {
    return ExportState(
      status: ExportStatus.idle,
      result: null,
      errorMessage: null,
    );
  }

  final ExportStatus status;
  final ExportResult? result;
  final String? errorMessage;

  ExportState copyWith({
    ExportStatus? status,
    ExportResult? result,
    String? errorMessage,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return ExportState(
      status: status ?? this.status,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
