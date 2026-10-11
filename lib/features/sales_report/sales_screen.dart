import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../models/enums.dart';
import '../../models/sale.dart';
import '../../shared/excel_export.dart';
import '../../shared/formatters.dart';
import '../../shared/widgets/app_data_grid.dart';
import '../../shared/widgets/totals_bar.dart';
import 'grouped_view.dart';
import 'sales_table.dart';
import 'sales_toolbar.dart';
import 'summary_cards.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final SalesDataSource _source = SalesDataSource();
  final ValueNotifier<int> _viewVersion = ValueNotifier<int>(0);
  late final AppStore _store;

  @override
  void initState() {
    super.initState();
    _store = context.read<AppStore>();
    _source.setItems(_store.filteredSales);
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    _viewVersion.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    _source.setItems(_store.filteredSales);
    _bumpView();
  }

  void _bumpView() {
    if (!mounted) return;
    setState(() {});
    _viewVersion.value++;
  }

  Future<void> _export() async {
    final items = _source.effectiveItems;
    final columns = _source.layout.visible;
    final groupBy = _store.salesGroupBy;
    final sheets = <ExportSheet>[
      if (groupBy != SalesGroupBy.none)
        buildSalesSummarySheet(groupSales(items, groupBy), groupBy, SalesTotals(items)),
      buildSalesDetailSheet(
        columns,
        items,
        name: groupBy == SalesGroupBy.none ? 'Sales' : 'Details',
      ),
    ];
    await exportToExcel(
      context,
      filePrefix: 'sales_report',
      sheets: sheets,
      rowCount: items.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupBy = context.select<AppStore, SalesGroupBy>((s) => s.salesGroupBy);
    final grouped = groupBy != SalesGroupBy.none;
    // Rows left after the toolbar filters and the grid's column filters.
    final items = _source.effectiveItems;
    final totals = SalesTotals(items);

    return Column(
      children: <Widget>[
        SalesToolbar(onExport: _export),
        const Divider(height: 1),
        SummaryCards(totals: totals),
        const SizedBox(height: 8),
        const Divider(height: 1),
        Expanded(
          // The grid stays mounted while grouped so its sort and column
          // filters keep applying to the grouped view as well.
          child: IndexedStack(
            index: grouped ? 1 : 0,
            sizing: StackFit.expand,
            children: <Widget>[
              AppDataGrid<Sale>(
                source: _source,
                viewVersion: _viewVersion,
                onViewChanged: _bumpView,
              ),
              if (grouped)
                GroupedSalesView(
                  groups: groupSales(items, groupBy),
                  groupLabel: groupBy.label,
                  columns: _source.layout.visible,
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
        TotalsBar(
          showing: 'Showing ${formatCount(totals.count)} of '
              '${formatCount(_store.sales.length)} sales',
          items: <TotalItem>[
            TotalItem('Sales', formatCount(totals.count)),
            TotalItem('Total Cost Price', formatMoney(totals.cost)),
            TotalItem('Total Sale Price', formatMoney(totals.sale)),
            TotalItem('Total Discount', formatMoney(totals.discount)),
            TotalItem(
              'Total Profit',
              formatMoney(totals.profit),
              color: totals.profit < 0 ? negativeColor : null,
            ),
            TotalItem('Average Profit %', formatPercent(totals.avgProfitPercent)),
          ],
        ),
      ],
    );
  }
}
