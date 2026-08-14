import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:be_yourself/core/theme/app_colors.dart';
import 'package:be_yourself/features/media/services/media_storage_service.dart';
import 'package:be_yourself/features/profile/presentation/providers/profile_providers.dart';
import 'package:be_yourself/features/quote/presentation/providers/quote_providers.dart';
import 'package:be_yourself/features/settings/presentation/pages/settings_page.dart';

class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ProfileSettingsPage> createState() =>
      _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _mottoController;
  final ImagePicker _picker = ImagePicker();

  static const List<String> _presetAvatars = [
    '💫',
    '🌟',
    '🦋',
    '🌸',
    '🎨',
    '🚀',
    '📚',
    '🌿',
    '✨',
    '☕',
    '🦁',
    '🔮',
    '💡',
    '💎',
    '🕊️',
    '🍀',
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameController = TextEditingController(text: profile.name);
    _mottoController = TextEditingController(text: profile.motto);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mottoController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        final permanentPath = await MediaStorageService.instance.saveAvatarXFileLocally(
          image,
        );
        ref.read(profileProvider.notifier).setAvatarPath(permanentPath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil fotoğrafı güncellendi! 📸'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.primaryBlue,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf seçilemedi: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _saveProfile() {
    final name = _nameController.text.trim();
    final motto = _mottoController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir isim giriniz.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    ref.read(profileProvider.notifier).updateName(name);
    ref.read(profileProvider.notifier).updateMotto(motto);

    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil bilgileri kaydedildi! ✨'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryBlue,
      ),
    );

    Navigator.of(context).pop();
  }

  void _confirmResetProfile() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profili Sıfırla'),
        content: const Text(
          'Profil bilgileriniz varsayılan ayarlara döndürülecektir. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(profileProvider.notifier).resetToDefaults();
              final defaultProfile = ref.read(profileProvider);
              _nameController.text = defaultProfile.name;
              _mottoController.text = defaultProfile.motto;
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profil varsayılan değerlere sıfırlandı.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final quotes = ref.watch(quoteListProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    final cardBgColor = Theme.of(context).cardColor;
    final primaryTextColor = isDarkMode
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryTextColor = isDarkMode
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final resolvedAvatarFile = profile.avatarPath != null && profile.avatarPath!.isNotEmpty
        ? MediaStorageService.instance.resolveLocalFileSync(profile.avatarPath!)
        : null;
    final hasCustomPhoto =
        resolvedAvatarFile != null && resolvedAvatarFile.existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil Ayarları',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Kaydet',
            icon: const Icon(Icons.check_rounded),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar & Photo Header
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryBlue.withAlpha(isDarkMode ? 40 : 25),
                            border: Border.all(
                              color: isDarkMode
                                  ? AppColors.primaryBlueLight
                                  : AppColors.primaryBlue,
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: hasCustomPhoto
                                ? Image.file(
                                    resolvedAvatarFile,
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                  )
                                : Center(
                                    child: Text(
                                      profile.avatarEmoji,
                                      style: const TextStyle(fontSize: 44),
                                    ),
                                  ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _pickImageFromGallery,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Galeriden Fotoğraf Seç'),
                      style: TextButton.styleFrom(
                        foregroundColor: isDarkMode
                            ? AppColors.primaryBlueLight
                            : AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Avatar Emojis Selector
              _SectionTitle(title: 'HAZIR İLHAM AVATARLARI', isDarkMode: isDarkMode),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: _presetAvatars.map((emoji) {
                    final isSelected = !hasCustomPhoto && profile.avatarEmoji == emoji;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(profileProvider.notifier).setAvatarEmoji(emoji);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.primaryBlue.withAlpha(isDarkMode ? 80 : 40)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Profile Name and Motto Fields
              _SectionTitle(title: 'KİŞİSEL BİLGİLER', isDarkMode: isDarkMode),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                      ),
                      decoration: InputDecoration(
                        labelText: 'İsim Soyisim',
                        labelStyle: TextStyle(color: secondaryTextColor),
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onSubmitted: (_) => _saveProfile(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _mottoController,
                      maxLines: 2,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: primaryTextColor,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Kişisel İlham Mottosu / Yaşam Felsefen',
                        hintText: 'Örn: Kendine inan, yapabileceklerinin sınırı yoktur.',
                        labelStyle: TextStyle(color: secondaryTextColor),
                        prefixIcon: const Icon(Icons.format_quote_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Notification Greeting Style
              _SectionTitle(title: 'BİLDİRİM HİTAP ŞEKLİ', isDarkMode: isDarkMode),
              Material(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: RadioGroup<String>(
                  groupValue: profile.greetingStyle,
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(profileProvider.notifier).setGreetingStyle(val);
                    }
                  },
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: Text(
                          'Samimi',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                        subtitle: Text(
                          'Örn: "Günaydın ${profile.name} ✨"',
                          style: TextStyle(color: secondaryTextColor),
                        ),
                        value: 'friendly',
                        activeColor: AppColors.primaryBlue,
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        title: Text(
                          'Motive Edici',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                        subtitle: Text(
                          'Örn: "Bugün harika bir gün olacak ${profile.name} 🚀"',
                          style: TextStyle(color: secondaryTextColor),
                        ),
                        value: 'motivational',
                        activeColor: AppColors.primaryBlue,
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        title: Text(
                          'Sade / Klasik',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                        subtitle: Text(
                          'Örn: "Günün Alıntısı 💫"',
                          style: TextStyle(color: secondaryTextColor),
                        ),
                        value: 'classic',
                        activeColor: AppColors.primaryBlue,
                      ),
                    ],
                  ),
                ),
                ),
              ),

              const SizedBox(height: 24),

              // Stats and Account Summary
              _SectionTitle(title: 'HESAP & VERİ ÖZETİ', isDarkMode: isDarkMode),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.format_quote_rounded,
                            label: 'Kayıtlı Alıntı',
                            value: '${quotes.length}',
                            isDarkMode: isDarkMode,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.favorite_rounded,
                            label: 'Favoriler',
                            value: '${quotes.where((q) => q.isFavorite).length}',
                            isDarkMode: isDarkMode,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.restore_rounded, color: Colors.redAccent),
                        label: const Text(
                          'Profil Bilgilerini Sıfırla',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _confirmResetProfile,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save Button at bottom
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text(
                    'Değişiklikleri Kaydet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _saveProfile,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.isDarkMode});
  final String title;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: isDarkMode
              ? AppColors.darkTextSecondary
              : const Color(0xFF6B7280),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDarkMode,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black.withAlpha(40)
            : AppColors.primaryBlue.withAlpha(12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withAlpha(15)
              : AppColors.primaryBlue.withAlpha(25),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDarkMode
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDarkMode
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
