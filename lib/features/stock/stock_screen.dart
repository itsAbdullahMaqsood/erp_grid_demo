import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../data/app_store.dart';
import '../../models/article.dart';
import '../../shared/excel_export.dart';
import '../../shared/formatters.dart';
import '../../shared/widgets/app_data_grid.dart';
import '../../shared/widgets/totals_bar.dart';
import 'details_panel.dart';
import 'edit_dialog.dart';
import 'stock_table.dart';
import 'stock_toolbar.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final StockDataSource _source = StockDataSource();
  final DataGridController _gridController = DataGridController();
  final TextEditingController _search = TextEditingController();
  final ValueNotifier<int> _viewVersion = ValueNotifier<int>(0);
  late final AppStore _store;
  Article? _selected;

  @override
  void initState() {
    super.initState();
    _store = context.read<AppStore>();
    _source.setItems(_store.filteredArticles);
    _store.addListener(_onStoreChanged);
    _store.stockGridFilterReset.addListener(_onGridFilterReset);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    _store.stockGridFilterReset.removeListener(_onGridFilterReset);
    _gridController.dispose();
    _search.dispose();
    _viewVersion.dispose();
    super.dispose();
  }

  /// Toolbar filters live in the store. Push the filtered list into the grid;
  /// the grid then applies its own column filters on top.
  void _onStoreChanged() {
    final items = _store.filteredArticles;
    _source.setItems(items);
    if (_search.text.trim() != _store.stockSearch) {
      _search.text = _store.stockSearch;
    }
    final selected = _selected;
    if (selected != null) {
      if (items.contains(selected)) {
        // Rows were rebuilt, so point the highlight at the new row object.
        _gridController.selectedRow = _source.rowOf(selected);
      } else {
        _gridController.selectedRow = null;
        _selected = null;
      }
    }
    _bumpView();
  }

  void _onGridFilterReset() {
    if (_source.filterConditions.isNotEmpty) _source.clearFilters();
    _bumpView();
  }

  void _bumpView() {
    if (!mounted) return;
    setState(() {});
    _viewVersion.value++;
  }

  void _closeDetails() {
    _gridController.selectedRow = null;
    setState(() => _selected = null);
  }

  Future<void> _export() async {
    final items = _source.effectiveItems;
    await exportToExcel(
      context,
      filePrefix: 'stock',
      sheets: <ExportSheet>[buildStockSheet(_source.layout.visible, items)],
      rowCount: items.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            children: <Widget>[
              StockToolbar(
                searchController: _search,
                source: _source,
                onClear: _store.clearStockFilters,
                onExport: _export,
                onColumnsChanged: _bumpView,
              ),
              const Divider(height: 1),
              Expanded(
                child: AppDataGrid<Article>(
                  source: _source,
                  controller: _gridController,
                  viewVersion: _viewVersion,
                  onViewChanged: _bumpView,
                  onRowSelected: (Article? article) => setState(() => _selected = article),
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: _viewVersion,
                builder: (BuildContext context, int _, Widget? child) {
                  final totals = StockTotals(_source.effectiveItems);
                  return TotalsBar(
                    showing: 'Showing ${formatCount(totals.count)} of '
                        '${formatCount(_store.articles.length)} articles',
                    items: <TotalItem>[
                      TotalItem('Articles', formatCount(totals.count)),
                      TotalItem('Total Gross Weight (g)', formatGrams(totals.grossMg)),
                      TotalItem('Total Net Weight (g)', formatGrams(totals.netMg)),
                      TotalItem('Total Cost Price', formatMoney(totals.cost)),
                      TotalItem('Total Tag Price', formatMoney(totals.tag)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        if (selected != null)
          DetailsPanel(
            article: selected,
            onClose: _closeDetails,
            onEdit: () => EditArticleDialog.show(context, selected),
          ),
      ],
    );
  }
}
