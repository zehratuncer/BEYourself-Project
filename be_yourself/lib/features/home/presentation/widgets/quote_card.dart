import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:be_yourself/core/theme/app_colors.dart';
import 'package:be_yourself/features/quote/domain/entities/quote.dart';
import 'package:be_yourself/features/quote/presentation/pages/quote_form_page.dart';
import 'package:be_yourself/features/quote/presentation/providers/quote_providers.dart';
import 'package:be_yourself/features/settings/presentation/pages/settings_page.dart';

class QuoteCard extends ConsumerWidget {
  const QuoteCard({
    super.key,
    required this.quote,
    this.onTap,
  });

  final Quote quote;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    final cardBg = Theme.of(context).cardColor;
    final primaryTextColor = isDarkMode
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryTextColor = isDarkMode
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
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
                  : const Color(0xFF60A5FA).withAlpha(15),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '"${quote.displayText}"',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: primaryTextColor,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote.author,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? AppColors.primaryBlueLight.withAlpha(30)
                            : AppColors.primaryBlue.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        quote.categoryName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? AppColors.primaryBlueLight
                              : AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        quote.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: quote.isFavorite
                            ? (isDarkMode
                                ? AppColors.primaryBlueLight
                                : AppColors.primaryBlue)
                            : (isDarkMode
                                ? AppColors.darkTextSecondary
                                : const Color(0xFF717783)),
                        size: 22,
                      ),
                      onPressed: () {
                        ref
                            .read(quoteListProvider.notifier)
                            .toggleFavorite(quote.id);
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: isDarkMode
                            ? AppColors.darkTextSecondary
                            : const Color(0xFF717783),
                        size: 22,
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  QuoteFormPage(initialQuote: quote),
                            ),
                          );
                        } else if (value == 'delete') {
                          ref
                              .read(quoteListProvider.notifier)
                              .deleteQuote(quote.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Alıntı silindi.'),
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit,
                                  size: 20,
                                  color: isDarkMode
                                      ? AppColors.darkTextSecondary
                                      : const Color(0xFF717783)),
                              const SizedBox(width: 8),
                              const Text('Düzenle'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Sil', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

