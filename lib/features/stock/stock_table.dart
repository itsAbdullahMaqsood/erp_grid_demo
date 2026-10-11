import '../../models/article.dart';
import '../../shared/excel_export.dart';
import '../../shared/grid_columns.dart';
import '../../shared/widgets/status_pill.dart';

/// Columns of the Stock table, in their default order.
final List<ColumnDef<Article>> stockColumns = <ColumnDef<Article>>[
  ColumnDef<Article>(
    name: 'articleCode',
    label: 'Article Code',
    kind: CellKind.text,
    width: 170,
    value: (a) => a.articleCode,
  ),
  ColumnDef<Article>(
    name: 'barcode',
    label: 'Barcode',
    kind: CellKind.text,
    width: 165,
    value: (a) => a.barcode,
  ),
  ColumnDef<Article>(
    name: 'category',
    label: 'Category',
    kind: CellKind.text,
    width: 140,
    value: (a) => a.category.label,
  ),
  ColumnDef<Article>(
    name: 'subCategory',
    label: 'Sub Category',
    kind: CellKind.text,
    width: 165,
    value: (a) => a.subCategory,
  ),
  ColumnDef<Article>(
    name: 'description',
    label: 'Description',
    kind: CellKind.text,
    width: 250,
    value: (a) => a.description,
  ),
  ColumnDef<Article>(
    name: 'purity',
    label: 'Purity',
    kind: CellKind.text,
    width: 125,
    value: (a) => a.purity,
  ),
  ColumnDef<Article>(
    name: 'grossWeight',
    label: 'Gross Wt (g)',
    kind: CellKind.weight,
    width: 170,
    value: (a) => a.grossWeightMg / 1000,
  ),
  ColumnDef<Article>(
    name: 'stoneWeight',
    label: 'Stone Wt (g)',
    kind: CellKind.weight,
    width: 170,
    value: (a) => a.stoneWeightMg / 1000,
  ),
  ColumnDef<Article>(
    name: 'netWeight',
    label: 'Net Wt (g)',
    kind: CellKind.weight,
    width: 160,
    value: (a) => a.netWeightMg / 1000,
  ),
  ColumnDef<Article>(
    name: 'makingCharges',
    label: 'Making',
    kind: CellKind.integer,
    width: 140,
    value: (a) => a.makingCharges,
  ),
  ColumnDef<Article>(
    name: 'stoneCharges',
    label: 'Stone Charges',
    kind: CellKind.integer,
    width: 175,
    value: (a) => a.stoneCharges,
  ),
  ColumnDef<Article>(
    name: 'costPrice',
    label: 'Cost Price',
    kind: CellKind.integer,
    width: 155,
    value: (a) => a.costPrice,
  ),
  ColumnDef<Article>(
    name: 'tagPrice',
    label: 'Tag Price',
    kind: CellKind.integer,
    width: 150,
    value: (a) => a.tagPrice,
  ),
  ColumnDef<Article>(
    name: 'status',
    label: 'Status',
    kind: CellKind.text,
    width: 185,
    value: (a) => a.status.label,
    builder: (a) => StatusPill(a.status),
  ),
  ColumnDef<Article>(
    name: 'supplier',
    label: 'Supplier',
    kind: CellKind.text,
    width: 215,
    value: (a) => a.supplier,
  ),
  ColumnDef<Article>(
    name: 'branch',
    label: 'Branch',
    kind: CellKind.text,
    width: 140,
    value: (a) => a.branch.label,
  ),
  ColumnDef<Article>(
    name: 'dateAdded',
    label: 'Date Added',
    kind: CellKind.date,
    width: 160,
    value: (a) => a.dateAdded,
  ),
];

/// Grid source for the Stock screen.
class StockDataSource extends ItemDataSource<Article> {
  StockDataSource() : super(GridLayout<Article>(stockColumns));
}

class StockTotals {
  StockTotals(List<Article> items)
      : count = items.length,
        grossMg = items.fold(0, (sum, a) => sum + a.grossWeightMg),
        netMg = items.fold(0, (sum, a) => sum + a.netWeightMg),
        stoneMg = items.fold(0, (sum, a) => sum + a.stoneWeightMg),
        making = items.fold(0, (sum, a) => sum + a.makingCharges),
        stoneCharges = items.fold(0, (sum, a) => sum + a.stoneCharges),
        cost = items.fold(0, (sum, a) => sum + a.costPrice),
        tag = items.fold(0, (sum, a) => sum + a.tagPrice);

  final int count;
  final int grossMg;
  final int netMg;
  final int stoneMg;
  final int making;
  final int stoneCharges;
  final int cost;
  final int tag;

  /// Value for the totals row of the export, per column name.
  Object? forColumn(String name) {
    switch (name) {
      case 'grossWeight':
        return grossMg / 1000;
      case 'stoneWeight':
        return stoneMg / 1000;
      case 'netWeight':
        return netMg / 1000;
      case 'makingCharges':
        return making;
      case 'stoneCharges':
        return stoneCharges;
      case 'costPrice':
        return cost;
      case 'tagPrice':
        return tag;
    }
    return null;
  }
}

/// Sheet for the Stock export: visible columns, rows as shown, totals row.
ExportSheet buildStockSheet(List<ColumnDef<Article>> columns, List<Article> items) {
  final totals = StockTotals(items);
  final totalsRow = <Object?>[for (final c in columns) totals.forColumn(c.name)];
  final labelIndex = totalsRow.indexWhere((v) => v == null);
  if (labelIndex >= 0) {
    totalsRow[labelIndex] = 'Totals (${items.length} articles)';
  }
  return ExportSheet(
    name: 'Stock',
    columns: <ExportColumn>[for (final c in columns) c.exportColumn],
    rows: <List<Object?>>[
      for (final a in items) <Object?>[for (final c in columns) c.value(a)],
    ],
    totals: totalsRow,
  );
}
