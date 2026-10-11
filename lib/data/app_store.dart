import 'package:flutter/foundation.dart';

import '../models/article.dart';
import '../models/enums.dart';
import '../models/sale.dart';
import 'seed_data.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class ImportOutcome {
  const ImportOutcome({required this.added, required this.updated, required this.skipped});
  final int added;
  final int updated;
  final int skipped;
}

/// Holds all in-memory data plus the toolbar filters of both table screens.
class AppStore extends ChangeNotifier {
  AppStore() {
    final seed = generateSeedData();
    articles = seed.articles;
    sales = seed.sales;
    setSalesPreset('Last 90 days', notify: false);
  }

  late final List<Article> articles;
  late final List<Sale> sales;

  // ---------------------------------------------------------------- navigation

  int navIndex = 0;

  void setNavIndex(int index) {
    navIndex = index;
    notifyListeners();
  }

  /// Bumped when the Stock grid should drop its own header filters too.
  final ValueNotifier<int> stockGridFilterReset = ValueNotifier<int>(0);

  // -------------------------------------------------------------- stock filters

  String stockSearch = '';
  ItemCategory? stockCategory;
  Set<ArticleStatus> stockStatuses = _defaultStatuses();
  Branch? stockBranch;
  DateTime? stockFrom;
  DateTime? stockTo;

  static Set<ArticleStatus> _defaultStatuses() =>
      ArticleStatus.values.toSet().difference(defaultHiddenStatuses);

  bool get hasStockFilters =>
      stockSearch.isNotEmpty ||
      stockCategory != null ||
      stockBranch != null ||
      stockFrom != null ||
      stockTo != null ||
      !setEquals(stockStatuses, _defaultStatuses());

  void setStockSearch(String value) {
    stockSearch = value.trim();
    notifyListeners();
  }

  void setStockCategory(ItemCategory? value) {
    stockCategory = value;
    notifyListeners();
  }

  void toggleStockStatus(ArticleStatus status, bool selected) {
    stockStatuses = <ArticleStatus>{...stockStatuses};
    if (selected) {
      stockStatuses.add(status);
    } else {
      stockStatuses.remove(status);
    }
    notifyListeners();
  }

  void setStockBranch(Branch? value) {
    stockBranch = value;
    notifyListeners();
  }

  void setStockDates({DateTime? from, DateTime? to}) {
    stockFrom = from;
    stockTo = to;
    notifyListeners();
  }

  void clearStockFilters() {
    _resetStockFilters();
    stockGridFilterReset.value++;
    notifyListeners();
  }

  void _resetStockFilters() {
    stockSearch = '';
    stockCategory = null;
    stockStatuses = _defaultStatuses();
    stockBranch = null;
    stockFrom = null;
    stockTo = null;
  }

  /// Opens the Stock screen showing only the articles added today.
  void showTodayInStock() {
    _resetStockFilters();
    final today = dateOnly(DateTime.now());
    stockFrom = today;
    stockTo = today;
    navIndex = 0;
    stockGridFilterReset.value++;
    notifyListeners();
  }

  List<Article> get filteredArticles {
    final query = stockSearch.toLowerCase();
    return articles.where((a) {
      if (stockCategory != null && a.category != stockCategory) return false;
      if (!stockStatuses.contains(a.status)) return false;
      if (stockBranch != null && a.branch != stockBranch) return false;
      if (stockFrom != null && a.dateAdded.isBefore(stockFrom!)) return false;
      if (stockTo != null && a.dateAdded.isAfter(stockTo!)) return false;
      if (query.isNotEmpty &&
          !a.articleCode.toLowerCase().contains(query) &&
          !a.barcode.contains(query) &&
          !a.description.toLowerCase().contains(query) &&
          !a.supplier.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  Article? articleByCode(String code) {
    for (final a in articles) {
      if (a.articleCode == code) return a;
    }
    return null;
  }

  void updateArticle(
    Article article, {
    required String description,
    required int makingCharges,
    required int stoneCharges,
    required int tagPrice,
    required ArticleStatus status,
  }) {
    article
      ..description = description
      ..makingCharges = makingCharges
      ..stoneCharges = stoneCharges
      ..tagPrice = tagPrice
      ..status = status;
    notifyListeners();
  }

  /// Adds [incoming] articles. Codes that already exist are either updated in
  /// place or skipped, depending on [updateExisting].
  ImportOutcome importArticles(List<Article> incoming, {required bool updateExisting}) {
    final byCode = <String, Article>{
      for (final a in articles) a.articleCode.toLowerCase(): a,
    };
    var added = 0, updated = 0, skipped = 0;
    for (final item in incoming) {
      final existing = byCode[item.articleCode.toLowerCase()];
      if (existing == null) {
        articles.add(item);
        byCode[item.articleCode.toLowerCase()] = item;
        added++;
      } else if (updateExisting) {
        existing
          ..barcode = item.barcode
          ..category = item.category
          ..subCategory = item.subCategory
          ..description = item.description
          ..purity = item.purity
          ..grossWeightMg = item.grossWeightMg
          ..stoneWeightMg = item.stoneWeightMg
          ..makingCharges = item.makingCharges
          ..stoneCharges = item.stoneCharges
          ..costPrice = item.costPrice
          ..tagPrice = item.tagPrice
          ..supplier = item.supplier
          ..branch = item.branch;
        updated++;
      } else {
        skipped++;
      }
    }
    notifyListeners();
    return ImportOutcome(added: added, updated: updated, skipped: skipped);
  }

  // -------------------------------------------------------------- sales filters

  static const List<String> salesPresets = <String>[
    'Today',
    'Last 7 days',
    'This month',
    'Last 90 days',
  ];

  String? salesPreset;
  DateTime? salesFrom;
  DateTime? salesTo;
  String? salesSalesman;
  Branch? salesBranch;
  PaymentMethod? salesPayment;
  ItemCategory? salesCategory;
  SalesGroupBy salesGroupBy = SalesGroupBy.none;

  void setSalesPreset(String preset, {bool notify = true}) {
    final today = dateOnly(DateTime.now());
    salesPreset = preset;
    salesTo = today;
    switch (preset) {
      case 'Today':
        salesFrom = today;
      case 'Last 7 days':
        salesFrom = DateTime(today.year, today.month, today.day - 6);
      case 'This month':
        salesFrom = DateTime(today.year, today.month);
      default:
        salesFrom = DateTime(today.year, today.month, today.day - 89);
    }
    if (notify) notifyListeners();
  }

  void setSalesDates({DateTime? from, DateTime? to}) {
    salesPreset = null;
    salesFrom = from;
    salesTo = to;
    notifyListeners();
  }

  void setSalesSalesman(String? value) {
    salesSalesman = value;
    notifyListeners();
  }

  void setSalesBranch(Branch? value) {
    salesBranch = value;
    notifyListeners();
  }

  void setSalesPayment(PaymentMethod? value) {
    salesPayment = value;
    notifyListeners();
  }

  void setSalesCategory(ItemCategory? value) {
    salesCategory = value;
    notifyListeners();
  }

  void setSalesGroupBy(SalesGroupBy value) {
    salesGroupBy = value;
    notifyListeners();
  }

  List<Sale> get filteredSales {
    return sales.where((s) {
      if (salesFrom != null && s.date.isBefore(salesFrom!)) return false;
      if (salesTo != null && s.date.isAfter(salesTo!)) return false;
      if (salesSalesman != null && s.salesman != salesSalesman) return false;
      if (salesBranch != null && s.branch != salesBranch) return false;
      if (salesPayment != null && s.paymentMethod != salesPayment) return false;
      if (salesCategory != null && s.category != salesCategory) return false;
      return true;
    }).toList();
  }
}
