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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quoteCount': quoteCount,
      'iconName': iconName,
      'colorHex': colorHex,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quoteCount: json['quoteCount'] as int? ?? 0,
      iconName: json['iconName'] as String?,
      colorHex: json['colorHex'] as String?,
    );
  }
}

