import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../data/seed_data.dart';
import '../../models/enums.dart';
import '../../shared/widgets/filter_controls.dart';

class SalesToolbar extends StatelessWidget {
  const SalesToolbar({super.key, required this.onExport});
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final preset in AppStore.salesPresets)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(preset),
                          selected: store.salesPreset == preset,
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => store.setSalesPreset(preset),
                        ),
                      ),
                  ],
                ),
                DateFilterButton(
                  label: 'From',
                  value: store.salesFrom,
                  onChanged: (d) => store.setSalesDates(from: d, to: store.salesTo),
                ),
                DateFilterButton(
                  label: 'To',
                  value: store.salesTo,
                  onChanged: (d) => store.setSalesDates(from: store.salesFrom, to: d),
                ),
                FilterDropdown<String>(
                  label: 'Salesman',
                  value: store.salesSalesman,
                  options: seedSalesmen,
                  optionLabel: (s) => s,
                  onChanged: store.setSalesSalesman,
                ),
                FilterDropdown<Branch>(
                  label: 'Branch',
                  value: store.salesBranch,
                  options: Branch.values,
                  optionLabel: (b) => b.label,
                  onChanged: store.setSalesBranch,
                ),
                FilterDropdown<PaymentMethod>(
                  label: 'Payment',
                  value: store.salesPayment,
                  options: PaymentMethod.values,
                  optionLabel: (p) => p.label,
                  onChanged: store.setSalesPayment,
                ),
                FilterDropdown<ItemCategory>(
                  label: 'Category',
                  value: store.salesCategory,
                  options: ItemCategory.values,
                  optionLabel: (c) => c.label,
                  onChanged: store.setSalesCategory,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(width: 6),
                    Text('Group by', style: theme.textTheme.labelLarge),
                    const SizedBox(width: 8),
                    SegmentedButton<SalesGroupBy>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity(horizontal: -2, vertical: -2),
                      ),
                      segments: <ButtonSegment<SalesGroupBy>>[
                        for (final g in SalesGroupBy.values)
                          ButtonSegment<SalesGroupBy>(value: g, label: Text(g.label)),
                      ],
                      selected: <SalesGroupBy>{store.salesGroupBy},
                      onSelectionChanged: (Set<SalesGroupBy> value) =>
                          store.setSalesGroupBy(value.first),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onExport,
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('Export to Excel'),
          ),
        ],
      ),
    );
  }
}
