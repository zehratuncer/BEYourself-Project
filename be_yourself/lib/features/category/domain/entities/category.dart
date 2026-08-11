class Category {
  const Category({
    required this.id,
    required this.name,
    this.quoteCount = 0,
    this.iconName,
    this.colorHex,
  });

  final String id;
  final String name;
  final int quoteCount;
  final String? iconName;
  final String? colorHex;

  Category copyWith({
    String? id,
    String? name,
    int? quoteCount,
    String? iconName,
    String? colorHex,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      quoteCount: quoteCount ?? this.quoteCount,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}

