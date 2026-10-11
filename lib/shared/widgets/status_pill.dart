import 'package:flutter/material.dart';

import '../../models/enums.dart';

Color statusColor(ArticleStatus status) {
  switch (status) {
    case ArticleStatus.available:
      return const Color(0xFF2E7D32);
    case ArticleStatus.promotional:
      return const Color(0xFF1565C0);
    case ArticleStatus.sold:
      return const Color(0xFF616161);
    case ArticleStatus.borrowed:
      return const Color(0xFFE65100);
    case ArticleStatus.melted:
      return const Color(0xFFC62828);
    case ArticleStatus.returnedToSupplier:
      return const Color(0xFF6A1B9A);
    case ArticleStatus.gifted:
      return const Color(0xFFC2185B);
  }
}

/// Small coloured label for an article status.
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final ArticleStatus status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        status.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
