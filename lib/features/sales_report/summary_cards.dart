import 'package:flutter/material.dart';

import '../../shared/formatters.dart';
import 'sales_table.dart';

/// The four headline numbers above the Sales Report table.
class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key, required this.totals});
  final SalesTotals totals;

  @override
  Widget build(BuildContext context) {
    final negative = totals.profit < 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: <Widget>[
          _Card(
            icon: Icons.payments_outlined,
            label: 'Total Sales (PKR)',
            value: formatMoney(totals.sale),
          ),
          const SizedBox(width: 12),
          _Card(
            icon: Icons.trending_up,
            label: 'Total Profit (PKR)',
            value: formatMoney(totals.profit),
            valueColor: negative ? negativeColor : null,
          ),
          const SizedBox(width: 12),
          _Card(
            icon: Icons.percent,
            label: 'Average Profit %',
            value: formatPercent(totals.avgProfitPercent),
            valueColor: totals.avgProfitPercent < 0 ? negativeColor : null,
          ),
          const SizedBox(width: 12),
          _Card(
            icon: Icons.receipt_long_outlined,
            label: 'Number of Invoices',
            value: formatCount(totals.count),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.icon, required this.label, required this.value, this.valueColor});
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: scheme.onPrimaryContainer, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: valueColor,
                      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
