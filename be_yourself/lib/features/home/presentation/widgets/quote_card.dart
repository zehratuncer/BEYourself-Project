import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quote_reminder/core/theme/app_colors.dart';
import 'package:quote_reminder/features/quote/domain/entities/quote.dart';
import 'package:quote_reminder/features/quote/presentation/providers/quote_providers.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF60A5FA).withAlpha(15),
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF111C2D),
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF414751),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        quote.categoryName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
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
                            ? AppColors.primaryBlue
                            : const Color(0xFF717783),
                        size: 22,
                      ),
                      onPressed: () {
                        ref
                            .read(quoteListProvider.notifier)
                            .toggleFavorite(quote.id);
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Color(0xFF717783),
                        size: 22,
                      ),
                      onPressed: () {
                        // Options menu
                      },
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
