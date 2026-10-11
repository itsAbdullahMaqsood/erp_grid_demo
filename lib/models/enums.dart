enum ItemCategory {
  gold('Gold', 'G'),
  diamond('Diamond', 'D'),
  silver('Silver', 'S'),
  platinum('Platinum', 'P');

  const ItemCategory(this.label, this.code);
  final String label;
  final String code;

  static ItemCategory? tryParse(String text) {
    final t = text.trim().toLowerCase();
    for (final c in values) {
      if (c.label.toLowerCase() == t) return c;
    }
    return null;
  }
}

enum ArticleStatus {
  available('Available'),
  promotional('Promotional'),
  sold('Sold'),
  borrowed('Borrowed'),
  melted('Melted'),
  returnedToSupplier('Returned to Supplier'),
  gifted('Gifted');

  const ArticleStatus(this.label);
  final String label;
}

/// Statuses hidden by the Stock status filter on startup. The status list has
/// no "Deleted" entry, so nothing is hidden by default and the table opens on
/// all 600 articles. Add e.g. melted / returnedToSupplier here to hide them.
const Set<ArticleStatus> defaultHiddenStatuses = <ArticleStatus>{};

enum Branch {
  main('Main Branch'),
  branch2('Branch 2');

  const Branch(this.label);
  final String label;

  static Branch? tryParse(String text) {
    final t = text.trim().toLowerCase();
    for (final b in values) {
      if (b.label.toLowerCase() == t) return b;
    }
    return null;
  }
}

enum PaymentMethod {
  cash('Cash'),
  creditCard('Credit Card'),
  cheque('Cheque'),
  online('Online');

  const PaymentMethod(this.label);
  final String label;
}

enum SalesGroupBy {
  none('None'),
  salesman('Salesman'),
  category('Category'),
  day('Day');

  const SalesGroupBy(this.label);
  final String label;
}

const List<String> subCategories = <String>[
  'Ring',
  'Bangle',
  'Necklace',
  'Bracelet',
  'Earrings',
  'Pendant',
  'Chain',
  'Bridal Set',
];
