import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../models/article.dart';
import '../../shared/excel_export.dart';
import '../../shared/formatters.dart';
import 'import_files.dart';
import 'import_parser.dart';
import 'import_validator.dart';

enum _RowFilter { all, errors, ready }

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  int _step = 0;
  bool _dragging = false;
  bool _loading = false;
  String? _fileName;
  String? _fileError;
  List<ImportRow> _rows = <ImportRow>[];
  _RowFilter _filter = _RowFilter.all;
  bool _updateExisting = false;
  ImportOutcome? _outcome;
  int _errorsLeftOut = 0;

  ImportSummary get _summary => ImportSummary(_rows);

  /// Rows that will be added or updated with the current choices.
  int get _importCount {
    final s = _summary;
    return _updateExisting ? s.importable : s.importable - s.existing;
  }

  // ------------------------------------------------------------------ actions

  Future<void> _loadBytes(String name, Uint8List bytes) async {
    final store = context.read<AppStore>();
    final parsed = parseImportFile(bytes);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _fileName = name;
      if (!parsed.ok) {
        _fileError = parsed.error ??
            'The file is missing these columns: ${parsed.missingHeaders.join(', ')}. '
                'Download the template to see the expected layout.';
        return;
      }
      _fileError = null;
      _rows = validateImportRows(
        parsed.rows,
        <String>{for (final a in store.articles) a.articleCode},
      );
      _filter = _RowFilter.all;
      _updateExisting = false;
      _outcome = null;
      _step = 1;
    });
  }

  Future<void> _chooseFile() async {
    final picked = await FilePicker.pickFiles(
      dialogTitle: 'Choose Excel file',
      type: FileType.custom,
      allowedExtensions: const <String>['xlsx'],
    );
    if (picked.isEmpty || !mounted) return;
    setState(() => _loading = true);
    try {
      final bytes = await picked.first.xFile.readAsBytes();
      await _loadBytes(picked.first.name, bytes);
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _fileError = 'Could not open the file: $error';
        });
      }
    }
  }

  Future<void> _onDrop(DropDoneDetails details) async {
    setState(() => _dragging = false);
    if (details.files.isEmpty) return;
    final file = details.files.first;
    if (!file.name.toLowerCase().endsWith('.xlsx')) {
      setState(() {
        _fileName = file.name;
        _fileError = 'Only Excel .xlsx files can be imported.';
      });
      return;
    }
    setState(() => _loading = true);
    try {
      await _loadBytes(file.name, await file.readAsBytes());
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _fileError = 'Could not open the file: $error';
        });
      }
    }
  }

  Future<void> _loadSample() async {
    setState(() => _loading = true);
    final data = await rootBundle.load('assets/sample_import.xlsx');
    await _loadBytes('sample_import.xlsx', data.buffer.asUint8List());
  }

  Future<void> _downloadTemplate() {
    return exportToExcel(
      context,
      filePrefix: 'article_import_template',
      sheets: <ExportSheet>[buildTemplateSheet()],
      rowCount: 3,
      datedName: false,
    );
  }

  Future<void> _downloadErrorRows() {
    return exportToExcel(
      context,
      filePrefix: 'import_errors',
      sheets: <ExportSheet>[buildErrorRowsSheet(_rows)],
      rowCount: _summary.errors,
    );
  }

  void _runImport() {
    final store = context.read<AppStore>();
    final today = dateOnly(DateTime.now());
    var serial = store.articles.length;
    final incoming = <Article>[
      for (final r in _rows)
        if (r.importable) r.toArticle(today, ++serial),
    ];
    final outcome = store.importArticles(incoming, updateExisting: _updateExisting);
    setState(() {
      _outcome = outcome;
      _errorsLeftOut = _summary.errors;
    });
  }

  void _reset() {
    setState(() {
      _step = 0;
      _rows = <ImportRow>[];
      _fileName = null;
      _fileError = null;
      _outcome = null;
    });
  }

  // -------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _StepHeader(step: _step),
        const Divider(height: 1),
        Expanded(
          child: switch (_step) {
            0 => _buildChooseStep(context),
            1 => _buildPreviewStep(context),
            _ => _buildConfirmStep(context),
          },
        ),
      ],
    );
  }

  Widget _buildChooseStep(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dropSupported = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;

    final dropArea = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 190,
      decoration: BoxDecoration(
        color: _dragging ? scheme.primary.withValues(alpha: 0.10) : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _dragging ? scheme.primary : scheme.outline,
          width: _dragging ? 2 : 1,
        ),
      ),
      child: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.upload_file_outlined, size: 40, color: scheme.primary),
                  const SizedBox(height: 10),
                  Text(
                    _dragging ? 'Drop the file to load it' : 'Drag and drop an Excel file here',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('or', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _chooseFile,
                    icon: const Icon(Icons.folder_open_outlined, size: 18),
                    label: const Text('Choose Excel file'),
                  ),
                ],
              ),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Add many articles at once', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Fill in the template in Excel, then load it here. Nothing is saved until '
                'you have checked the preview and confirmed.',
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              if (dropSupported)
                DropTarget(
                  onDragEntered: (_) => setState(() => _dragging = true),
                  onDragExited: (_) => setState(() => _dragging = false),
                  onDragDone: _onDrop,
                  child: dropArea,
                )
              else
                dropArea,
              if (_fileError != null) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.error_outline, color: scheme.onErrorContainer),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${_fileName == null ? '' : '$_fileName: '}$_fileError',
                          style: TextStyle(color: scheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: _downloadTemplate,
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('Download template'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _loadSample,
                    icon: const Icon(Icons.science_outlined, size: 18),
                    label: const Text('Load sample file (200 rows)'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Columns in the file', style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              Text(
                'The first row must hold the column names. Capital letters and extra spaces '
                'do not matter, and any other columns in the file are ignored. '
                'Columns marked * are required.',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final f in importFields)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        requiredImportKeys.contains(f.key) ? '${f.header} *' : f.header,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Category must be Gold, Diamond, Silver or Platinum. Weights are in grams. '
                'Prices are in whole rupees.',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewStep(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summary = _summary;
    final visible = _rows.where((r) {
      switch (_filter) {
        case _RowFilter.all:
          return true;
        case _RowFilter.errors:
          return r.state == ImportRowState.error;
        case _RowFilter.ready:
          return r.importable;
      }
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.description_outlined, size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    '${_fileName ?? ''}  ·  ${formatCount(_rows.length)} rows',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  children: <InlineSpan>[
                    TextSpan(
                      text: '${formatCount(summary.ready)} ready to import',
                      style: const TextStyle(color: Color(0xFF2E7D32)),
                    ),
                    const TextSpan(text: ',  '),
                    TextSpan(
                      text: '${formatCount(summary.warnings)} warnings',
                      style: const TextStyle(color: Color(0xFF9A6700)),
                    ),
                    const TextSpan(text: ',  '),
                    TextSpan(
                      text: '${formatCount(summary.errors)} errors',
                      style: const TextStyle(color: Color(0xFFC62828)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rows with warnings are still imported. Rows with errors are left out.',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  SegmentedButton<_RowFilter>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity(horizontal: -2, vertical: -2),
                    ),
                    segments: const <ButtonSegment<_RowFilter>>[
                      ButtonSegment<_RowFilter>(value: _RowFilter.all, label: Text('All')),
                      ButtonSegment<_RowFilter>(
                        value: _RowFilter.errors,
                        label: Text('Errors only'),
                      ),
                      ButtonSegment<_RowFilter>(
                        value: _RowFilter.ready,
                        label: Text('Ready only'),
                      ),
                    ],
                    selected: <_RowFilter>{_filter},
                    onSelectionChanged: (Set<_RowFilter> v) => setState(() => _filter = v.first),
                  ),
                  OutlinedButton.icon(
                    onPressed: summary.errors == 0 ? null : _downloadErrorRows,
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('Download error rows'),
                  ),
                  if (summary.existing > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '${formatCount(summary.existing)} already exist in stock:',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 8),
                        SegmentedButton<bool>(
                          showSelectedIcon: false,
                          style: const ButtonStyle(
                            visualDensity: VisualDensity(horizontal: -2, vertical: -2),
                          ),
                          segments: const <ButtonSegment<bool>>[
                            ButtonSegment<bool>(value: false, label: Text('Skip them')),
                            ButtonSegment<bool>(value: true, label: Text('Update existing')),
                          ],
                          selected: <bool>{_updateExisting},
                          onSelectionChanged: (Set<bool> v) =>
                              setState(() => _updateExisting = v.first),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _PreviewTable(rows: visible)),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Choose another file'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _importCount == 0 ? null : () => setState(() => _step = 2),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Continue'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmStep(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summary = _summary;
    final outcome = _outcome;

    Widget line(IconData icon, Color color, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
            ],
          ),
        );

    final Widget content;
    if (outcome == null) {
      final newCount = summary.importable - summary.existing;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Ready to import', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          line(Icons.add_circle_outline, const Color(0xFF2E7D32),
              '${formatCount(newCount)} new articles will be added as Available, dated today'),
          if (summary.existing > 0)
            line(
              _updateExisting ? Icons.sync : Icons.skip_next_outlined,
              scheme.primary,
              _updateExisting
                  ? '${formatCount(summary.existing)} existing articles will be updated'
                  : '${formatCount(summary.existing)} existing articles will be skipped',
            ),
          if (summary.warnings > 0)
            line(Icons.warning_amber_outlined, const Color(0xFF9A6700),
                '${formatCount(summary.warnings)} rows with warnings are included'),
          if (summary.errors > 0)
            line(Icons.error_outline, const Color(0xFFC62828),
                '${formatCount(summary.errors)} rows with errors will be left out'),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: () => setState(() => _step = 1),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to preview'),
              ),
              FilledButton.icon(
                onPressed: _runImport,
                icon: const Icon(Icons.check, size: 18),
                label: Text('Import ${formatCount(_importCount)} articles'),
              ),
            ],
          ),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 32),
              const SizedBox(width: 10),
              Text('Import complete', style: theme.textTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 12),
          line(Icons.add_circle_outline, const Color(0xFF2E7D32),
              '${formatCount(outcome.added)} articles added'),
          line(Icons.sync, scheme.primary, '${formatCount(outcome.updated)} articles updated'),
          line(Icons.skip_next_outlined, scheme.onSurfaceVariant,
              '${formatCount(outcome.skipped + _errorsLeftOut)} rows skipped'
              '${_errorsLeftOut > 0 ? ' (${formatCount(_errorsLeftOut)} with errors)' : ''}'),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.icon(
                onPressed: () => context.read<AppStore>().showTodayInStock(),
                icon: const Icon(Icons.inventory_2_outlined, size: 18),
                label: const Text('View in Stock'),
              ),
              OutlinedButton(onPressed: _reset, child: const Text('Import another file')),
            ],
          ),
        ],
      );
    }

    return Center(
      child: Container(
        width: 620,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: content,
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});
  final int step;

  static const List<String> _titles = <String>[
    'Choose file',
    'Preview and validate',
    'Confirm',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: <Widget>[
          for (var i = 0; i < _titles.length; i++) ...<Widget>[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: i <= step ? scheme.primary : scheme.outlineVariant,
                ),
              ),
            CircleAvatar(
              radius: 14,
              backgroundColor: i <= step ? scheme.primary : scheme.surfaceContainerHighest,
              foregroundColor: i <= step ? scheme.onPrimary : scheme.onSurfaceVariant,
              child: i < step
                  ? const Icon(Icons.check, size: 16)
                  : Text('${i + 1}', style: const TextStyle(fontSize: 13)),
            ),
            const SizedBox(width: 8),
            Text(
              _titles[i],
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: i == step ? FontWeight.w700 : FontWeight.w500,
                color: i <= step ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Read-only preview of the parsed file with tinted error and warning rows.
class _PreviewTable extends StatefulWidget {
  const _PreviewTable({required this.rows});
  final List<ImportRow> rows;

  @override
  State<_PreviewTable> createState() => _PreviewTableState();
}

class _PreviewTableState extends State<_PreviewTable> {
  final ScrollController _horizontal = ScrollController();

  static const double _rowNoWidth = 60;
  static const double _statusWidth = 96;
  static const double _issuesWidth = 420;

  static double _fieldWidth(ImportField f) {
    switch (f.key) {
      case 'description':
        return 230;
      case 'supplier':
        return 190;
      case 'articleCode':
      case 'barcode':
        return 140;
    }
    return f.numeric ? 125 : 115;
  }

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  Widget _cell(String text, double width, {bool right = false, TextStyle? style}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = _rowNoWidth +
        _statusWidth +
        _issuesWidth +
        importFields.fold<double>(0, (sum, f) => sum + _fieldWidth(f));
    const headerStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
    const cellStyle = TextStyle(fontSize: 13);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final width = total > constraints.maxWidth ? total : constraints.maxWidth;
        return Scrollbar(
          controller: _horizontal,
          thumbVisibility: true,
          notificationPredicate: (ScrollNotification n) => n.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Column(
                children: <Widget>[
                  Container(
                    height: 38,
                    color: scheme.surfaceContainerHigh,
                    child: Row(
                      children: <Widget>[
                        _cell('Row', _rowNoWidth, style: headerStyle),
                        _cell('Result', _statusWidth, style: headerStyle),
                        _cell('Issues', _issuesWidth, style: headerStyle),
                        for (final f in importFields)
                          _cell(f.header, _fieldWidth(f), right: f.numeric, style: headerStyle),
                      ],
                    ),
                  ),
                  Expanded(
                    child: widget.rows.isEmpty
                        ? const Center(child: Text('No rows to show for this filter'))
                        : ListView.builder(
                            itemExtent: 34,
                            itemCount: widget.rows.length,
                            itemBuilder: (BuildContext context, int index) {
                              final row = widget.rows[index];
                              final Color? tint;
                              final Color accent;
                              final String label;
                              switch (row.state) {
                                case ImportRowState.error:
                                  tint = const Color(0xFFFDE7E7);
                                  accent = const Color(0xFFC62828);
                                  label = 'Error';
                                case ImportRowState.warning:
                                  tint = const Color(0xFFFFF6D6);
                                  accent = const Color(0xFF9A6700);
                                  label = 'Warning';
                                case ImportRowState.ready:
                                  tint = null;
                                  accent = const Color(0xFF2E7D32);
                                  label = row.exists ? 'Exists' : 'Ready';
                              }
                              return Container(
                                decoration: BoxDecoration(
                                  color: tint,
                                  border: Border(
                                    bottom: BorderSide(color: scheme.outlineVariant),
                                  ),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    _cell(
                                      '${row.raw.rowNumber}',
                                      _rowNoWidth,
                                      style: cellStyle.copyWith(color: scheme.onSurfaceVariant),
                                    ),
                                    _cell(
                                      label,
                                      _statusWidth,
                                      style: cellStyle.copyWith(
                                        color: row.exists && row.state == ImportRowState.ready
                                            ? scheme.primary
                                            : accent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    _cell(
                                      row.issues,
                                      _issuesWidth,
                                      style: cellStyle.copyWith(color: accent),
                                    ),
                                    for (final f in importFields)
                                      _cell(
                                        row.raw[f.key],
                                        _fieldWidth(f),
                                        right: f.numeric,
                                        style: cellStyle,
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
