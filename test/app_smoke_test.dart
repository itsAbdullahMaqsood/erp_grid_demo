import 'package:erp_grid_demo/app.dart';
import 'package:erp_grid_demo/data/app_store.dart';
import 'package:erp_grid_demo/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

Future<AppStore> _pumpApp(WidgetTester tester, {Size size = const Size(1440, 900)}) async {
  // The test font draws every glyph as a full square, which is wider than any
  // real font and overflows the fixed-width page size dropdown inside
  // SfDataPager. That one is not ours to lay out, so it is ignored here.
  final previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final text = details.toString();
    if (text.contains('overflowed') && text.contains('sfdatapager.dart')) return;
    previous?.call(details);
  };
  addTearDown(() => FlutterError.onError = previous);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final store = AppStore();
  await tester.pumpWidget(
    ChangeNotifierProvider<AppStore>.value(value: store, child: const ErpDemoApp()),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  testWidgets('stock: filters, totals, details and edit', (tester) async {
    final store = await _pumpApp(tester);
    expect(find.text('Jewelry ERP Demo'), findsOneWidget);
    expect(find.text('Demo data'), findsOneWidget);
    expect(find.text('Showing 600 of 600 articles'), findsOneWidget);

    // Toolbar category chip.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Gold'));
    await tester.pumpAndSettle();
    expect(find.text('Showing 360 of 600 articles'), findsOneWidget);

    // Search on top of the chip.
    await tester.enterText(find.byType(TextField).first, 'ring');
    await tester.pumpAndSettle();
    final ringCount = store.filteredArticles.length;
    expect(find.text('Showing $ringCount of 600 articles'), findsOneWidget);

    // A grid column filter applies on top of the toolbar filters.
    final grid = tester.widget<SfDataGrid>(find.byType(SfDataGrid).first);
    grid.source.addFilter(
      'Gross Wt (g)',
      const FilterCondition(type: FilterType.lessThan, value: 5.0),
    );
    grid.onFilterChanged!(
      DataGridFilterChangeDetails(column: grid.columns.first, filterConditions: const []),
    );
    await tester.pumpAndSettle();
    final under5 = store.filteredArticles.where((a) => a.grossWeightMg < 5000).length;
    expect(under5, inExclusiveRange(0, ringCount));
    expect(find.text('Showing $under5 of 600 articles'), findsOneWidget);

    // Clear filters resets toolbar and column filters.
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Showing 600 of 600 articles'), findsOneWidget);

    // Row click opens the details panel.
    final first = store.articles.first;
    await tester.tap(find.text(first.articleCode));
    await tester.pumpAndSettle();
    expect(find.text('Article details'), findsOneWidget);

    // Edit dialog saves and the totals move.
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    final totalBefore = store.articles.fold<int>(0, (s, a) => s + a.tagPrice);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tag Price'),
      '${first.tagPrice + 1000}',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(store.articles.fold<int>(0, (s, a) => s + a.tagPrice), totalBefore + 1000);
    expect(find.text('Article details'), findsOneWidget);

    // Hide a column from the Columns menu.
    await tester.tap(find.text('Columns'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxMenuButton, 'Barcode'));
    await tester.pumpAndSettle();
    expect(find.text('Columns: 16 of 17'), findsOneWidget);
  });

  testWidgets('sales: presets, grouping and expand', (tester) async {
    final store = await _pumpApp(tester);
    await tester.tap(find.text('Sales Report'));
    await tester.pumpAndSettle();
    expect(find.text('Showing 250 of 250 sales'), findsOneWidget);
    expect(find.text('Number of Invoices'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Last 7 days'));
    await tester.pumpAndSettle();
    final week = store.filteredSales.length;
    expect(find.text('Showing $week of 250 sales'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Last 90 days'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<SalesGroupBy>),
        matching: find.text('Salesman'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Number of Sales'), findsOneWidget);
    expect(find.text('Ahmed Raza'), findsWidgets);

    await tester.tap(find.text('Ahmed Raza').last);
    await tester.pumpAndSettle();
    expect(find.text('Invoice No'), findsWidgets);
  });

  testWidgets('import: sample file through to stock', (tester) async {
    final store = await _pumpApp(tester);
    await tester.tap(find.text('Import from\nExcel'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Load sample file (200 rows)'));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('188 ready to import', findRichText: true), findsOneWidget);
    expect(find.text('Gross Weight is missing'), findsNothing); // off-screen row

    await tester.tap(find.text('Errors only'));
    await tester.pumpAndSettle();
    expect(find.text('Gross Weight is missing'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import 189 articles'));
    await tester.pumpAndSettle();
    expect(find.text('189 articles added'), findsOneWidget);
    expect(store.articles.length, 789);

    await tester.tap(find.text('View in Stock'));
    await tester.pumpAndSettle();
    expect(find.text('Showing 189 of 789 articles'), findsOneWidget);
  });

  testWidgets('narrow window scrolls instead of overflowing', (tester) async {
    await _pumpApp(tester, size: const Size(900, 700));
    expect(tester.takeException(), isNull);
  });
}
