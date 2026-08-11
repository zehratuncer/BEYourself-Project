import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:be_yourself/core/theme/app_colors.dart';
import 'package:be_yourself/features/quote/domain/entities/quote.dart';
import 'package:be_yourself/features/quote/presentation/pages/quote_form_page.dart';
import 'package:be_yourself/features/quote/presentation/providers/quote_providers.dart';
import 'package:be_yourself/features/settings/presentation/pages/settings_page.dart';
import 'package:be_yourself/shared/widgets/app_video_player.dart';

class QuoteDetailPage extends ConsumerWidget {
  const QuoteDetailPage({super.key, required this.quoteId});

  final String quoteId;

  bool _isVideoMedia(String? path) {
    if (path == null) return false;
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.contains('/reels/') ||
        lower.contains('video');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotes = ref.watch(quoteListProvider);
    final quoteList = quotes.where((q) => q.id == quoteId);
    final isDarkMode = ref.watch(isDarkModeProvider);

    final Quote quote;
    if (quoteList.isNotEmpty) {
      quote = quoteList.first;
    } else {
      quote = Quote(
        id: quoteId,
        text: 'Kendine inan, yapabileceklerinin sınırı yoktur.',
        author: 'Günün Alıntısı 💫',
        categoryName: 'Genel',
        createdAt: DateTime.now(),
      );
    }

    final cardBg = Theme.of(context).cardColor;
    final primaryTextColor = isDarkMode
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryTextColor = isDarkMode
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final isVideo = _isVideoMedia(quote.mediaUrl);
    final screenSize = MediaQuery.of(context).size;

    if (isVideo) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Immersive Reels Video Container (fills ~75% of screen height)
                Stack(
                  children: [
                    Container(
                      height: screenSize.height * 0.74,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        child: AppVideoPlayer(
                          videoPath: quote.mediaUrl!,
                          height: screenSize.height * 0.74,
                          borderRadius: 32,
                          autoPlay: true,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Top Floating Navigation Bar
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _FloatingCircleButton(
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(140),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withAlpha(30),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_offer_outlined,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  quote.categoryName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              _FloatingCircleButton(
                                icon: quote.isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                iconColor: quote.isFavorite
                                    ? Colors.redAccent
                                    : Colors.white,
                                onTap: () {
                                  ref
                                      .read(quoteListProvider.notifier)
                                      .toggleFavorite(quote.id);
                                },
                              ),
                              const SizedBox(width: 8),
                              _FloatingCircleButton(
                                icon: Icons.edit_outlined,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          QuoteFormPage(initialQuote: quote),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Bottom Scroll Indicator Overlay
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(120),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Açıklama için aşağı kaydırın',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Details & Caption Section (revealed on scroll)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Short Title / Başlık (if available)
                      if (quote.shortText != null &&
                          quote.shortText!.trim().isNotEmpty) ...[
                        Text(
                          quote.shortText!,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Divider(
                          color: isDarkMode
                              ? Colors.white12
                              : const Color(0xFFE2E8F0),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Full Caption / Quote Text
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: isDarkMode
                              ? Border.all(
                                  color: Colors.white.withAlpha(15),
                                  width: 1,
                                )
                              : Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode
                                  ? Colors.black.withAlpha(30)
                                  : Colors.black.withAlpha(6),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isDarkMode
                                            ? AppColors.primaryBlueLight
                                                .withAlpha(25)
                                            : AppColors.primaryBlue
                                                .withAlpha(20),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.person_rounded,
                                        size: 16,
                                        color: isDarkMode
                                            ? AppColors.primaryBlueLight
                                            : AppColors.primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      quote.author,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDarkMode
                                            ? AppColors.primaryBlueLight
                                            : AppColors.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: quote.text),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Alıntı metni panoya kopyalandı! 📋'),
                                        duration: Duration(milliseconds: 1200),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy_rounded, size: 14),
                                  label: const Text(
                                    'Kopyala',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: isDarkMode
                                        ? AppColors.primaryBlueLight
                                        : AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              quote.text,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: primaryTextColor,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Classic Card Layout for Photo or Text-Only Quotes
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode
              ? AppColors.primaryBlueLight
              : AppColors.primaryBlue,
        ),
        actions: [
          IconButton(
            icon: Icon(
              quote.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: quote.isFavorite
                  ? (isDarkMode
                      ? AppColors.primaryBlueLight
                      : AppColors.primaryBlue)
                  : (isDarkMode
                      ? AppColors.darkTextSecondary
                      : Colors.grey),
            ),
            onPressed: () {
              ref.read(quoteListProvider.notifier).toggleFavorite(quote.id);
            },
          ),
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: isDarkMode
                  ? AppColors.primaryBlueLight
                  : AppColors.primaryBlue,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QuoteFormPage(initialQuote: quote),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(28),
                  border: isDarkMode
                      ? Border.all(
                          color: Colors.white.withAlpha(15),
                          width: 1,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withAlpha(40)
                          : const Color(0xFF60A5FA).withAlpha(20),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? AppColors.primaryBlueLight.withAlpha(30)
                            : AppColors.primaryBlue.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        quote.categoryName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? AppColors.primaryBlueLight
                              : AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    if (quote.mediaUrl != null &&
                        quote.mediaUrl!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: quote.mediaUrl!.startsWith('http')
                            ? Image.network(
                                quote.mediaUrl!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : (File(quote.mediaUrl!).existsSync()
                                ? Image.file(
                                    File(quote.mediaUrl!),
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    quote.mediaUrl!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                    ),
                                  )),
                      ),
                    ],
                    if (quote.shortText != null &&
                        quote.shortText!.trim().isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        quote.shortText!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode
                              ? AppColors.primaryBlueLight
                              : AppColors.primaryBlue,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      '"${quote.text}"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '— ${quote.author}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: quote.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alıntı kopyalandı! 📋')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Kopyala'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDarkMode
                          ? AppColors.primaryBlueLight
                          : AppColors.primaryBlue,
                      side: BorderSide(
                        color: isDarkMode
                            ? AppColors.primaryBlueLight.withAlpha(60)
                            : AppColors.primaryBlue.withAlpha(50),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingCircleButton extends StatelessWidget {
  const _FloatingCircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(140),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withAlpha(30),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
    );
  }
}
