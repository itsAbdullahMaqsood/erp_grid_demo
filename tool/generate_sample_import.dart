// Generates assets/sample_import.xlsx: 200 rows for the Import screen demo,
// including 8 rows with errors, 4 with warnings and 3 that already exist.
//
// Run from the project root:  dart run tool/generate_sample_import.dart
import 'dart:io';
import 'dart:math';

import 'package:erp_grid_demo/data/seed_data.dart';
import 'package:erp_grid_demo/models/article.dart';
import 'package:excel/excel.dart';

const List<String> _headers = <String>[
  'Article Code', 'Barcode', 'Category', 'Sub Category', 'Description', 'Purity',
  'Gross Weight (g)', 'Stone Weight (g)', 'Making Charges', 'Stone Charges',
  'Cost Price', 'Tag Price', 'Supplier', 'Branch',
];

List<Object?> _rowFor(Article a) => <Object?>[
      a.articleCode,
      a.barcode,
      a.category.label,
      a.subCategory,
      a.description,
      a.purity,
      a.grossWeightMg / 1000,
      a.stoneWeightMg / 1000,
      a.makingCharges,
      a.stoneCharges,
      a.costPrice,
      a.tagPrice,
      a.supplier,
      a.branch.label,
    ];

void main() {
  final seed = generateSeedData(today: DateTime(2026, 1, 1));
  final rnd = Random(7);

  // New articles: reuse believable seeded values under fresh codes.
  final rows = <List<Object?>>[];
  for (var i = 0; i < 200; i++) {
    final base = seed.articles[rnd.nextInt(seed.articles.length)];
    final serial = 601 + i;
    final row = _rowFor(base);
    row[0] = articleCodeFor(base.category, base.subCategory, base.purity, serial);
    row[1] = barcodeFor(serial);
    rows.add(row);
  }

  // 3 rows whose code is already in stock (with a new tag price).
  for (final i in <int>[20, 75, 140]) {
    final existing = seed.articles[i];
    rows[i] = _rowFor(existing)..[11] = existing.tagPrice + 2500;
  }

  // 8 rows with deliberate errors.
  rows[9][0] = null; // Article Code missing
  rows[27][0] = rows[26][0]; // Article Code repeated
  rows[44][2] = 'Gems'; // Category not allowed
  rows[63][6] = null; // Gross Weight missing
  rows[88][6] = 'abc'; // Gross Weight not a number
  rows[112][7] = (rows[112][6]! as double) + 1.5; // Stone heavier than gross
  rows[151][10] = null; // Cost Price missing
  rows[176][11] = 0; // Tag Price zero

  // 4 rows with a warning: tag price below cost.
  for (final i in <int>[15, 58, 99, 163]) {
    rows[i][11] = (rows[i][10]! as int) - 1500;
  }

  final excel = Excel.createExcel();
  final sheet = excel[excel.getDefaultSheet()!];
  sheet.appendRow(<CellValue?>[for (final h in _headers) TextCellValue(h)]);
  for (final row in rows) {
    sheet.appendRow(<CellValue?>[
      for (final v in row)
        v == null
            ? null
            : v is int
                ? IntCellValue(v)
                : v is double
                    ? DoubleCellValue(v)
                    : TextCellValue(v.toString()),
    ]);
  }

  final bytes = excel.encode()!;
  File('assets/sample_import.xlsx')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);
  stdout.writeln('Wrote assets/sample_import.xlsx (${rows.length} rows)');
}
