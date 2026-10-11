import '../../shared/excel_export.dart';
import 'import_parser.dart';
import 'import_validator.dart';

List<ExportColumn> _templateColumns() => <ExportColumn>[
      for (final f in importFields)
        ExportColumn(
          f.header,
          f.key.endsWith('Weight')
              ? CellKind.weight
              : f.numeric
                  ? CellKind.integer
                  : CellKind.text,
          width: f.key == 'description' ? 34 : (f.key == 'supplier' ? 26 : 18),
        ),
    ];

/// Template workbook: the header row plus 3 example rows.
ExportSheet buildTemplateSheet() {
  return ExportSheet(
    name: 'Articles',
    columns: _templateColumns(),
    rows: const <List<Object?>>[
      <Object?>[
        'GR-22K-90001', '8901009000017', 'Gold', 'Ring', 'Ladies ring, floral design', '22K',
        4.85, 0.32, 12000, 8500, 142000, 168000, 'Hanif Jewellers', 'Main Branch',
      ],
      <Object?>[
        'DN-18K-90002', '8901009000024', 'Diamond', 'Necklace', 'Necklace, light party wear',
        '18K', 18.4, 1.25, 65000, 420000, 870500, 1040000, 'Rehman Diamond House', 'Branch 2',
      ],
      <Object?>[
        'SB-925-90003', '8901009000031', 'Silver', 'Bangle', 'Bangle pair, plain polish', '925',
        32.5, 0, 3500, 0, 14900, 17500, 'Qureshi Silver Works', 'Main Branch',
      ],
    ],
  );
}

/// The rows that failed validation, as they were in the file, plus an Issues
/// column, so they can be fixed in Excel and imported again.
ExportSheet buildErrorRowsSheet(List<ImportRow> rows) {
  final failed = rows.where((r) => r.state == ImportRowState.error).toList();
  return ExportSheet(
    name: 'Rows to fix',
    columns: <ExportColumn>[
      ..._templateColumns(),
      const ExportColumn('Issues', CellKind.text, width: 60),
    ],
    rows: <List<Object?>>[
      for (final r in failed)
        <Object?>[
          for (final f in importFields) _original(f, r.raw[f.key]),
          r.errors.join('; '),
        ],
    ],
  );
}

/// Numbers go back as numbers; anything else is kept as the text that was
/// typed, so nothing is lost.
Object? _original(ImportField field, String text) {
  if (text.isEmpty) return null;
  if (!field.numeric) return text;
  return double.tryParse(text.replaceAll(',', '')) ?? text;
}
