import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/file_writers/xlsx_file_saver.dart';
import '../../domain/entities/export_options.dart';
import '../../domain/entities/export_result.dart';
import '../../domain/usecases/build_xlsx_export.dart';
import 'export_state.dart';

class ExportCubit extends Cubit<ExportState> {
  ExportCubit({required this.buildXlsxExportUseCase, required this.fileSaver})
    : super(ExportState.initial());

  final BuildXlsxExport buildXlsxExportUseCase;
  final XlsxFileSaver fileSaver;

  Future<void> exportToXlsx({
    required int profileId,
    required DateTime? dateFrom,
    required DateTime? dateTo,
  }) async {
    emit(
      state.copyWith(
        status: ExportStatus.working,
        clearError: true,
        clearResult: true,
      ),
    );

    try {
      final adjustedTo = dateTo == null
          ? null
          : DateTime(dateTo.year, dateTo.month, dateTo.day, 23, 59, 59, 999);
      final adjustedFrom = dateFrom == null
          ? null
          : DateTime(dateFrom.year, dateFrom.month, dateFrom.day);

      final payload = await buildXlsxExportUseCase(
        ExportOptions(
          profileId: profileId,
          dateFrom: adjustedFrom,
          dateTo: adjustedTo,
        ),
      );

      if (payload.exportedTransactions == 0) {
        emit(
          state.copyWith(
            status: ExportStatus.failure,
            errorMessage: 'No transactions match the selected range',
          ),
        );
        return;
      }

      final fileName = _buildFileName(payload.profileName);
      final savedPath = await fileSaver.save(
        fileName: fileName,
        bytes: payload.bytes,
      );

      if (savedPath == null) {
        emit(state.copyWith(status: ExportStatus.cancelled));
        return;
      }

      emit(
        state.copyWith(
          status: ExportStatus.success,
          result: ExportResult(
            profileName: payload.profileName,
            exportedTransactions: payload.exportedTransactions,
            savedPath: savedPath,
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ExportStatus.failure,
          errorMessage: 'Export failed: $e',
        ),
      );
    }
  }

  String _buildFileName(String profileName) {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final safeProfile = _sanitizeFileSegment(profileName);
    return 'mango_balance_${safeProfile}_$date.xlsx';
  }

  String _sanitizeFileSegment(String value) {
    final sanitized = value
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    if (sanitized.isEmpty) return 'profile';
    return sanitized;
  }
}
