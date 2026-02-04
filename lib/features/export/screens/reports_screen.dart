import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../models/export_models.dart';
import '../providers/report_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/analytics_service.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ExportPeriod _period = _thisMonth();

  static ExportPeriod _thisMonth() {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return ExportPeriod(from: from, to: to);
  }

  static ExportPeriod _lastMonth() {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month - 1, 1);
    final to = DateTime(now.year, now.month, 0, 23, 59, 59);
    return ExportPeriod(from: from, to: to);
  }

  static ExportPeriod _thisQuarter() {
    final now = DateTime.now();
    final quarter = ((now.month - 1) ~/ 3) * 3 + 1;
    final from = DateTime(now.year, quarter, 1);
    final to = DateTime(now.year, quarter + 3, 0, 23, 59, 59);
    return ExportPeriod(from: from, to: to);
  }

  static ExportPeriod _thisYear() {
    final now = DateTime.now();
    final from = DateTime(now.year, 1, 1);
    final to = DateTime(now.year, 12, 31, 23, 59, 59);
    return ExportPeriod(from: from, to: to);
  }

  bool _isCustomPeriod = false;

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportControllerProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final pdfService = ref.read(pdfServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manažérske Reporty')),
      body: Column(
        children: [
          _buildPeriodSelector(),
          const Divider(height: 1),
          Expanded(
            child: reportAsync.when(
              data: (report) {
                if (report == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.analytics_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text('Vyberte obdobie a vygenerujte report'),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () {
                            ref
                                .read(analyticsServiceProvider)
                                .logReportGenerated(
                                  '${_period.from.month}/${_period.from.year}',
                                );
                            ref
                                .read(reportControllerProvider.notifier)
                                .generateReport(_period);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Generovať Report'),
                        ),
                      ],
                    ),
                  );
                }

                return settingsAsync.when(
                  data: (settings) => PdfPreview(
                    build: (format) =>
                        pdfService.generateBusinessReport(report, settings),
                    canDebug: false,
                    allowPrinting: true,
                    allowSharing: true,
                    pdfFileName:
                        'report_${report.from.year}_${report.from.month}.pdf',
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, __) => Center(child: Text('Chyba nastavení: $e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text('Chyba pri generovaní: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('Mesiac'),
                      icon: Icon(Icons.calendar_month),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('Min. mes.'),
                      icon: Icon(Icons.history),
                    ),
                  ],
                  selected: {
                    !_isCustomPeriod &&
                            _period.from.month == DateTime.now().month
                        ? 0
                        : 1,
                  },
                  onSelectionChanged: (val) {
                    setState(() {
                      _isCustomPeriod = false;
                      _period = val.first == 0 ? _thisMonth() : _lastMonth();
                    });
                    ref
                        .read(reportControllerProvider.notifier)
                        .generateReport(_period);
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Date Range Picker Button
              IconButton.filled(
                onPressed: _showDateRangePicker,
                icon: const Icon(Icons.date_range),
                tooltip: 'Vlastné obdobie',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quick Presets
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Tento kvartál'),
                avatar: const Icon(Icons.calendar_view_week, size: 16),
                onPressed: () {
                  setState(() {
                    _isCustomPeriod = true;
                    _period = _thisQuarter();
                  });
                  ref
                      .read(reportControllerProvider.notifier)
                      .generateReport(_period);
                },
              ),
              ActionChip(
                label: const Text('Celý rok'),
                avatar: const Icon(Icons.calendar_today, size: 16),
                onPressed: () {
                  setState(() {
                    _isCustomPeriod = true;
                    _period = _thisYear();
                  });
                  ref
                      .read(reportControllerProvider.notifier)
                      .generateReport(_period);
                },
              ),
              if (_isCustomPeriod)
                Chip(
                  label: Text(
                    '${_formatDate(_period.from)} - ${_formatDate(_period.to)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _isCustomPeriod = false;
                      _period = _thisMonth();
                    });
                    ref
                        .read(reportControllerProvider.notifier)
                        .generateReport(_period);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _period.from, end: _period.to),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      setState(() {
        _isCustomPeriod = true;
        _period = ExportPeriod(
          from: range.start,
          to: DateTime(
            range.end.year,
            range.end.month,
            range.end.day,
            23,
            59,
            59,
          ),
        );
      });
      ref.read(reportControllerProvider.notifier).generateReport(_period);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
