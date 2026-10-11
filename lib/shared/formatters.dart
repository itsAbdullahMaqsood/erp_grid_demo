import 'package:intl/intl.dart';

final NumberFormat _whole = NumberFormat('#,##0', 'en_US');
final DateFormat _date = DateFormat('dd MMM yyyy', 'en_US');
final DateFormat _fileDate = DateFormat('yyyy-MM-dd', 'en_US');

/// 142000 -> "142,000"
String formatMoney(int rupees) => _whole.format(rupees);

/// 4850 mg -> "4.850". Integer math only, so no rounding surprises.
String formatGrams(int milligrams) {
  final sign = milligrams < 0 ? '-' : '';
  final abs = milligrams.abs();
  return '$sign${_whole.format(abs ~/ 1000)}.${(abs % 1000).toString().padLeft(3, '0')}';
}

/// 18.37 -> "18.4%"
String formatPercent(double percent) => '${percent.toStringAsFixed(1)}%';

String formatDate(DateTime date) => _date.format(date);

/// Date part used in export file names, e.g. 2026-10-11.
String formatFileDate(DateTime date) => _fileDate.format(date);

String formatCount(int n) => _whole.format(n);
