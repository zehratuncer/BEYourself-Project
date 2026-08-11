class Quote {
  const Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.categoryName,
    required this.createdAt,
    this.isFavorite = false,
    this.mediaUrl,
    this.shortText,
  });

  final String id;
  final String text;
  final String author;
  final String categoryName;
  final DateTime createdAt;
  final bool isFavorite;
  final String? mediaUrl;
  final String? shortText;

  String get displayText =>
      (shortText != null && shortText!.isNotEmpty) ? shortText! : text;

  Quote copyWith({
    String? id,
    String? text,
    String? author,
    String? categoryName,
    DateTime? createdAt,
    bool? isFavorite,
    String? mediaUrl,
    String? shortText,
  }) {
    return Quote(
      id: id ?? this.id,
      text: text ?? this.text,
      author: author ?? this.author,
      categoryName: categoryName ?? this.categoryName,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      shortText: shortText ?? this.shortText,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'author': author,
      'categoryName': categoryName,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
      'mediaUrl': mediaUrl,
      'shortText': shortText,
    };
  }

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      author: json['author'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? 'Genel',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      mediaUrl: json['mediaUrl'] as String?,
      shortText: json['shortText'] as String?,
    );
  }
}
