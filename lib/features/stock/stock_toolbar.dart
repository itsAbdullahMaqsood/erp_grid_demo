import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../models/article.dart';
import '../../models/enums.dart';
import '../../shared/grid_columns.dart';
import '../../shared/widgets/filter_controls.dart';

class StockToolbar extends StatelessWidget {
  const StockToolbar({
    super.key,
    required this.searchController,
    required this.source,
    required this.onClear,
    required this.onExport,
    required this.onColumnsChanged,
  });

  final TextEditingController searchController;
  final ItemDataSource<Article> source;
  final VoidCallback onClear;
  final VoidCallback onExport;
  final VoidCallback onColumnsChanged;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final layout = source.layout;

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
                SizedBox(
                  width: 290,
                  height: kControlHeight,
                  child: TextField(
                    controller: searchController,
                    onChanged: store.setStockSearch,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search code, barcode, description, supplier',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: store.stockSearch.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                searchController.clear();
                                store.setStockSearch('');
                              },
                            ),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _CategoryChip(
                      label: 'All',
                      selected: store.stockCategory == null,
                      onSelected: () => store.setStockCategory(null),
                    ),
                    for (final c in ItemCategory.values)
                      _CategoryChip(
                        label: c.label,
                        selected: store.stockCategory == c,
                        onSelected: () => store.setStockCategory(c),
                      ),
                  ],
                ),
                MultiFilterDropdown<ArticleStatus>(
                  label: 'Status',
                  selected: store.stockStatuses,
                  options: ArticleStatus.values,
                  optionLabel: (s) => s.label,
                  onToggle: store.toggleStockStatus,
                ),
                FilterDropdown<Branch>(
                  label: 'Branch',
                  value: store.stockBranch,
                  options: Branch.values,
                  optionLabel: (b) => b.label,
                  onChanged: store.setStockBranch,
                ),
                DateFilterButton(
                  label: 'Added from',
                  value: store.stockFrom,
                  onChanged: (d) => store.setStockDates(from: d, to: store.stockTo),
                ),
                DateFilterButton(
                  label: 'Added to',
                  value: store.stockTo,
                  onChanged: (d) => store.setStockDates(from: store.stockFrom, to: d),
                ),
                ListenableBuilder(
                  listenable: layout,
                  builder: (BuildContext context, Widget? child) {
                    final shown = layout.all.where(layout.isVisible).toSet();
                    return MultiFilterDropdown<ColumnDef<Article>>(
                      label: 'Columns',
                      icon: Icons.view_column_outlined,
                      summary: shown.length == layout.all.length
                          ? 'Columns'
                          : 'Columns: ${shown.length} of ${layout.all.length}',
                      active: shown.length != layout.all.length,
                      selected: shown,
                      // The frozen Article Code column always stays.
                      options: layout.all.skip(1).toList(),
                      optionLabel: (c) => c.label,
                      onToggle: (c, visible) {
                        source.setColumnVisible(c, visible);
                        onColumnsChanged();
                      },
                    );
                  },
                ),
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Clear filters'),
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onSelected});
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
