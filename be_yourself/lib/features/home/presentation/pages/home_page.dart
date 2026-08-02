import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quote_reminder/core/theme/app_colors.dart';
import 'package:quote_reminder/features/category/presentation/providers/category_providers.dart';
import 'package:quote_reminder/features/home/presentation/widgets/quote_card.dart';
import 'package:quote_reminder/features/quote/presentation/providers/quote_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key, this.onAddQuoteTap, this.onQuoteTap});

  final VoidCallback? onAddQuoteTap;
  final Function(String quoteId)? onQuoteTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredQuotes = ref.watch(filteredQuoteListProvider);
    final quoteOfDay = ref.watch(quoteOfDayProvider);
    final categories = ref.watch(categoryListProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
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
                        const Text(
                          'BeYourself',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, color: Color(0xFF414751)),
                      onPressed: () {},
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
                    const Text(
                      'Merhaba, Can',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111C2D),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (val) {
                        ref.read(searchQueryProvider.notifier).state = val;
                      },
                      decoration: InputDecoration(
                        hintText: 'Ne aramak istersin?',
                        hintStyle: const TextStyle(
                          color: Color(0xFF717783),
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF717783),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF0F3FF),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFEBF3FF),
                        Color(0xFFD8E3FB),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF60A5FA).withAlpha(20),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GÜNÜN ALINTISI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '"${quoteOfDay.text}"',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111C2D),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '— ${quoteOfDay.author}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF414751),
                        ),
                      ),
                    ],
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
                  ? const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'Aradığınız kıstaslara uygun söz bulunamadı.',
                            style: TextStyle(
                              color: Color(0xFF5E6C84),
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
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryBlue.withAlpha(40),
        backgroundColor: const Color(0xFFF0F3FF),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primaryBlue : const Color(0xFF414751),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: false,
      ),
    );
  }
}
