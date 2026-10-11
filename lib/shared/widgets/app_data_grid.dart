import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../grid_columns.dart';

/// The table used on the Stock and Sales screens: sortable, filterable,
/// resizable, reorderable columns, a frozen first column and a pager.
class AppDataGrid<T> extends StatefulWidget {
  const AppDataGrid({
    super.key,
    required this.source,
    required this.viewVersion,
    required this.onViewChanged,
    this.controller,
    this.onRowSelected,
  });

  final ItemDataSource<T> source;

  /// Ticks whenever the set of rows left after all filters may have changed.
  final ValueNotifier<int> viewVersion;

  /// Called when the grid's own column filters change.
  final VoidCallback onViewChanged;

  final DataGridController? controller;
  final ValueChanged<T?>? onRowSelected;

  @override
  State<AppDataGrid<T>> createState() => _AppDataGridState<T>();
}

class _AppDataGridState<T> extends State<AppDataGrid<T>> {
  static const List<int> _pageSizes = <int>[25, 50, 100];
  int _rowsPerPage = 50;

  GridLayout<T> get _layout => widget.source.layout;

  @override
  void initState() {
    super.initState();
    _layout.addListener(_onLayoutChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.source.markAttached();
      widget.onViewChanged();
    });
  }

  @override
  void dispose() {
    _layout.removeListener(_onLayoutChanged);
    super.dispose();
  }

  void _onLayoutChanged() {
    if (!mounted) return;
    setState(() {});
    // Cells are built in column order, so rows must be rebuilt as well.
    widget.source.refresh();
  }

  bool _onColumnDragging(DataGridColumnDragDetails details) {
    // The first column is frozen: it cannot be moved and nothing can be
    // dropped in front of it.
    if (details.from == 0) return false;
    if (details.action == DataGridColumnDragAction.dropping && details.to == 0) {
      return false;
    }
    if (details.action == DataGridColumnDragAction.dropped && details.to != null) {
      _layout.move(details.from, details.to!);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final columns = _layout.visible;

    return Column(
      children: <Widget>[
        Expanded(
          child: SfDataGridTheme(
            data: SfDataGridThemeData(
              headerColor: scheme.surfaceContainerHigh,
              headerHoverColor: scheme.surfaceContainerHighest,
              gridLineColor: scheme.outlineVariant,
              gridLineStrokeWidth: 1,
              frozenPaneLineColor: scheme.outline,
              frozenPaneLineWidth: 1.5,
              selectionColor: scheme.primary.withValues(alpha: 0.14),
              rowHoverColor: scheme.primary.withValues(alpha: 0.05),
              sortIconColor: scheme.primary,
              filterIconColor: scheme.onSurfaceVariant,
              filterIconHoverColor: scheme.primary,
              columnResizeIndicatorColor: scheme.primary,
              columnDragIndicatorColor: scheme.primary,
            ),
            child: SfDataGrid(
              source: widget.source,
              controller: widget.controller,
              columns: <GridColumn>[
                for (final c in columns)
                  GridColumn(
                    columnName: c.label,
                    width: _layout.widthOf(c),
                    minimumWidth: 70,
                    label: Container(
                      alignment: c.isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        c.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
              rowHeight: 34,
              headerRowHeight: 40,
              rowsPerPage: _rowsPerPage,
              gridLinesVisibility: GridLinesVisibility.both,
              headerGridLinesVisibility: GridLinesVisibility.both,
              frozenColumnsCount: 1,
              // Sorting: one click ascending, next click descending.
              allowSorting: true,
              allowTriStateSorting: false,
              // Excel-style filter popup on every header.
              allowFiltering: true,
              onFilterChanged: (_) => widget.onViewChanged(),
              allowColumnsResizing: true,
              columnResizeMode: ColumnResizeMode.onResize,
              onColumnResizeUpdate: (ColumnResizeUpdateDetails details) {
                _layout.setWidth(details.column.columnName, details.width);
                return true;
              },
              allowColumnsDragging: true,
              onColumnDragging: _onColumnDragging,
              selectionMode: SelectionMode.single,
              navigationMode: GridNavigationMode.row,
              onSelectionChanged: (List<DataGridRow> added, List<DataGridRow> removed) {
                final onRowSelected = widget.onRowSelected;
                if (onRowSelected == null) return;
                onRowSelected(added.isEmpty ? null : widget.source.itemOf(added.first));
              },
            ),
          ),
        ),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: ValueListenableBuilder<int>(
            valueListenable: widget.viewVersion,
            builder: (BuildContext context, int _, Widget? child) {
              final count = widget.source.effectiveItems.length;
              final pages = count == 0 ? 1 : (count / _rowsPerPage).ceil();
              return SfDataPagerTheme(
                data: SfDataPagerThemeData(
                  selectedItemColor: scheme.primary,
                  itemBorderRadius: BorderRadius.circular(6),
                ),
                child: SfDataPager(
                  delegate: widget.source,
                  pageCount: pages.toDouble(),
                  itemHeight: 36,
                  itemWidth: 40,
                  navigationItemHeight: 36,
                  navigationItemWidth: 40,
                  availableRowsPerPage: _pageSizes,
                  onRowsPerPageChanged: (int? value) {
                    if (value == null) return;
                    setState(() => _rowsPerPage = value);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) widget.onViewChanged();
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
