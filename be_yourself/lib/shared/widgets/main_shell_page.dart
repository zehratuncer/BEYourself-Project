import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:be_yourself/core/theme/app_colors.dart';
import 'package:be_yourself/features/category/presentation/pages/categories_page.dart';
import 'package:be_yourself/features/category/presentation/widgets/add_category_dialog.dart';
import 'package:be_yourself/features/favorites/presentation/pages/favorites_page.dart';
import 'package:be_yourself/features/home/presentation/pages/home_page.dart';
import 'package:be_yourself/features/quote/presentation/pages/quote_detail_page.dart';
import 'package:be_yourself/features/quote/presentation/pages/quote_form_page.dart';
import 'package:be_yourself/features/quote/presentation/widgets/random_quote_modal.dart';
import 'package:be_yourself/features/settings/presentation/pages/settings_page.dart';
import 'package:be_yourself/shared/providers/navigation_provider.dart';

class MainShellPage extends ConsumerWidget {
  const MainShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    final pages = [
      HomePage(
        onAddQuoteTap: () => _openAddQuote(context),
        onQuoteTap: (quoteId) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => QuoteDetailPage(quoteId: quoteId),
            ),
          );
        },
      ),
      const FavoritesPage(),
      const CategoriesPage(),
      const SettingsPage(),
    ];

    final isCategoriesTab = currentTab == 2;

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: pages,
      ),
      floatingActionButton: (currentTab == 0)
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'random_quote_dice_fab',
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    RandomQuoteModal.show(context);
                  },
                  backgroundColor: isDarkMode
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  elevation: 6,
                  shape: const CircleBorder(),
                  tooltip: 'Rastgele Keşfet',
                  child: const Text(
                    '🎲',
                    style: TextStyle(fontSize: 26),
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'main_add_quote_fab',
                  onPressed: () => _openAddQuote(context),
                  backgroundColor: AppColors.primaryBlue,
                  elevation: 6,
                  shape: const CircleBorder(),
                  tooltip: 'Alıntı Ekle',
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            )
          : (isCategoriesTab
              ? FloatingActionButton(
                  heroTag: 'add_category_fab',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const AddCategoryDialog(),
                    );
                  },
                  backgroundColor: AppColors.primaryBlue,
                  elevation: 6,
                  shape: const CircleBorder(),
                  tooltip: 'Kategori Ekle',
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 28,
                  ),
                )
              : null),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withAlpha(40)
                  : Colors.black.withAlpha(12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentTab,
          onTap: (index) {
            ref.read(currentTabProvider.notifier).state = index;
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).cardColor,
          selectedItemColor: isDarkMode
              ? AppColors.primaryBlueLight
              : AppColors.primaryBlue,
          unselectedItemColor: isDarkMode
              ? AppColors.darkTextSecondary
              : const Color(0xFF516072),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Ana Sayfa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Favoriler',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Kategoriler',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Ayarlar',
            ),
          ],
        ),
      ),
    );
  }

  void _openAddQuote(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const QuoteFormPage(),
      ),
    );
  }
}
