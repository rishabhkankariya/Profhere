import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/excel_service.dart';
import '../../data/services/timetable_import_service.dart';
import 'supabase_provider.dart';

final excelServiceProvider = Provider<ExcelService>((ref) {
  return ExcelService();
});

final timetableImportServiceProvider = Provider<TimetableImportService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return null;
  }

  return TimetableImportService(client);
});

final timetableImportControllerProvider =
    AsyncNotifierProvider<TimetableImportController, TimetableImportResult?>(
      TimetableImportController.new,
    );

class TimetableImportController extends AsyncNotifier<TimetableImportResult?> {
  @override
  Future<TimetableImportResult?> build() async {
    return null;
  }

  Future<TimetableImportResult> pickAndImport() async {
    final excelService = ref.read(excelServiceProvider);
    final importService = ref.read(timetableImportServiceProvider);

    if (importService == null) {
      throw StateError('Supabase is not configured.');
    }

    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      final rows = await excelService.pickAndParseTimetable();
      return importService.importRows(rows);
    });

    state = result;
    if (!result.hasValue) {
      throw result.error!;
    }

    return result.requireValue;
  }
}
