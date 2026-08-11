import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:be_yourself/core/theme/app_colors.dart';
import 'package:be_yourself/features/category/presentation/providers/category_providers.dart';
import 'package:be_yourself/features/quote/domain/entities/quote.dart';
import 'package:be_yourself/features/quote/presentation/pages/quote_detail_page.dart';
import 'package:be_yourself/features/quote/presentation/pages/quote_form_page.dart';
import 'package:be_yourself/features/quote/presentation/providers/quote_providers.dart';
import 'package:be_yourself/features/quote/presentation/providers/random_quote_provider.dart';
import 'package:be_yourself/features/settings/presentation/pages/settings_page.dart';

class RandomQuoteModal extends ConsumerStatefulWidget {
  const RandomQuoteModal({super.key, this.initialCategory});

  final String? initialCategory;

  static Future<void> show(BuildContext context, {String? category}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RandomQuoteModal(initialCategory: category),
    );
  }

  @override
  ConsumerState<RandomQuoteModal> createState() => _RandomQuoteModalState();
}

class _RandomQuoteModalState extends ConsumerState<RandomQuoteModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _diceAnimController;
  late final Animation<double> _diceRotationAnimation;
  late final Animation<double> _diceScaleAnimation;

  @override
  void initState() {
    super.initState();
    _diceAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _diceRotationAnimation = Tween<double>(begin: 0.0, end: 2 * 3.14159265).animate(
      CurvedAnimation(
        parent: _diceAnimController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _diceScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_diceAnimController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _roll(initial: true);
    });
  }

  @override
  void dispose() {
    _diceAnimController.dispose();
    super.dispose();
  }

  void _roll({bool initial = false, String? category}) {
    HapticFeedback.mediumImpact();
    _diceAnimController.forward(from: 0.0);

    final allQuotes = ref.read(quoteListProvider);
    final targetCategory = category ?? widget.initialCategory;

    ref
        .read(randomQuoteNotifierProvider.notifier)
        .rollQuote(allQuotes, category: targetCategory);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final randomState = ref.watch(randomQuoteNotifierProvider);
    final allQuotes = ref.watch(quoteListProvider);
    final categories = ref.watch(categoryListProvider);

    // Live update quote from allQuotes if favorite or content changed
    final Quote? activeQuote;
    if (randomState.currentQuote != null) {
      activeQuote = allQuotes.firstWhere(
        (q) => q.id == randomState.currentQuote!.id,
        orElse: () => randomState.currentQuote!,
      );
    } else {
      activeQuote = null;
    }

    final primaryTextColor =
        isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final mediaQuery = MediaQuery.of(context);
    final modalHeight = mediaQuery.size.height * 0.78;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        height: modalHeight,
        decoration: BoxDecoration(
          color: isDarkMode
              ? const Color(0xFF0F172A).withAlpha(235)
              : Colors.white.withAlpha(245),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withAlpha(25)
                : AppColors.primaryBlue.withAlpha(20),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withAlpha(120)
                  : AppColors.primaryBlue.withAlpha(35),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Top Drag Handle & Header
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withAlpha(50)
                        : Colors.black.withAlpha(40),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Title Row with animated dice icon
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _diceAnimController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _diceScaleAnimation.value,
                          child: Transform.rotate(
                            angle: _diceRotationAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDarkMode
                                      ? const [
                                          Color(0xFF3B82F6),
                                          Color(0xFF1D4ED8),
                                        ]
                                      : const [
                                          Color(0xFF2563EB),
                                          Color(0xFF1D4ED8),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withAlpha(80),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.casino_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rastgele Keşfet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                            ),
                          ),
                          Text(
                            'Şansına ne çıkacak? Zar at ve gör!',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: secondaryTextColor,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 0.5),

              // Category Filter Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _FilterChipItem(
                      label: 'Hepsi',
                      isSelected: randomState.selectedCategory == 'Hepsi',
                      isDarkMode: isDarkMode,
                      onTap: () => _roll(category: 'Hepsi'),
                    ),
                    for (final category in categories)
                      _FilterChipItem(
                        label: category.name,
                        isSelected:
                            randomState.selectedCategory == category.name,
                        isDarkMode: isDarkMode,
                        onTap: () => _roll(category: category.name),
                      ),
                  ],
                ),
              ),

              // Main Content (Quote or Empty State)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.95, end: 1.0)
                              .animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: activeQuote == null || randomState.isEmpty
                        ? _buildEmptyState(context, isDarkMode, secondaryTextColor)
                        : _buildQuoteCard(
                            context,
                            activeQuote,
                            isDarkMode,
                            primaryTextColor,
                            secondaryTextColor,
                          ),
                  ),
                ),
              ),

              // Bottom Action Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF1E293B).withAlpha(150)
                      : const Color(0xFFF1F5F9),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    // Quick Action: Favorite
                    if (activeQuote != null) ...[
                      IconButton.filledTonal(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          ref
                              .read(quoteListProvider.notifier)
                              .toggleFavorite(activeQuote!.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                activeQuote.isFavorite
                                    ? 'Favorilerden çıkarıldı'
                                    : 'Favorilere eklendi ❤️',
                              ),
                              duration: const Duration(milliseconds: 1200),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: Icon(
                          activeQuote.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: activeQuote.isFavorite
                              ? Colors.redAccent
                              : (isDarkMode
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: activeQuote.isFavorite
                              ? Colors.redAccent.withAlpha(30)
                              : (isDarkMode
                                  ? Colors.white.withAlpha(15)
                                  : Colors.white),
                        ),
                        tooltip: 'Favori',
                      ),
                      const SizedBox(width: 8),

                      // Quick Action: Copy
                      IconButton.filledTonal(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Clipboard.setData(
                            ClipboardData(
                              text:
                                  '"${activeQuote!.text}" — ${activeQuote.author}',
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Alıntı panoya kopyalandı! 📋'),
                              duration: Duration(milliseconds: 1200),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.copy_rounded,
                          color: isDarkMode
                              ? AppColors.primaryBlueLight
                              : AppColors.primaryBlue,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: isDarkMode
                              ? Colors.white.withAlpha(15)
                              : Colors.white,
                        ),
                        tooltip: 'Kopyala',
                      ),
                      const SizedBox(width: 8),

                      // Quick Action: Detail
                      IconButton.filledTonal(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  QuoteDetailPage(quoteId: activeQuote!.id),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.open_in_new_rounded,
                          color: isDarkMode
                              ? AppColors.primaryBlueLight
                              : AppColors.primaryBlue,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: isDarkMode
                              ? Colors.white.withAlpha(15)
                              : Colors.white,
                        ),
                        tooltip: 'Detaya Git',
                      ),
                      const SizedBox(width: 12),
                    ],

                    // Re-Roll Button (Yeniden At)
                    Expanded(
                      child: ElevatedButton.icon(
                        key: const ValueKey('roll_button'),
                        onPressed: () => _roll(),
                        icon: const Text('🎲', style: TextStyle(fontSize: 18)),
                        label: const Text(
                          'Yeniden At',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDarkMode,
    Color secondaryTextColor,
  ) {
    return Center(
      key: const ValueKey('empty_state'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withAlpha(10)
                  : AppColors.primaryBlue.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.format_quote_rounded,
              size: 48,
              color: isDarkMode
                  ? AppColors.primaryBlueLight
                  : AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Keşfedilecek alıntı bulunamadı',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDarkMode
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Bu kategoride alıntı bulunmuyor veya henüz hiç söz eklemediniz. İlk alıntınızı eklemeye ne dersiniz?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: secondaryTextColor,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const QuoteFormPage(),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('İlk Alıntını Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(
    BuildContext context,
    Quote quote,
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Center(
      key: ValueKey(quote.id),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? const [
                    Color(0xFF1E293B),
                    Color(0xFF0F172A),
                  ]
                : const [
                    Color(0xFFF8FAFC),
                    Color(0xFFEEF2F6),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode
                ? AppColors.primaryBlueLight.withAlpha(45)
                : AppColors.primaryBlue.withAlpha(30),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withAlpha(70)
                  : const Color(0xFF60A5FA).withAlpha(25),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category tag & quote icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? AppColors.primaryBlueLight.withAlpha(35)
                          : AppColors.primaryBlue.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      quote.categoryName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode
                            ? AppColors.primaryBlueLight
                            : AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.format_quote_rounded,
                    size: 32,
                    color: isDarkMode
                        ? AppColors.primaryBlueLight.withAlpha(90)
                        : AppColors.primaryBlue.withAlpha(70),
                  ),
                ],
              ),

              // Media Preview (if available)
              if (quote.mediaUrl != null && quote.mediaUrl!.isNotEmpty) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    quote.mediaUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Quote text
              Text(
                '"${quote.displayText}"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 14),

              // Author
              Text(
                '— ${quote.author}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
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

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: isDarkMode
            ? AppColors.primaryBlue.withAlpha(50)
            : AppColors.primaryBlue.withAlpha(35),
        backgroundColor: isDarkMode
            ? (isSelected
                ? AppColors.primaryBlue.withAlpha(50)
                : AppColors.darkCardBackground)
            : (isSelected
                ? AppColors.primaryBlue.withAlpha(35)
                : const Color(0xFFF0F3FF)),
        labelStyle: TextStyle(
          color: isSelected ? activeColor : inactiveTextColor,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: isDarkMode
              ? BorderSide(
                  color: isSelected
                      ? AppColors.primaryBlueLight.withAlpha(80)
                      : Colors.white.withAlpha(15),
                  width: 1,
                )
              : BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        showCheckmark: false,
      ),
    );
  }
}
