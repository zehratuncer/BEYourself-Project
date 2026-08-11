import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quote_reminder/core/theme/app_colors.dart';
import 'package:quote_reminder/features/quote/presentation/pages/quote_form_page.dart';
import 'package:quote_reminder/features/quote/presentation/providers/quote_providers.dart';
import 'package:quote_reminder/features/settings/presentation/pages/settings_page.dart';

class QuoteDetailPage extends ConsumerWidget {
  const QuoteDetailPage({super.key, required this.quoteId});

  final String quoteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotes = ref.watch(quoteListProvider);
    final quoteList = quotes.where((q) => q.id == quoteId);
    final isDarkMode = ref.watch(isDarkModeProvider);

    if (quoteList.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: Text('Söz bulunamadı.')),
      );
    }

    final quote = quoteList.first;
    final cardBg = Theme.of(context).cardColor;
    final primaryTextColor = isDarkMode
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryTextColor = isDarkMode
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                            : (quote.mediaUrl!.contains('.mp4') ||
                                    quote.mediaUrl!.contains('.mov') ||
                                    quote.mediaUrl!.contains('video')
                                ? Container(
                                    height: 200,
                                    width: double.infinity,
                                    color: Colors.black87,
                                    child: const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.play_circle_fill,
                                            size: 64,
                                            color: Colors.white,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Video Oynat',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
                    const SizedBox(height: 24),
                    Text(
                      '"${quote.text}"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alıntı kopyalandı!')),
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

