import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import 'excel_export.dart';
import 'formatters.dart';

/// Describes one table column: how to read it from a record, how to show it
/// in the grid and how to write it to Excel.
class ColumnDef<T> {
  const ColumnDef({
    required this.name,
    required this.label,
    required this.kind,
    required this.value,
    this.width = 120,
    this.color,
    this.builder,
  });

  /// Internal key, used to look up totals.
  final String name;

  /// Header text. Also the grid's column name, because the grid shows that
  /// name in its filter popup ("Clear Filter From ...").
  final String label;
  final CellKind kind;
  final double width;

  /// Value used for sorting, filtering and export.
  /// text -> String, integer -> int, weight -> grams as double,
  /// percent -> double, date -> DateTime.
  final Object? Function(T item) value;

  /// Optional text colour, e.g. red for negative profit.
  final Color? Function(T item)? color;

  /// Optional custom cell, e.g. the status pill.
  final Widget Function(T item)? builder;

  bool get isNumeric =>
      kind == CellKind.integer || kind == CellKind.weight || kind == CellKind.percent;

  String display(Object? v) {
    if (v == null) return '';
    switch (kind) {
      case CellKind.text:
        return v.toString();
      case CellKind.integer:
        return formatMoney(v as int);
      case CellKind.weight:
        return formatGrams(((v as double) * 1000).round());
      case CellKind.percent:
        return formatPercent(v as double);
      case CellKind.date:
        return formatDate(v as DateTime);
    }
  }

  ExportColumn get exportColumn => ExportColumn(label, kind, width: (width / 7).roundToDouble());
}

/// Which columns are shown, in what order and how wide. Changed by the
/// Columns menu, by dragging headers and by resizing.
class GridLayout<T> extends ChangeNotifier {
  GridLayout(this.all) : _order = <ColumnDef<T>>[...all];

  final List<ColumnDef<T>> all;
  final List<ColumnDef<T>> _order;
  final Set<String> _hidden = <String>{};
  final Map<String, double> _widths = <String, double>{};

  List<ColumnDef<T>> get visible =>
      _order.where((c) => !_hidden.contains(c.name)).toList();

  bool isVisible(ColumnDef<T> column) => !_hidden.contains(column.name);

  double widthOf(ColumnDef<T> column) => _widths[column.label] ?? column.width;

  void setVisible(ColumnDef<T> column, bool visible) {
    if (visible) {
      _hidden.remove(column.name);
    } else {
      _hidden.add(column.name);
    }
    notifyListeners();
  }

  void setWidth(String label, double width) {
    _widths[label] = width;
    notifyListeners();
  }

  /// Moves a column. Indexes refer to the visible column list: the column is
  /// taken out at [from] and put back at [to].
  void move(int from, int to) {
    final shown = visible;
    if (from < 0 || from >= shown.length || to < 0 || to >= shown.length) return;
    final moving = shown.removeAt(from);
    _order.remove(moving);
    if (to >= shown.length) {
      _order.insert(_order.indexOf(shown.last) + 1, moving);
    } else {
      _order.insert(_order.indexOf(shown[to]), moving);
    }
    notifyListeners();
  }
}

/// Grid data source shared by the table screens. Each screen subclasses it
/// with its own column list.
abstract class ItemDataSource<T> extends DataGridSource {
  ItemDataSource(this.layout);

  final GridLayout<T> layout;

  List<DataGridRow> _rows = <DataGridRow>[];
  final Map<DataGridRow, T> _itemOf = Map<DataGridRow, T>.identity();
  final Map<T, DataGridRow> _rowOf = Map<T, DataGridRow>.identity();
  bool _attached = false;

  /// Replaces the records shown in the grid (already filtered by the toolbar).
  void setItems(List<T> items) {
    _itemOf.clear();
    _rowOf.clear();
    _rows = <DataGridRow>[
      for (final item in items) _buildRow(item),
    ];
    notifyListeners();
  }

  DataGridRow _buildRow(T item) {
    final row = DataGridRow(
      cells: <DataGridCell>[
        for (final c in layout.all)
          DataGridCell<Object>(columnName: c.label, value: c.value(item)),
      ],
    );
    _itemOf[row] = item;
    _rowOf[item] = row;
    return row;
  }

  int get itemCount => _rows.length;

  T? itemOf(DataGridRow row) => _itemOf[row];

  DataGridRow? rowOf(T item) => _rowOf[item];

  /// Called by the grid widget once it is on screen.
  void markAttached() => _attached = true;

  /// Records left after the toolbar filters AND the grid's own column
  /// filters, in the current sort order. Not limited to the current page.
  List<T> get effectiveItems {
    final source = _attached ? effectiveRows : _rows;
    return <T>[
      for (final row in source)
        if (_itemOf[row] case final T item) item,
    ];
  }

  void refresh() => notifyListeners();

  /// Shows or hides a column. A hidden column cannot keep filtering or
  /// sorting the table, so those are dropped first.
  void setColumnVisible(ColumnDef<T> column, bool visible) {
    if (!visible) {
      if (filterConditions.containsKey(column.label)) {
        clearFilters(columnName: column.label);
      }
      sortedColumns.removeWhere((SortColumnDetails s) => s.name == column.label);
    }
    layout.setVisible(column, visible);
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    final item = _itemOf[row];
    if (item == null) return null;
    return DataGridRowAdapter(
      cells: <Widget>[
        for (final c in layout.visible) _buildCell(c, item),
      ],
    );
  }

  Widget _buildCell(ColumnDef<T> column, T item) {
    final custom = column.builder;
    return Container(
      alignment: column.isNumeric ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: custom != null
          ? custom(item)
          : Text(
              column.display(column.value(item)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: column.color?.call(item),
                fontFeatures: column.isNumeric
                    ? const <FontFeature>[FontFeature.tabularFigures()]
                    : null,
              ),
            ),
    );
  }
}
