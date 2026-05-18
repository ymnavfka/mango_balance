import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../profiles/domain/usecases/create_profile.dart';
import '../../domain/usecases/import_to_profile.dart';
import '../../domain/usecases/parse_xlsx_file.dart';
import 'import_state.dart';

class ImportCubit extends Cubit<ImportState> {
  ImportCubit({
    required this.parseXlsxFileUseCase,
    required this.importToProfileUseCase,
    required this.createProfileUseCase,
  }) : super(ImportState.initial());

  final ParseXlsxFile parseXlsxFileUseCase;
  final ImportToProfile importToProfileUseCase;
  final CreateProfile createProfileUseCase;

  Future<void> loadFile({
    required String fileName,
    required Uint8List bytes,
  }) async {
    emit(
      state.copyWith(
        status: ImportStatus.parsing,
        fileName: fileName,
        clearError: true,
      ),
    );
    try {
      final parsed = parseXlsxFileUseCase(bytes);
      if (parsed.totalTransactions == 0) {
        emit(
          state.copyWith(
            status: ImportStatus.failure,
            errorMessage: 'В файле не найдено транзакций',
          ),
        );
        return;
      }
      emit(state.copyWith(status: ImportStatus.ready, parsed: parsed));
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportStatus.failure,
          errorMessage: 'Не удалось прочитать файл: $e',
        ),
      );
    }
  }

  Future<void> importIntoExisting(int profileId) async {
    final parsed = state.parsed;
    if (parsed == null) return;

    emit(state.copyWith(status: ImportStatus.importing, clearError: true));
    try {
      final result = await importToProfileUseCase(
        profileId: profileId,
        data: parsed,
      );
      emit(state.copyWith(status: ImportStatus.success, result: result));
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportStatus.failure,
          errorMessage: 'Ошибка импорта: $e',
        ),
      );
    }
  }

  Future<void> importIntoNewProfile({
    required String name,
    required bool includeStandardData,
  }) async {
    final parsed = state.parsed;
    if (parsed == null) return;

    emit(state.copyWith(status: ImportStatus.importing, clearError: true));
    try {
      final newProfileId = await createProfileUseCase(
        name: name,
        includeStandardData: includeStandardData,
      );
      final result = await importToProfileUseCase(
        profileId: newProfileId,
        data: parsed,
      );
      emit(state.copyWith(status: ImportStatus.success, result: result));
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportStatus.failure,
          errorMessage: 'Ошибка импорта: $e',
        ),
      );
    }
  }

  void reset() {
    emit(ImportState.initial());
  }
}
