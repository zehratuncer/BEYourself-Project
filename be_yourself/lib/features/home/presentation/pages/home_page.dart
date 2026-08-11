import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:be_yourself/core/theme/app_colors.dart';
import 'package:be_yourself/features/category/presentation/providers/category_providers.dart';
import 'package:be_yourself/features/home/presentation/widgets/quote_card.dart';
import 'package:be_yourself/features/quote/presentation/providers/quote_providers.dart';
import 'package:be_yourself/features/settings/presentation/pages/settings_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key, this.onAddQuoteTap, this.onQuoteTap});

  final VoidCallback? onAddQuoteTap;
  final Function(String quoteId)? onQuoteTap;

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      return 'Günaydınnn☀️';
    } else if (hour >= 12 && hour < 18) {
      return 'İyi Öğlenlerrr🤗';
    } else {
      return 'İyi Gecelerrr🌃';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredQuotes = ref.watch(filteredQuoteListProvider);
    final quoteOfDay = ref.watch(quoteOfDayProvider);
    final categories = ref.watch(categoryListProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    final primaryTextColor = isDarkMode
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryTextColor = isDarkMode
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header: Profile & App Title
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/app_bird_logo.png',
                          width: 42,
                          height: 42,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'BeYourself',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode
                                ? AppColors.primaryBlueLight
                                : AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Greeting & Search Input
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreetingMessage(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (val) {
                        ref.read(searchQueryProvider.notifier).state = val;
                      },
                      style: TextStyle(color: primaryTextColor),
                      decoration: InputDecoration(
                        hintText: 'Ne aramak istersiniz?',
                        hintStyle: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: secondaryTextColor,
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? AppColors.darkInputFill
                            : AppColors.lightInputFill,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quote of the Day Card
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: InkWell(
                  onTap: () => onQuoteTap?.call(quoteOfDay.id),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDarkMode
                            ? const [
                                Color(0xFF1E293B),
                                Color(0xFF0F172A),
                              ]
                            : const [
                                Color(0xFFEBF3FF),
                                Color(0xFFD8E3FB),
                              ],
                      ),
                      border: isDarkMode
                          ? Border.all(
                              color: AppColors.primaryBlueLight.withAlpha(40),
                              width: 1,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? Colors.black.withAlpha(50)
                              : const Color(0xFF60A5FA).withAlpha(20),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GÜNÜN ALINTISI',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode
                                ? AppColors.primaryBlueLight
                                : AppColors.primaryBlue,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '"${quoteOfDay.displayText}"',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '— ${quoteOfDay.author}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Category Chips Row
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _CategoryChip(
                      label: 'Hepsi',
                      isSelected: selectedCategory == 'Hepsi',
                      isDarkMode: isDarkMode,
                      onTap: () {
                        ref
                            .read(selectedCategoryFilterProvider.notifier)
                            .state = 'Hepsi';
                      },
                    ),
                    for (final category in categories)
                      _CategoryChip(
                        label: category.name,
                        isSelected: selectedCategory == category.name,
                        isDarkMode: isDarkMode,
                        onTap: () {
                          ref
                              .read(selectedCategoryFilterProvider.notifier)
                              .state = category.name;
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Quote List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: filteredQuotes.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'Aradığınız kıstaslara uygun söz bulunamadı.',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final quote = filteredQuotes[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: QuoteCard(
                              quote: quote,
                              onTap: () => onQuoteTap?.call(quote.id),
                            ),
                          );
                        },
                        childCount: filteredQuotes.length,
                      ),
                    ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.isDarkMode,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDarkMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor =
        isDarkMode ? AppColors.primaryBlueLight : AppColors.primaryBlue;
    final inactiveTextColor = isDarkMode
        ? AppColors.darkTextSecondary
        : const Color(0xFF414751);
    final bgColor = isDarkMode
        ? (isSelected
            ? AppColors.primaryBlue.withAlpha(50)
            : AppColors.darkCardBackground)
        : (isSelected
            ? AppColors.primaryBlue.withAlpha(40)
            : const Color(0xFFF0F3FF));

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: isDarkMode
            ? AppColors.primaryBlue.withAlpha(50)
            : AppColors.primaryBlue.withAlpha(40),
        backgroundColor: bgColor,
        labelStyle: TextStyle(
          color: isSelected ? activeColor : inactiveTextColor,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isDarkMode
              ? BorderSide(
                  color: isSelected
                      ? AppColors.primaryBlueLight.withAlpha(80)
                      : Colors.white.withAlpha(15),
                  width: 1,
                )
              : BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: false,
      ),
    );
  }
}

