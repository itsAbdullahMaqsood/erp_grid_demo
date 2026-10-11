import 'package:flutter/material.dart';

import '../../models/sale.dart';
import '../../shared/formatters.dart';
import '../../shared/grid_columns.dart';
import 'sales_table.dart';

/// Summary table used when "Group by" is on: one row per group with its
/// totals. Clicking a group row expands it to show the sales inside.
class GroupedSalesView extends StatefulWidget {
  const GroupedSalesView({
    super.key,
    required this.groups,
    required this.groupLabel,
    required this.columns,
  });

  final List<SalesGroup> groups;
  final String groupLabel;

  /// Columns shown for the sales inside an expanded group.
  final List<ColumnDef<Sale>> columns;

  @override
  State<GroupedSalesView> createState() => _GroupedSalesViewState();
}

class _GroupedSalesViewState extends State<GroupedSalesView> {
  final Set<String> _expanded = <String>{};
  final ScrollController _horizontal = ScrollController();

  static const double _indent = 44;

  @override
  void didUpdateWidget(GroupedSalesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupLabel != widget.groupLabel) _expanded.clear();
  }

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final detailWidth =
        _indent + widget.columns.fold<double>(0, (sum, c) => sum + c.width);

    // Flatten groups and the sales of expanded groups into one lazy list.
    final entries = <Object>[];
    for (final g in widget.groups) {
      entries.add(g);
      if (_expanded.contains(g.name)) {
        entries.add(_DetailHeader(g));
        entries.addAll(g.sales);
      }
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final width = detailWidth > constraints.maxWidth ? detailWidth : constraints.maxWidth;
        return Scrollbar(
          controller: _horizontal,
          thumbVisibility: true,
          notificationPredicate: (ScrollNotification n) => n.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Column(
                children: <Widget>[
                  Container(
                    height: 40,
                    color: scheme.surfaceContainerHigh,
                    child: _summaryRow(
                      context,
                      leading: const SizedBox(width: 24),
                      name: widget.groupLabel,
                      count: 'Number of Sales',
                      sale: 'Total Sale Price',
                      profit: 'Total Profit',
                      percent: 'Average Profit %',
                      bold: true,
                    ),
                  ),
                  Divider(height: 1, color: scheme.outlineVariant),
                  Expanded(
                    child: widget.groups.isEmpty
                        ? const Center(child: Text('No sales match the current filters'))
                        : ListView.builder(
                            itemCount: entries.length,
                            itemBuilder: (BuildContext context, int index) {
                              final entry = entries[index];
                              if (entry is SalesGroup) return _groupRow(context, entry);
                              if (entry is _DetailHeader) return _detailHeader(context);
                              return _detailRow(context, entry as Sale);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _summaryRow(
    BuildContext context, {
    required Widget leading,
    required String name,
    required String count,
    required String sale,
    required String profit,
    required String percent,
    bool bold = false,
    Color? profitColor,
  }) {
    final style = TextStyle(
      fontSize: 13,
      fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    Widget number(String text, double width, {Color? color}) => SizedBox(
          width: width,
          child: Text(
            text,
            textAlign: TextAlign.right,
            style: color == null ? style : style.copyWith(color: color),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: <Widget>[
          leading,
          const SizedBox(width: 10),
          SizedBox(width: 260, child: Text(name, style: style, overflow: TextOverflow.ellipsis)),
          number(count, 140),
          number(sale, 180),
          number(profit, 160, color: profitColor),
          number(percent, 160, color: profitColor),
        ],
      ),
    );
  }

  Widget _groupRow(BuildContext context, SalesGroup group) {
    final scheme = Theme.of(context).colorScheme;
    final open = _expanded.contains(group.name);
    final t = group.totals;
    return InkWell(
      onTap: () => setState(() {
        if (!_expanded.remove(group.name)) _expanded.add(group.name);
      }),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: open ? scheme.primary.withValues(alpha: 0.07) : null,
          border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        child: _summaryRow(
          context,
          leading: Icon(
            open ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
            size: 24,
            color: scheme.primary,
          ),
          name: group.name,
          count: formatCount(t.count),
          sale: formatMoney(t.sale),
          profit: formatMoney(t.profit),
          percent: formatPercent(t.avgProfitPercent),
          profitColor: t.profit < 0 ? negativeColor : null,
        ),
      ),
    );
  }

  Widget _cells(BuildContext context, String Function(ColumnDef<Sale> c) text,
      {Color? Function(ColumnDef<Sale> c)? color, bool header = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        const SizedBox(width: _indent),
        for (final c in widget.columns)
          Container(
            width: c.width,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: c.isNumeric ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              text(c),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: header ? 12 : 13,
                fontWeight: header ? FontWeight.w600 : FontWeight.w400,
                color: color?.call(c) ?? (header ? scheme.onSurfaceVariant : null),
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
      ],
    );
  }

  Widget _detailHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 30,
      color: scheme.surfaceContainerLow,
      child: _cells(context, (c) => c.label, header: true),
    );
  }

  Widget _detailRow(BuildContext context, Sale sale) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: _cells(
        context,
        (c) => c.display(c.value(sale)),
        color: (c) => c.color?.call(sale),
      ),
    );
  }
}

class _DetailHeader {
  const _DetailHeader(this.group);
  final SalesGroup group;
}
