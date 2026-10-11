import 'package:flutter/material.dart';

import '../../models/article.dart';
import '../../shared/formatters.dart';
import '../../shared/widgets/status_pill.dart';

/// Read-only side panel listing every field of the selected article.
class DetailsPanel extends StatelessWidget {
  const DetailsPanel({
    super.key,
    required this.article,
    required this.onEdit,
    required this.onClose,
  });

  final Article article;
  final VoidCallback onEdit;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final a = article;

    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(left: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Article details', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 2),
                      Text(
                        a.articleCode,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(alignment: Alignment.centerLeft, child: StatusPill(a.status)),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: <Widget>[
                const _Section('Item'),
                _Field('Description', a.description),
                _Field('Barcode', a.barcode),
                _Field('Category', a.category.label),
                _Field('Sub Category', a.subCategory),
                _Field('Purity', a.purity),
                const _Section('Weight'),
                _Field('Gross Weight', '${formatGrams(a.grossWeightMg)} g'),
                _Field('Stone Weight', '${formatGrams(a.stoneWeightMg)} g'),
                _Field('Net Weight', '${formatGrams(a.netWeightMg)} g'),
                const _Section('Pricing (PKR)'),
                _Field('Making Charges', formatMoney(a.makingCharges)),
                _Field('Stone Charges', formatMoney(a.stoneCharges)),
                _Field('Cost Price', formatMoney(a.costPrice)),
                _Field('Tag Price', formatMoney(a.tagPrice)),
                const _Section('Stock'),
                _Field('Status', a.status.label),
                _Field('Supplier', a.supplier),
                _Field('Branch', a.branch.label),
                _Field('Date Added', formatDate(a.dateAdded)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
