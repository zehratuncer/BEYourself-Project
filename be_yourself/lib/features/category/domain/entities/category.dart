class Category {
  const Category({
    required this.id,
    required this.name,
    required this.quoteCount,
    this.iconName,
    this.colorHex,
  });

  final String id;
  final String name;
  final int quoteCount;
  final String? iconName;
  final String? colorHex;
}
