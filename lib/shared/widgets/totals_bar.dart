import 'package:flutter/material.dart';

class TotalItem {
  const TotalItem(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;
}

/// Bar pinned under a table showing totals for the rows currently in view.
class TotalsBar extends StatelessWidget {
  const TotalsBar({super.key, required this.showing, required this.items});

  /// e.g. "Showing 143 of 600 articles".
  final String showing;
  final List<TotalItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.45),
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.filter_alt_outlined, size: 18, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            showing,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 28,
              runSpacing: 6,
              children: <Widget>[
                for (final item in items)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        item.label,
                        style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      Text(
                        item.value,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: item.color,
                          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
