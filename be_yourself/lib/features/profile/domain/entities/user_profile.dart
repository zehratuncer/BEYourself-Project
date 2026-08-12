class UserProfile {
  const UserProfile({
    required this.name,
    this.avatarPath,
    this.avatarEmoji = '💫',
    this.motto = 'Kendine inan, yapabileceklerinin sınırı yoktur.',
    this.greetingStyle = 'friendly', // 'friendly', 'motivational', 'classic'
  });

  final String name;
  final String? avatarPath;
  final String avatarEmoji;
  final String motto;
  final String greetingStyle;

  UserProfile copyWith({
    String? name,
    String? avatarPath,
    bool clearAvatarPath = false,
    String? avatarEmoji,
    String? motto,
    String? greetingStyle,
  }) {
    return UserProfile(
      name: name ?? this.name,
      avatarPath: clearAvatarPath ? null : (avatarPath ?? this.avatarPath),
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      motto: motto ?? this.motto,
      greetingStyle: greetingStyle ?? this.greetingStyle,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'avatarPath': avatarPath,
      'avatarEmoji': avatarEmoji,
      'motto': motto,
      'greetingStyle': greetingStyle,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? 'Zehra Tuncer',
      avatarPath: json['avatarPath'] as String?,
      avatarEmoji: json['avatarEmoji'] as String? ?? '💫',
      motto: json['motto'] as String? ??
          'Kendine inan, yapabileceklerinin sınırı yoktur.',
      greetingStyle: json['greetingStyle'] as String? ?? 'friendly',
    );
  }

  static const UserProfile defaultProfile = UserProfile(
    name: 'Zehra Tuncer',
    avatarPath: null,
    avatarEmoji: '💫',
    motto: 'Kendine inan, yapabileceklerinin sınırı yoktur.',
    greetingStyle: 'friendly',
  );
}
