import 'package:flutter/material.dart';

import '../formatters.dart';

const double kControlHeight = 38;

ButtonStyle _controlStyle(BuildContext context, {bool active = false}) {
  final scheme = Theme.of(context).colorScheme;
  return OutlinedButton.styleFrom(
    minimumSize: const Size(0, kControlHeight),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    foregroundColor: active ? scheme.primary : scheme.onSurface,
    backgroundColor: active ? scheme.primary.withValues(alpha: 0.08) : null,
    side: BorderSide(color: active ? scheme.primary : scheme.outline),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
  );
}

/// Single choice dropdown shown as "Label: value". A null value means "All".
class FilterDropdown<T> extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> options;
  final String Function(T option) optionLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = value;
    return MenuAnchor(
      menuChildren: <Widget>[
        MenuItemButton(
          onPressed: () => onChanged(null),
          child: const Text('All'),
        ),
        for (final option in options)
          MenuItemButton(
            onPressed: () => onChanged(option),
            child: Text(optionLabel(option)),
          ),
      ],
      builder: (BuildContext context, MenuController menu, Widget? child) {
        return OutlinedButton(
          style: _controlStyle(context, active: current != null),
          onPressed: () => menu.isOpen ? menu.close() : menu.open(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('$label: ${current == null ? 'All' : optionLabel(current)}'),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        );
      },
    );
  }
}

/// Multi choice dropdown with checkboxes. Stays open while ticking.
class MultiFilterDropdown<T> extends StatelessWidget {
  const MultiFilterDropdown({
    super.key,
    required this.label,
    required this.selected,
    required this.options,
    required this.optionLabel,
    required this.onToggle,
    this.icon,
    this.summary,
    this.active,
  });

  final String label;
  final Set<T> selected;
  final List<T> options;
  final String Function(T option) optionLabel;
  final void Function(T option, bool selected) onToggle;
  final IconData? icon;

  /// Overrides the "x of y" text on the button.
  final String? summary;
  final bool? active;

  @override
  Widget build(BuildContext context) {
    final all = selected.length == options.length;
    final text = summary ??
        (all ? '$label: All' : '$label: ${selected.length} of ${options.length}');
    return MenuAnchor(
      menuChildren: <Widget>[
        for (final option in options)
          CheckboxMenuButton(
            value: selected.contains(option),
            closeOnActivate: false,
            onChanged: (bool? checked) => onToggle(option, checked ?? false),
            child: Text(optionLabel(option)),
          ),
      ],
      builder: (BuildContext context, MenuController menu, Widget? child) {
        return OutlinedButton(
          style: _controlStyle(context, active: active ?? !all),
          onPressed: () => menu.isOpen ? menu.close() : menu.open(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[Icon(icon, size: 18), const SizedBox(width: 6)],
              Text(text),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        );
      },
    );
  }
}

/// Button that opens a date picker. Shows a clear icon once a date is set.
class DateFilterButton extends StatelessWidget {
  const DateFilterButton({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = value;
    return OutlinedButton(
      style: _controlStyle(context, active: current != null),
      onPressed: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: current ?? now,
          firstDate: DateTime(now.year - 3),
          lastDate: DateTime(now.year + 1, 12, 31),
          helpText: label,
        );
        if (picked != null) onChanged(picked);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.calendar_today_outlined, size: 15),
          const SizedBox(width: 6),
          Text(current == null ? label : '$label: ${formatDate(current)}'),
          if (current != null) ...<Widget>[
            const SizedBox(width: 4),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(null),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close, size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
