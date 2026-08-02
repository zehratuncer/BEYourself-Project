class Quote {
  const Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.categoryName,
    required this.createdAt,
    this.isFavorite = false,
    this.mediaUrl,
  });

  final String id;
  final String text;
  final String author;
  final String categoryName;
  final DateTime createdAt;
  final bool isFavorite;
  final String? mediaUrl;

  Quote copyWith({
    String? id,
    String? text,
    String? author,
    String? categoryName,
    DateTime? createdAt,
    bool? isFavorite,
    String? mediaUrl,
  }) {
    return Quote(
      id: id ?? this.id,
      text: text ?? this.text,
      author: author ?? this.author,
      categoryName: categoryName ?? this.categoryName,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      mediaUrl: mediaUrl ?? this.mediaUrl,
    );
  }
}
