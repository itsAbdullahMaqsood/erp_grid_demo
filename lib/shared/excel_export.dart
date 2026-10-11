import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import 'formatters.dart';

/// How a column is written to Excel.
enum CellKind {
  /// Plain text cell.
  text,

  /// Whole number (money, counts). Written as a numeric cell.
  integer,

  /// Weight in grams with 3 decimals. Written as a numeric cell.
  weight,

  /// Percentage. The value passed in is e.g. 18.4 and is written as 0.184.
  percent,

  /// Date cell.
  date,
}

class ExportColumn {
  const ExportColumn(this.header, this.kind, {this.width = 14});
  final String header;
  final CellKind kind;

  /// Column width in Excel character units.
  final double width;
}

class ExportSheet {
  const ExportSheet({
    required this.name,
    required this.columns,
    required this.rows,
    this.totals,
  });

  final String name;
  final List<ExportColumn> columns;

  /// One list per row, in the same order as [columns]. Values are String,
  /// num or DateTime. Null leaves the cell empty.
  final List<List<Object?>> rows;

  /// Optional bold totals row written under the data.
  final List<Object?>? totals;
}

const String xlsxMimeType =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// Builds an .xlsx file: bold frozen header, typed cells, optional totals row.
Uint8List buildWorkbook(List<ExportSheet> sheets) {
  final workbook = xlsio.Workbook(sheets.length);
  for (var s = 0; s < sheets.length; s++) {
    final data = sheets[s];
    final sheet = workbook.worksheets[s]..name = data.name;

    for (var c = 0; c < data.columns.length; c++) {
      final column = data.columns[c];
      final cell = sheet.getRangeByIndex(1, c + 1)
        ..setText(column.header)
        ..columnWidth = column.width;
      cell.cellStyle
        ..bold = true
        ..backColor = '#E8EFE9'
        ..hAlign = column.kind == CellKind.text || column.kind == CellKind.date
            ? xlsio.HAlignType.left
            : xlsio.HAlignType.right;
    }

    for (var r = 0; r < data.rows.length; r++) {
      final row = data.rows[r];
      for (var c = 0; c < data.columns.length; c++) {
        _writeCell(sheet.getRangeByIndex(r + 2, c + 1), data.columns[c].kind, row[c]);
      }
    }

    final totals = data.totals;
    if (totals != null) {
      final rowIndex = data.rows.length + 2;
      for (var c = 0; c < data.columns.length; c++) {
        final cell = sheet.getRangeByIndex(rowIndex, c + 1);
        final value = totals[c];
        _writeCell(cell, data.columns[c].kind, value);
        cell.cellStyle
          ..bold = true
          ..backColor = '#F4F4F4';
      }
    }

    // Keep the header row visible while scrolling.
    sheet.getRangeByIndex(2, 1).freezePanes();
  }

  final bytes = workbook.saveAsStream();
  workbook.dispose();
  return Uint8List.fromList(bytes);
}

void _writeCell(xlsio.Range cell, CellKind kind, Object? value) {
  if (value == null) return;
  // Text always stays text, whatever the column kind: a "Totals" label, or a
  // value that could not be read as a number.
  if (value is String) {
    cell.setText(value);
    return;
  }
  switch (kind) {
    case CellKind.text:
      cell.setText(value.toString());
    case CellKind.integer:
      cell.setNumber((value as num).toDouble());
      cell.numberFormat = '#,##0';
    case CellKind.weight:
      cell.setNumber((value as num).toDouble());
      cell.numberFormat = '0.000';
    case CellKind.percent:
      cell.setNumber((value as num).toDouble() / 100);
      cell.numberFormat = '0.0%';
    case CellKind.date:
      cell.setDateTime(value as DateTime);
      cell.numberFormat = 'dd-mmm-yyyy';
  }
}

/// Saves [bytes] as [fileName]. Desktop shows a save dialog, the browser
/// downloads the file. Returns false if the user cancelled the dialog.
Future<bool> saveXlsx(String fileName, Uint8List bytes) async {
  final uri = await FilePicker.saveFile(
    fileName: fileName,
    bytes: bytes,
    mimeType: xlsxMimeType,
    dialogTitle: 'Save Excel file',
    type: FileType.custom,
    allowedExtensions: const <String>['xlsx'],
  );
  return kIsWeb || uri != null;
}

/// The one export entry point used by every screen: builds the workbook,
/// saves it and confirms with a snackbar.
Future<void> exportToExcel(
  BuildContext context, {
  required String filePrefix,
  required List<ExportSheet> sheets,
  required int rowCount,
  bool datedName = true,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final fileName = datedName
      ? '${filePrefix}_${formatFileDate(DateTime.now())}.xlsx'
      : '$filePrefix.xlsx';
  try {
    final saved = await saveXlsx(fileName, buildWorkbook(sheets));
    if (!saved) return;
    messenger.showSnackBar(
      SnackBar(content: Text('Exported ${formatCount(rowCount)} rows to $fileName')),
    );
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text('Export failed: $error')));
  }
}
