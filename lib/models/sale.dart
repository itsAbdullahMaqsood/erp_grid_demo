import 'enums.dart';

/// A sale invoice line. Money is whole rupees.
class Sale {
  Sale({
    required this.invoiceNo,
    required this.date,
    required this.articleCode,
    required this.category,
    required this.customerName,
    required this.salesman,
    required this.branch,
    required this.costPrice,
    required this.salePrice,
    required this.discount,
    required this.paymentMethod,
  });

  final String invoiceNo;
  final DateTime date;
  final String articleCode;
  final ItemCategory category;
  final String customerName;
  final String salesman;
  final Branch branch;
  final int costPrice;
  final int salePrice;
  final int discount;
  final PaymentMethod paymentMethod;

  int get profit => salePrice - costPrice;

  /// Profit as a percentage of cost, e.g. 18.4.
  double get profitPercent => costPrice == 0 ? 0 : profit * 100 / costPrice;
}
