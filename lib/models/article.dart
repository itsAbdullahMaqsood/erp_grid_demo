import 'enums.dart';

/// A stock item. Money is whole rupees, weight is milligrams.
class Article {
  Article({
    required this.articleCode,
    required this.barcode,
    required this.category,
    required this.subCategory,
    required this.description,
    required this.purity,
    required this.grossWeightMg,
    required this.stoneWeightMg,
    required this.makingCharges,
    required this.stoneCharges,
    required this.costPrice,
    required this.tagPrice,
    required this.status,
    required this.supplier,
    required this.branch,
    required this.dateAdded,
  });

  final String articleCode;
  String barcode;
  ItemCategory category;
  String subCategory;
  String description;
  String purity;
  int grossWeightMg;
  int stoneWeightMg;
  int makingCharges;
  int stoneCharges;
  int costPrice;
  int tagPrice;
  ArticleStatus status;
  String supplier;
  Branch branch;
  DateTime dateAdded;

  int get netWeightMg => grossWeightMg - stoneWeightMg;
}
