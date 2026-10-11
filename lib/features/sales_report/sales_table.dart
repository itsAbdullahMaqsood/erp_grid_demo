import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../models/sale.dart';
import '../../shared/excel_export.dart';
import '../../shared/formatters.dart';
import '../../shared/grid_columns.dart';

const Color negativeColor = Color(0xFFC62828);

Color? _profitColor(Sale s) => s.profit < 0 ? negativeColor : null;

/// One decimal, so the on-screen value, the filter list and Excel all agree.
double roundPercent(double percent) => (percent * 10).round() / 10;

/// Columns of the Sales Report table, in their default order.
final List<ColumnDef<Sale>> salesColumns = <ColumnDef<Sale>>[
  ColumnDef<Sale>(
    name: 'invoiceNo',
    label: 'Invoice No',
    kind: CellKind.text,
    width: 165,
    value: (s) => s.invoiceNo,
  ),
  ColumnDef<Sale>(
    name: 'date',
    label: 'Date',
    kind: CellKind.date,
    width: 140,
    value: (s) => s.date,
  ),
  ColumnDef<Sale>(
    name: 'articleCode',
    label: 'Article Code',
    kind: CellKind.text,
    width: 170,
    value: (s) => s.articleCode,
  ),
  ColumnDef<Sale>(
    name: 'category',
    label: 'Category',
    kind: CellKind.text,
    width: 140,
    value: (s) => s.category.label,
  ),
  ColumnDef<Sale>(
    name: 'customer',
    label: 'Customer',
    kind: CellKind.text,
    width: 175,
    value: (s) => s.customerName,
  ),
  ColumnDef<Sale>(
    name: 'salesman',
    label: 'Salesman',
    kind: CellKind.text,
    width: 160,
    value: (s) => s.salesman,
  ),
  ColumnDef<Sale>(
    name: 'branch',
    label: 'Branch',
    kind: CellKind.text,
    width: 140,
    value: (s) => s.branch.label,
  ),
  ColumnDef<Sale>(
    name: 'costPrice',
    label: 'Cost Price',
    kind: CellKind.integer,
    width: 155,
    value: (s) => s.costPrice,
  ),
  ColumnDef<Sale>(
    name: 'salePrice',
    label: 'Sale Price',
    kind: CellKind.integer,
    width: 155,
    value: (s) => s.salePrice,
  ),
  ColumnDef<Sale>(
    name: 'discount',
    label: 'Discount',
    kind: CellKind.integer,
    width: 145,
    value: (s) => s.discount,
  ),
  ColumnDef<Sale>(
    name: 'profit',
    label: 'Profit',
    kind: CellKind.integer,
    width: 130,
    value: (s) => s.profit,
    color: _profitColor,
  ),
  ColumnDef<Sale>(
    name: 'profitPercent',
    label: 'Profit %',
    kind: CellKind.percent,
    width: 140,
    value: (s) => roundPercent(s.profitPercent),
    color: _profitColor,
  ),
  ColumnDef<Sale>(
    name: 'paymentMethod',
    label: 'Payment Method',
    kind: CellKind.text,
    width: 190,
    value: (s) => s.paymentMethod.label,
  ),
];

/// Grid source for the Sales Report screen.
class SalesDataSource extends ItemDataSource<Sale> {
  SalesDataSource() : super(GridLayout<Sale>(salesColumns));
}

class SalesTotals {
  SalesTotals(List<Sale> items)
      : count = items.length,
        cost = items.fold(0, (sum, s) => sum + s.costPrice),
        sale = items.fold(0, (sum, s) => sum + s.salePrice),
        discount = items.fold(0, (sum, s) => sum + s.discount),
        profit = items.fold(0, (sum, s) => sum + s.profit),
        avgProfitPercent = items.isEmpty
            ? 0
            : items.fold<double>(0, (sum, s) => sum + roundPercent(s.profitPercent)) /
                items.length;

  final int count;
  final int cost;
  final int sale;
  final int discount;
  final int profit;

  /// Plain average of the Profit % column, same as AVERAGE() in Excel.
  final double avgProfitPercent;

  Object? forColumn(String name) {
    switch (name) {
      case 'costPrice':
        return cost;
      case 'salePrice':
        return sale;
      case 'discount':
        return discount;
      case 'profit':
        return profit;
      case 'profitPercent':
        return avgProfitPercent;
    }
    return null;
  }
}

class SalesGroup {
  SalesGroup(this.name, this.sales) : totals = SalesTotals(sales);
  final String name;
  final List<Sale> sales;
  final SalesTotals totals;
}

/// Groups sales for the "Group by" view. Sales keep their incoming order
/// inside each group.
List<SalesGroup> groupSales(List<Sale> sales, SalesGroupBy groupBy) {
  final byKey = <Comparable<Object>, List<Sale>>{};
  for (final s in sales) {
    final Comparable<Object> key;
    switch (groupBy) {
      case SalesGroupBy.salesman:
        key = s.salesman;
      case SalesGroupBy.category:
        key = s.category.index;
      case SalesGroupBy.day:
        key = s.date;
      case SalesGroupBy.none:
        key = '';
    }
    byKey.putIfAbsent(key, () => <Sale>[]).add(s);
  }
  final keys = byKey.keys.toList()..sort((a, b) => a.compareTo(b));
  // Newest day first.
  final ordered = groupBy == SalesGroupBy.day ? keys.reversed : keys;
  return <SalesGroup>[
    for (final key in ordered)
      SalesGroup(
        switch (groupBy) {
          SalesGroupBy.category => ItemCategory.values[key as int].label,
          SalesGroupBy.day => formatDate(key as DateTime),
          _ => key.toString(),
        },
        byKey[key]!,
      ),
  ];
}

ExportSheet buildSalesDetailSheet(
  List<ColumnDef<Sale>> columns,
  List<Sale> items, {
  String name = 'Sales',
}) {
  final totals = SalesTotals(items);
  final totalsRow = <Object?>[for (final c in columns) totals.forColumn(c.name)];
  final labelIndex = totalsRow.indexWhere((v) => v == null);
  if (labelIndex >= 0) {
    totalsRow[labelIndex] = 'Totals (${items.length} sales)';
  }
  return ExportSheet(
    name: name,
    columns: <ExportColumn>[for (final c in columns) c.exportColumn],
    rows: <List<Object?>>[
      for (final s in items) <Object?>[for (final c in columns) c.value(s)],
    ],
    totals: totalsRow,
  );
}

ExportSheet buildSalesSummarySheet(
  List<SalesGroup> groups,
  SalesGroupBy groupBy,
  SalesTotals overall,
) {
  return ExportSheet(
    name: 'Summary by ${groupBy.label}',
    columns: <ExportColumn>[
      ExportColumn(groupBy.label, CellKind.text, width: 26),
      const ExportColumn('Number of Sales', CellKind.integer, width: 18),
      const ExportColumn('Total Sale Price', CellKind.integer, width: 20),
      const ExportColumn('Total Profit', CellKind.integer, width: 18),
      const ExportColumn('Average Profit %', CellKind.percent, width: 18),
    ],
    rows: <List<Object?>>[
      for (final g in groups)
        <Object?>[
          g.name,
          g.totals.count,
          g.totals.sale,
          g.totals.profit,
          g.totals.avgProfitPercent,
        ],
    ],
    totals: <Object?>[
      'Totals',
      overall.count,
      overall.sale,
      overall.profit,
      overall.avgProfitPercent,
    ],
  );
}
