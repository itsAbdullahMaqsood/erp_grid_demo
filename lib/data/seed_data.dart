import 'dart:math';

import '../models/article.dart';
import '../models/enums.dart';
import '../models/sale.dart';

const List<String> seedSuppliers = <String>[
  'Hanif Jewellers',
  'Al-Madina Gold Traders',
  'Saleem & Sons Bullion',
  'Chaudhry Gems Lahore',
  'Rehman Diamond House',
  'Qureshi Silver Works',
  'Butt Brothers Jewellers',
  'Sheikh Zaveri Wholesale',
];

const List<String> seedSalesmen = <String>[
  'Ahmed Raza',
  'Bilal Hussain',
  'Usman Tariq',
  'Hamza Sheikh',
  'Imran Qureshi',
  'Fahad Malik',
];

const List<String> _firstNames = <String>[
  'Ayesha', 'Fatima', 'Zainab', 'Maryam', 'Hira', 'Sana', 'Nadia', 'Rabia',
  'Sadia', 'Amna', 'Mahnoor', 'Iqra', 'Kiran', 'Saima', 'Bushra', 'Farah',
  'Ali', 'Hassan', 'Omar', 'Zeeshan', 'Kamran', 'Asad', 'Faisal', 'Shahid',
  'Tariq', 'Naveed', 'Junaid', 'Waqas', 'Adnan', 'Salman',
];

const List<String> _lastNames = <String>[
  'Khan', 'Ahmed', 'Malik', 'Butt', 'Sheikh', 'Qureshi', 'Chaudhry', 'Siddiqui',
  'Hussain', 'Iqbal', 'Raza', 'Mirza', 'Baig', 'Javed', 'Aslam', 'Farooqi',
  'Abbasi', 'Rana', 'Dar', 'Memon',
];

const Map<String, String> subCategoryCodes = <String, String>{
  'Ring': 'R',
  'Bangle': 'B',
  'Necklace': 'N',
  'Bracelet': 'L',
  'Earrings': 'E',
  'Pendant': 'P',
  'Chain': 'C',
  'Bridal Set': 'S',
};

/// Gross weight range in milligrams per sub category.
const Map<String, List<int>> _weightRangeMg = <String, List<int>>{
  'Ring': <int>[2800, 8500],
  'Bangle': <int>[9000, 30000],
  'Necklace': <int>[18000, 60000],
  'Bracelet': <int>[7000, 24000],
  'Earrings': <int>[3500, 12000],
  'Pendant': <int>[2000, 8000],
  'Chain': <int>[6000, 25000],
  'Bridal Set': <int>[55000, 140000],
};

const Map<String, List<String>> _descriptions = <String, List<String>>{
  'Ring': <String>[
    'Ladies ring, floral design',
    'Gents ring, plain band',
    'Ladies ring, solitaire setting',
    'Engagement ring, classic',
    'Ladies ring, filigree work',
    'Gents ring, square top',
  ],
  'Bangle': <String>[
    'Bangle pair, plain polish',
    'Bangle, kundan work',
    'Kara, heavy engraved',
    'Bangle set of 4, machine cut',
    'Bangle, antique finish',
  ],
  'Necklace': <String>[
    'Necklace, choker style',
    'Necklace, long rani haar',
    'Necklace, light party wear',
    'Necklace, temple design',
    'Necklace, beaded strand',
  ],
  'Bracelet': <String>[
    'Ladies bracelet, link chain',
    'Gents bracelet, curb link',
    'Bracelet, charm style',
    'Bracelet, tennis style',
  ],
  'Earrings': <String>[
    'Earrings, jhumka style',
    'Earrings, studs',
    'Earrings, chandbali',
    'Earrings, drop design',
    'Earrings, hoops',
  ],
  'Pendant': <String>[
    'Pendant, Allah calligraphy',
    'Pendant, heart shape',
    'Pendant, initial letter',
    'Pendant, round halo',
  ],
  'Chain': <String>[
    'Chain, rope design 18 inch',
    'Chain, box link 20 inch',
    'Chain, figaro 22 inch',
    'Chain, fine cable 16 inch',
  ],
  'Bridal Set': <String>[
    'Bridal set, necklace with earrings and tikka',
    'Bridal set, kundan with matha patti',
    'Bridal set, polki full set',
    'Bridal set, traditional jadau',
  ],
};

/// Metal rate in PKR per gram of net weight.
int ratePerGram(ItemCategory category, String purity) {
  switch (purity) {
    case '24K':
      return 30000;
    case '22K':
      return 27500;
    case '21K':
      return 26250;
    case '18K':
      return 22500;
    case '925':
      return 350;
    case '950':
      return 9500;
  }
  return category == ItemCategory.silver ? 350 : 27500;
}

/// EAN-13 style barcode for a serial number.
String barcodeFor(int serial) {
  final body = '890100${serial.toString().padLeft(6, '0')}';
  var sum = 0;
  for (var i = 0; i < body.length; i++) {
    final d = body.codeUnitAt(i) - 48;
    sum += i.isEven ? d : d * 3;
  }
  return '$body${(10 - sum % 10) % 10}';
}

String articleCodeFor(
  ItemCategory category,
  String subCategory,
  String purity,
  int serial,
) {
  return '${category.code}${subCategoryCodes[subCategory] ?? 'X'}-$purity-'
      '${serial.toString().padLeft(5, '0')}';
}

int _roundTo(int value, int step) => ((value + step ~/ 2) ~/ step) * step;

class SeedData {
  SeedData(this.articles, this.sales);
  final List<Article> articles;
  final List<Sale> sales;
}

/// Builds the demo data. Uses a fixed seed so every run looks the same.
/// Dates are relative to [today].
SeedData generateSeedData({DateTime? today}) {
  final rnd = Random(42);
  final now = today ?? DateTime.now();
  final day0 = DateTime(now.year, now.month, now.day);

  // 60% gold, 20% diamond, 15% silver, 5% platinum.
  final categories = <ItemCategory>[
    ...List<ItemCategory>.filled(360, ItemCategory.gold),
    ...List<ItemCategory>.filled(120, ItemCategory.diamond),
    ...List<ItemCategory>.filled(90, ItemCategory.silver),
    ...List<ItemCategory>.filled(30, ItemCategory.platinum),
  ]..shuffle(rnd);

  // 250 sold articles are needed to back the 250 sales.
  final statuses = <ArticleStatus>[
    ...List<ArticleStatus>.filled(300, ArticleStatus.available),
    ...List<ArticleStatus>.filled(250, ArticleStatus.sold),
    ...List<ArticleStatus>.filled(20, ArticleStatus.promotional),
    ...List<ArticleStatus>.filled(8, ArticleStatus.borrowed),
    ...List<ArticleStatus>.filled(8, ArticleStatus.melted),
    ...List<ArticleStatus>.filled(8, ArticleStatus.returnedToSupplier),
    ...List<ArticleStatus>.filled(6, ArticleStatus.gifted),
  ]..shuffle(rnd);

  final articles = <Article>[];
  for (var i = 0; i < 600; i++) {
    final serial = i + 1;
    final category = categories[i];
    final String subCategory;
    if (category == ItemCategory.platinum) {
      subCategory = const <String>['Ring', 'Ring', 'Pendant', 'Chain', 'Bracelet'][rnd.nextInt(5)];
    } else if (category == ItemCategory.silver) {
      subCategory = subCategories[rnd.nextInt(7)];
    } else {
      // Rings and earrings are the most common stock lines.
      final roll = rnd.nextInt(100);
      subCategory = roll < 24
          ? 'Ring'
          : roll < 40
              ? 'Earrings'
              : roll < 54
                  ? 'Bangle'
                  : roll < 66
                      ? 'Necklace'
                      : roll < 77
                          ? 'Pendant'
                          : roll < 87
                              ? 'Chain'
                              : roll < 95
                                  ? 'Bracelet'
                                  : 'Bridal Set';
    }

    final String purity;
    switch (category) {
      case ItemCategory.gold:
        final roll = rnd.nextInt(100);
        purity = roll < 55
            ? '22K'
            : roll < 80
                ? '21K'
                : roll < 93
                    ? '18K'
                    : '24K';
      case ItemCategory.diamond:
        purity = '18K';
      case ItemCategory.silver:
        purity = '925';
      case ItemCategory.platinum:
        purity = '950';
    }

    final range = _weightRangeMg[subCategory]!;
    var gross = range[0] + rnd.nextInt(range[1] - range[0]);
    if (category == ItemCategory.silver) gross = gross * 3 ~/ 2;
    if (category == ItemCategory.diamond) gross = gross * 2 ~/ 3;
    gross = _roundTo(gross, 10);

    int stone;
    if (category == ItemCategory.diamond) {
      stone = gross * (3 + rnd.nextInt(8)) ~/ 100;
    } else if (rnd.nextInt(100) < 45) {
      stone = gross * (2 + rnd.nextInt(12)) ~/ 100;
    } else {
      stone = 0;
    }
    stone = _roundTo(stone, 10);
    final net = gross - stone;

    final rate = ratePerGram(category, purity);
    final metalValue = net * rate ~/ 1000;

    final int making;
    final int stoneCharges;
    switch (category) {
      case ItemCategory.gold:
        making = _roundTo(net * (1800 + rnd.nextInt(1400)) ~/ 1000, 500) + 1500;
        stoneCharges = stone == 0 ? 0 : _roundTo(stone * (18 + rnd.nextInt(20)), 500) + 500;
      case ItemCategory.diamond:
        making = _roundTo(net * (3500 + rnd.nextInt(2500)) ~/ 1000, 500) + 5000;
        stoneCharges = _roundTo(stone * (450 + rnd.nextInt(900)), 1000) + 20000;
      case ItemCategory.silver:
        making = _roundTo(net * (120 + rnd.nextInt(160)) ~/ 1000, 100) + 800;
        stoneCharges = stone == 0 ? 0 : _roundTo(stone * (2 + rnd.nextInt(3)), 100) + 200;
      case ItemCategory.platinum:
        making = _roundTo(net * (2500 + rnd.nextInt(2000)) ~/ 1000, 500) + 4000;
        stoneCharges = stone == 0 ? 0 : _roundTo(stone * (60 + rnd.nextInt(80)), 500) + 2000;
    }

    final cost = _roundTo(metalValue + making + stoneCharges, 100);
    // Tag price is 12% to 25% above cost.
    final markup = 112 + rnd.nextInt(14);
    final tag = _roundTo(cost * markup ~/ 100, cost > 20000 ? 500 : 50);

    final descriptions = _descriptions[subCategory]!;
    articles.add(
      Article(
        articleCode: articleCodeFor(category, subCategory, purity, serial),
        barcode: barcodeFor(serial),
        category: category,
        subCategory: subCategory,
        description: descriptions[rnd.nextInt(descriptions.length)],
        purity: purity,
        grossWeightMg: gross,
        stoneWeightMg: stone,
        makingCharges: making,
        stoneCharges: stoneCharges,
        costPrice: cost,
        tagPrice: tag,
        status: statuses[i],
        supplier: seedSuppliers[rnd.nextInt(seedSuppliers.length)],
        branch: rnd.nextInt(100) < 62 ? Branch.main : Branch.branch2,
        dateAdded: day0.subtract(Duration(days: 1 + rnd.nextInt(364))),
      ),
    );
  }

  // One sale per sold article, spread over the last 90 days.
  final drafts = <_SaleDraft>[];
  for (final article in articles) {
    if (article.status != ArticleStatus.sold) continue;
    final daysAgo = rnd.nextInt(90);
    final date = DateTime(day0.year, day0.month, day0.day - daysAgo);
    if (article.dateAdded.isAfter(date)) {
      article.dateAdded = DateTime(date.year, date.month, date.day - 3 - rnd.nextInt(60));
    }

    // Most sales get a small discount. A few are clearance sales below cost.
    final roll = rnd.nextInt(100);
    final int discountPercent = roll < 30
        ? 0
        : roll < 92
            ? 1 + rnd.nextInt(8)
            : 14 + rnd.nextInt(12);
    final discount = _roundTo(
      article.tagPrice * discountPercent ~/ 100,
      article.tagPrice > 20000 ? 500 : 50,
    );
    final payRoll = rnd.nextInt(100);
    drafts.add(
      _SaleDraft(
        article: article,
        date: date,
        discount: discount,
        customer:
            '${_firstNames[rnd.nextInt(_firstNames.length)]} '
            '${_lastNames[rnd.nextInt(_lastNames.length)]}',
        salesman: seedSalesmen[rnd.nextInt(seedSalesmen.length)],
        payment: payRoll < 45
            ? PaymentMethod.cash
            : payRoll < 72
                ? PaymentMethod.creditCard
                : payRoll < 88
                    ? PaymentMethod.online
                    : PaymentMethod.cheque,
      ),
    );
  }
  drafts.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    return byDate != 0 ? byDate : a.article.articleCode.compareTo(b.article.articleCode);
  });

  final sales = <Sale>[];
  for (var i = 0; i < drafts.length; i++) {
    final d = drafts[i];
    sales.add(
      Sale(
        invoiceNo: 'INV-${d.date.year}-${(i + 1).toString().padLeft(5, '0')}',
        date: d.date,
        articleCode: d.article.articleCode,
        category: d.article.category,
        customerName: d.customer,
        salesman: d.salesman,
        branch: d.article.branch,
        costPrice: d.article.costPrice,
        salePrice: d.article.tagPrice - d.discount,
        discount: d.discount,
        paymentMethod: d.payment,
      ),
    );
  }

  return SeedData(articles, sales);
}

class _SaleDraft {
  _SaleDraft({
    required this.article,
    required this.date,
    required this.discount,
    required this.customer,
    required this.salesman,
    required this.payment,
  });
  final Article article;
  final DateTime date;
  final int discount;
  final String customer;
  final String salesman;
  final PaymentMethod payment;
}
