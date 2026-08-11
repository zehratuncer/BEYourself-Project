import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quote_reminder/core/theme/app_colors.dart';
import 'package:quote_reminder/features/home/presentation/widgets/quote_card.dart';
import 'package:quote_reminder/features/quote/presentation/providers/quote_providers.dart';
import 'package:quote_reminder/features/settings/presentation/pages/settings_page.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteQuoteListProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    final primaryTextColor = isDarkMode
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryTextColor = isDarkMode
        ? AppColors.darkTextSecondary
        : const Color(0xFF5E6C84);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'Favorilerim',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode
                      ? AppColors.primaryBlueLight
                      : AppColors.primaryBlue,
                ),
              ),
            ),
            Expanded(
              child: favorites.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? AppColors.primaryBlueLight.withAlpha(25)
                                    : AppColors.primaryBlue.withAlpha(15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.favorite_border,
                                size: 56,
                                color: isDarkMode
                                    ? AppColors.primaryBlueLight
                                    : AppColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Henüz favori sözünüz yok',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sevdiğiniz alıntıların yanındaki kalp ikonuna basarak buraya ekleyebilirsiniz.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: QuoteCard(quote: favorites[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

