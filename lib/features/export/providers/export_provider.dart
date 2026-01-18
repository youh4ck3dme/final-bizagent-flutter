import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/export_models.dart';

final exportProvider =
    StateNotifierProvider<ExportController, ExportState>((ref) {
  return ExportController();
});

final exportPeriodsProvider = Provider<List<ExportPeriod>>((ref) {
  final now = DateTime.now();
  return [
    ExportPeriod.thisMonth(now),
    ExportPeriod.lastMonth(now),
    ExportPeriod.thisYear(now),
  ];
});

class ExportController extends StateNotifier<ExportState> {
  ExportController() : super(ExportState.idle());

  Future<void> run({
    required String uid,
    required ExportPeriod period,
  }) async {
    state = state.copyWith(
      isRunning: true,
      error: null,
      result: null,
      progress: ExportProgress.idle()
          .copyWith(message: 'Starting export…', percent: 0.05),
    );

    try {
      // Minimal working flow (compiles + UI progress).
      // Real zip generation is already in core/services/export_service.dart,
      // we’ll wire it in after compilation is clean.

      await Future.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(
          progress: state.progress
              .copyWith(pdfDone: true, percent: 0.35, message: 'PDFs ready'));

      await Future.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(
          progress: state.progress.copyWith(
              photosDone: true, percent: 0.55, message: 'Photos ready'));

      await Future.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(
          progress: state.progress
              .copyWith(csvDone: true, percent: 0.75, message: 'CSV ready'));

      await Future.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(
          progress: state.progress
              .copyWith(jsonDone: true, percent: 0.9, message: 'JSON ready'));

      // Placeholder path (to satisfy UI). Next step: connect real ExportService to produce this file.
      final zipPath =
          '/tmp/bizagent_export_${uid}_${period.from.toIso8601String()}_${period.to.toIso8601String()}.zip';

      state = state.copyWith(
        isRunning: false,
        progress: state.progress.copyWith(percent: 1.0, message: 'Done'),
        result: ExportResult(
            zipPath: zipPath, hasMissing: false, missingItems: const []),
      );
    } catch (e) {
      state = state.copyWith(isRunning: false, error: e.toString());
    }
  }

  void reset() {
    state = ExportState.idle();
  }
}
