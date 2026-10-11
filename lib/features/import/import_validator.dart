import '../../data/seed_data.dart';
import '../../models/article.dart';
import '../../models/enums.dart';
import 'import_parser.dart';

enum ImportRowState { ready, warning, error }

/// A file row after validation.
class ImportRow {
  ImportRow(this.raw);

  final RawImportRow raw;
  final List<String> errors = <String>[];
  final List<String> warnings = <String>[];

  /// The article code is already in stock.
  bool exists = false;

  ItemCategory? category;
  int grossMg = 0;
  int stoneMg = 0;
  int making = 0;
  int stoneCharges = 0;
  int cost = 0;
  int tag = 0;

  ImportRowState get state => errors.isNotEmpty
      ? ImportRowState.error
      : warnings.isNotEmpty
          ? ImportRowState.warning
          : ImportRowState.ready;

  bool get importable => errors.isEmpty;

  /// Plain-language list shown in the Issues column.
  String get issues => <String>[
        ...errors,
        ...warnings,
        if (exists) 'Already exists',
      ].join('; ');

  Article toArticle(DateTime today, int serial) {
    final code = raw['articleCode'].trim();
    final purity = raw['purity'].trim();
    return Article(
      articleCode: code,
      barcode: raw['barcode'].isEmpty ? barcodeFor(serial) : raw['barcode'],
      category: category!,
      subCategory: raw['subCategory'].isEmpty ? 'Ring' : raw['subCategory'],
      description: raw['description'],
      purity: purity,
      grossWeightMg: grossMg,
      stoneWeightMg: stoneMg,
      makingCharges: making,
      stoneCharges: stoneCharges,
      costPrice: cost,
      tagPrice: tag,
      status: ArticleStatus.available,
      supplier: raw['supplier'],
      branch: Branch.tryParse(raw['branch']) ?? Branch.main,
      dateAdded: today,
    );
  }
}

class ImportSummary {
  ImportSummary(List<ImportRow> rows)
      : ready = rows.where((r) => r.state == ImportRowState.ready).length,
        warnings = rows.where((r) => r.state == ImportRowState.warning).length,
        errors = rows.where((r) => r.state == ImportRowState.error).length,
        existing = rows.where((r) => r.importable && r.exists).length;

  final int ready;
  final int warnings;
  final int errors;

  /// Importable rows whose article code is already in stock.
  final int existing;

  int get importable => ready + warnings;
}

double? _number(String text) {
  final cleaned = text.replaceAll(',', '').trim();
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

/// Checks every row against the import rules.
List<ImportRow> validateImportRows(List<RawImportRow> rawRows, Set<String> existingCodes) {
  final existing = <String>{for (final c in existingCodes) c.toLowerCase()};
  final seen = <String>{};
  final result = <ImportRow>[];

  for (final raw in rawRows) {
    final row = ImportRow(raw);

    final code = raw['articleCode'].trim();
    if (code.isEmpty) {
      row.errors.add('Article Code is missing');
    } else if (!seen.add(code.toLowerCase())) {
      row.errors.add('Article Code is repeated in this file');
    } else if (existing.contains(code.toLowerCase())) {
      row.exists = true;
    }

    final categoryText = raw['category'];
    row.category = ItemCategory.tryParse(categoryText);
    if (categoryText.isEmpty) {
      row.errors.add('Category is missing');
    } else if (row.category == null) {
      row.errors.add('Category "$categoryText" is not Gold, Diamond, Silver or Platinum');
    }

    final gross = _number(raw['grossWeight']);
    if (raw['grossWeight'].isEmpty) {
      row.errors.add('Gross Weight is missing');
    } else if (gross == null) {
      row.errors.add('Gross Weight is not a number');
    } else if (gross <= 0) {
      row.errors.add('Gross Weight must be greater than 0');
    } else {
      row.grossMg = (gross * 1000).round();
    }

    final stone = _number(raw['stoneWeight']);
    if (raw['stoneWeight'].isNotEmpty && stone == null) {
      row.errors.add('Stone Weight is not a number');
    } else if (stone != null) {
      if (stone < 0) {
        row.errors.add('Stone Weight cannot be negative');
      } else {
        row.stoneMg = (stone * 1000).round();
        if (row.grossMg > 0 && row.stoneMg > row.grossMg) {
          row.errors.add('Stone Weight is more than Gross Weight');
        }
      }
    }

    int? money(String key, String label, {required bool required}) {
      final text = raw[key];
      final value = _number(text);
      if (text.isEmpty) {
        if (required) row.errors.add('$label is missing');
        return required ? null : 0;
      }
      if (value == null) {
        row.errors.add('$label is not a number');
        return null;
      }
      if (required && value <= 0) {
        row.errors.add('$label must be greater than 0');
        return null;
      }
      if (value < 0) {
        row.errors.add('$label cannot be negative');
        return null;
      }
      return value.round();
    }

    row.making = money('makingCharges', 'Making Charges', required: false) ?? 0;
    row.stoneCharges = money('stoneCharges', 'Stone Charges', required: false) ?? 0;
    final cost = money('costPrice', 'Cost Price', required: true);
    final tag = money('tagPrice', 'Tag Price', required: true);
    row.cost = cost ?? 0;
    row.tag = tag ?? 0;
    if (cost != null && tag != null && tag < cost) {
      row.warnings.add('Tag Price is lower than Cost Price');
    }

    result.add(row);
  }
  return result;
}
