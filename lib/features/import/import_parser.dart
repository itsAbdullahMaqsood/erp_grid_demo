import 'dart:typed_data';

import 'package:excel/excel.dart';

/// One column of the import template.
class ImportField {
  const ImportField(this.key, this.header, {this.numeric = false});
  final String key;
  final String header;
  final bool numeric;
}

/// Template columns, in template order.
const List<ImportField> importFields = <ImportField>[
  ImportField('articleCode', 'Article Code'),
  ImportField('barcode', 'Barcode'),
  ImportField('category', 'Category'),
  ImportField('subCategory', 'Sub Category'),
  ImportField('description', 'Description'),
  ImportField('purity', 'Purity'),
  ImportField('grossWeight', 'Gross Weight (g)', numeric: true),
  ImportField('stoneWeight', 'Stone Weight (g)', numeric: true),
  ImportField('makingCharges', 'Making Charges', numeric: true),
  ImportField('stoneCharges', 'Stone Charges', numeric: true),
  ImportField('costPrice', 'Cost Price', numeric: true),
  ImportField('tagPrice', 'Tag Price', numeric: true),
  ImportField('supplier', 'Supplier'),
  ImportField('branch', 'Branch'),
];

/// Columns a file must contain to be accepted at all.
const List<String> requiredImportKeys = <String>[
  'articleCode',
  'category',
  'grossWeight',
  'costPrice',
  'tagPrice',
];

/// A row exactly as read from the file: one piece of text per template column.
class RawImportRow {
  RawImportRow(this.rowNumber, this.cells);

  /// Row number in the Excel sheet (the header is row 1).
  final int rowNumber;
  final Map<String, String> cells;

  String operator [](String key) => cells[key] ?? '';
}

class ParsedFile {
  ParsedFile({required this.rows, this.missingHeaders = const <String>[], this.error});
  final List<RawImportRow> rows;
  final List<String> missingHeaders;
  final String? error;

  bool get ok => error == null && missingHeaders.isEmpty;
}

/// Lower case, trimmed, single spaces: " Article   CODE " -> "article code".
String normalizeHeader(String text) =>
    text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String _cellText(Data? cell) {
  final value = cell?.value;
  if (value == null) return '';
  if (value is DoubleCellValue) {
    final d = value.value;
    return d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toString();
  }
  if (value is DateCellValue) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
  return value.toString().trim();
}

/// Reads the first sheet of an .xlsx file. Headers are matched without regard
/// to case or extra spaces, unknown columns are ignored, blank rows skipped.
ParsedFile parseImportFile(Uint8List bytes) {
  final Excel workbook;
  try {
    workbook = Excel.decodeBytes(bytes);
  } catch (_) {
    return ParsedFile(
      rows: <RawImportRow>[],
      error: 'This file could not be read. Please choose an Excel .xlsx file.',
    );
  }
  if (workbook.tables.isEmpty) {
    return ParsedFile(rows: <RawImportRow>[], error: 'The file has no sheets.');
  }
  final sheet = workbook.tables.values.first;
  final table = sheet.rows;
  if (table.isEmpty) {
    return ParsedFile(rows: <RawImportRow>[], error: 'The first sheet is empty.');
  }

  final byHeader = <String, ImportField>{
    for (final f in importFields) normalizeHeader(f.header): f,
  };
  final columnOf = <String, int>{};
  final headerRow = table.first;
  for (var c = 0; c < headerRow.length; c++) {
    final field = byHeader[normalizeHeader(_cellText(headerRow[c]))];
    if (field != null) columnOf.putIfAbsent(field.key, () => c);
  }

  final missing = <String>[
    for (final f in importFields)
      if (requiredImportKeys.contains(f.key) && !columnOf.containsKey(f.key)) f.header,
  ];
  if (missing.isNotEmpty) {
    return ParsedFile(rows: <RawImportRow>[], missingHeaders: missing);
  }

  final rows = <RawImportRow>[];
  for (var r = 1; r < table.length; r++) {
    final cells = <String, String>{};
    for (final entry in columnOf.entries) {
      final text = entry.value < table[r].length ? _cellText(table[r][entry.value]) : '';
      cells[entry.key] = text;
    }
    if (cells.values.every((v) => v.isEmpty)) continue;
    rows.add(RawImportRow(r + 1, cells));
  }
  if (rows.isEmpty) {
    return ParsedFile(rows: rows, error: 'The file has a header row but no data rows.');
  }
  return ParsedFile(rows: rows);
}
