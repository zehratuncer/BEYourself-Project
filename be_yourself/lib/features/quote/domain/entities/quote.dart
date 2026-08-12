class Quote {
  const Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.categoryName,
    required this.createdAt,
    this.isFavorite = false,
    this.mediaUrl,
    this.mediaUrls,
    this.shortText,
  });

  final String id;
  final String text;
  final String author;
  final String categoryName;
  final DateTime createdAt;
  final bool isFavorite;
  final String? mediaUrl;
  final List<String>? mediaUrls;
  final String? shortText;

  String get displayText =>
      (shortText != null && shortText!.isNotEmpty) ? shortText! : text;

  /// Returns all available media items (from mediaUrls or fallback to mediaUrl)
  List<String> get allMediaUrls {
    if (mediaUrls != null && mediaUrls!.isNotEmpty) {
      return mediaUrls!;
    }
    if (mediaUrl != null && mediaUrl!.isNotEmpty) {
      return [mediaUrl!];
    }
    return const [];
  }

  Quote copyWith({
    String? id,
    String? text,
    String? author,
    String? categoryName,
    DateTime? createdAt,
    bool? isFavorite,
    String? mediaUrl,
    List<String>? mediaUrls,
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
      mediaUrls: mediaUrls ?? this.mediaUrls,
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
      'mediaUrl': mediaUrl ?? (mediaUrls?.isNotEmpty == true ? mediaUrls!.first : null),
      'mediaUrls': mediaUrls,
      'shortText': shortText,
    };
  }

  factory Quote.fromJson(Map<String, dynamic> json) {
    List<String>? parsedMediaUrls;
    if (json['mediaUrls'] != null) {
      parsedMediaUrls = (json['mediaUrls'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList();
    }
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
      mediaUrls: parsedMediaUrls,
      shortText: json['shortText'] as String?,
    );
  }
}
