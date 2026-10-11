import 'dart:io';

import 'package:erp_grid_demo/data/app_store.dart';
import 'package:erp_grid_demo/data/seed_data.dart';
import 'package:erp_grid_demo/features/import/import_files.dart';
import 'package:erp_grid_demo/features/import/import_parser.dart';
import 'package:erp_grid_demo/features/import/import_validator.dart';
import 'package:erp_grid_demo/features/sales_report/sales_table.dart';
import 'package:erp_grid_demo/features/stock/stock_table.dart';
import 'package:erp_grid_demo/models/enums.dart';
import 'package:erp_grid_demo/shared/excel_export.dart';
import 'package:erp_grid_demo/shared/formatters.dart';
import 'package:excel/excel.dart' as ex;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatters', () {
    expect(formatMoney(142000), '142,000');
    expect(formatGrams(4850), '4.850');
    expect(formatGrams(1234005), '1,234.005');
    expect(formatPercent(18.37), '18.4%');
  });

  test('seed data is deterministic and consistent', () {
    final a = generateSeedData(today: DateTime(2026, 10, 11));
    final b = generateSeedData(today: DateTime(2026, 10, 11));
    expect(a.articles.length, 600);
    expect(a.sales.length, 250);
    expect(a.articles.map((x) => x.articleCode).toSet().length, 600);
    for (var i = 0; i < 600; i++) {
      expect(a.articles[i].articleCode, b.articles[i].articleCode);
      expect(a.articles[i].tagPrice, b.articles[i].tagPrice);
    }
    final byCode = {for (final x in a.articles) x.articleCode: x};
    for (final s in a.sales) {
      final art = byCode[s.articleCode]!;
      expect(art.status, ArticleStatus.sold);
      expect(s.costPrice, art.costPrice);
      expect(s.category, art.category);
      expect(art.dateAdded.isAfter(s.date), isFalse);
      expect(DateTime(2026, 10, 11).difference(s.date).inDays, inInclusiveRange(0, 89));
    }
    for (final x in a.articles) {
      expect(x.stoneWeightMg <= x.grossWeightMg, isTrue);
      final ratio = x.tagPrice / x.costPrice;
      expect(ratio, inInclusiveRange(1.11, 1.26), reason: x.articleCode);
    }
    final counts = <ItemCategory, int>{};
    for (final x in a.articles) {
      counts[x.category] = (counts[x.category] ?? 0) + 1;
    }
    // ignore: avoid_print
    print('categories: $counts, negative-profit sales: '
        '${a.sales.where((s) => s.profit < 0).length}, example: '
        '${a.articles.first.articleCode} ${a.articles.first.barcode} '
        'cost ${a.articles.first.costPrice} tag ${a.articles.first.tagPrice}');
  });

  test('sample import file: 188 ready, 4 warnings, 8 errors', () {
    final bytes = File('assets/sample_import.xlsx').readAsBytesSync();
    final parsed = parseImportFile(bytes);
    expect(parsed.ok, isTrue);
    expect(parsed.rows.length, 200);
    final store = AppStore();
    final rows = validateImportRows(
      parsed.rows,
      {for (final a in store.articles) a.articleCode},
    );
    final summary = ImportSummary(rows);
    for (final r in rows.where((r) => r.state != ImportRowState.ready || r.exists)) {
      // ignore: avoid_print
      print('row ${r.raw.rowNumber}: ${r.state.name} ${r.issues}');
    }
    expect(summary.ready, 188);
    expect(summary.warnings, 4);
    expect(summary.errors, 8);
    expect(summary.existing, 3);

    final incoming = [
      for (final r in rows)
        if (r.importable) r.toArticle(DateTime(2026, 10, 11), 1000),
    ];
    final outcome = store.importArticles(incoming, updateExisting: false);
    expect(outcome.added, 189);
    expect(outcome.skipped, 3);
    expect(store.articles.length, 789);

    // Error rows export can be read back and still fails validation.
    final errorBytes = buildWorkbook([buildErrorRowsSheet(rows)]);
    final reparsed = parseImportFile(errorBytes);
    expect(reparsed.rows.length, 8);
  });

  test('header matching ignores case, spaces and extra columns', () {
    final sheet = ExportSheet(
      name: 'x',
      columns: const [
        ExportColumn('  article   CODE ', CellKind.text),
        ExportColumn('Notes', CellKind.text),
        ExportColumn('CATEGORY', CellKind.text),
        ExportColumn('gross weight (g)', CellKind.weight),
        ExportColumn('Cost price', CellKind.integer),
        ExportColumn('TAG PRICE', CellKind.integer),
      ],
      rows: const [
        ['ZZ-1', 'ignored', 'gold', 4.85, 1000, 1200],
      ],
    );
    final parsed = parseImportFile(buildWorkbook([sheet]));
    expect(parsed.ok, isTrue);
    final rows = validateImportRows(parsed.rows, {});
    expect(rows.single.state, ImportRowState.ready);
    expect(rows.single.grossMg, 4850);
  });

  test('template parses clean', () {
    final parsed = parseImportFile(buildWorkbook([buildTemplateSheet()]));
    expect(parsed.rows.length, 3);
    final rows = validateImportRows(parsed.rows, {});
    expect(rows.every((r) => r.state == ImportRowState.ready), isTrue);
  });

  test('stock export writes typed cells and a totals row', () {
    final store = AppStore();
    final items = store.articles.take(25).toList();
    final bytes = buildWorkbook([buildStockSheet(stockColumns, items)]);
    final book = ex.Excel.decodeBytes(bytes);
    final rows = book.tables['Stock']!.rows;
    expect(rows.length, 27); // header + 25 + totals
    final header = [for (final c in rows.first) c?.value.toString()];
    expect(header.first, 'Article Code');
    final first = rows[1];
    expect(first[header.indexOf('Gross Wt (g)')]!.value, isA<ex.DoubleCellValue>());
    expect(first[header.indexOf('Cost Price')]!.value, isA<ex.IntCellValue>());
    expect(first[header.indexOf('Date Added')]!.value, isA<ex.DateCellValue>());
    final totals = StockTotals(items);
    final last = rows.last;
    expect((last[header.indexOf('Cost Price')]!.value as ex.IntCellValue).value, totals.cost);
    expect(
      (last[header.indexOf('Gross Wt (g)')]!.value as ex.DoubleCellValue).value,
      closeTo(totals.grossMg / 1000, 0.0005),
    );
  });

  test('grouped sales export has summary and details sheets', () {
    final store = AppStore();
    final items = store.filteredSales;
    expect(items.length, 250);
    final groups = groupSales(items, SalesGroupBy.salesman);
    expect(groups.length, 6);
    expect(groups.fold<int>(0, (s, g) => s + g.totals.count), 250);
    expect(groups.fold<int>(0, (s, g) => s + g.totals.sale), SalesTotals(items).sale);
    final bytes = buildWorkbook([
      buildSalesSummarySheet(groups, SalesGroupBy.salesman, SalesTotals(items)),
      buildSalesDetailSheet(salesColumns, items, name: 'Details'),
    ]);
    final book = ex.Excel.decodeBytes(bytes);
    expect(book.tables.keys.toList(), ['Summary by Salesman', 'Details']);
    expect(book.tables['Summary by Salesman']!.rows.length, 8);
    expect(book.tables['Details']!.rows.length, 252);
    expect(groupSales(items, SalesGroupBy.category).length, 4);
    expect(groupSales(items, SalesGroupBy.day).length, greaterThan(30));
  });

  test('store toolbar filters', () {
    final store = AppStore();
    expect(store.filteredArticles.length, 600);
    store.setStockCategory(ItemCategory.gold);
    expect(store.filteredArticles.length, 360);
    store.setStockSearch('ring');
    final n = store.filteredArticles.length;
    expect(n, inExclusiveRange(0, 360));
    store.toggleStockStatus(ArticleStatus.sold, false);
    expect(store.filteredArticles.length, lessThan(n));
    store.clearStockFilters();
    expect(store.filteredArticles.length, 600);
    store.setSalesPreset('Last 7 days');
    expect(store.filteredSales.length, inExclusiveRange(0, 250));
  });
}
