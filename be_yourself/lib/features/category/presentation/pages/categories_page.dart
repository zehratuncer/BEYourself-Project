import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:be_yourself/core/theme/app_colors.dart';
import 'package:be_yourself/core/utils/category_icon_helper.dart';
import 'package:be_yourself/features/category/domain/entities/category.dart';
import 'package:be_yourself/features/category/presentation/providers/category_providers.dart';
import 'package:be_yourself/features/category/presentation/widgets/edit_category_dialog.dart';
import 'package:be_yourself/features/quote/presentation/providers/quote_providers.dart';
import 'package:be_yourself/features/settings/presentation/pages/settings_page.dart';
import 'package:be_yourself/shared/providers/navigation_provider.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  void _showCategoryOptions(
    BuildContext context,
    WidgetRef ref,
    Category category,
    int quoteCount,
  ) {
    final isDarkMode = ref.read(isDarkModeProvider);
    final cardBg = Theme.of(context).cardColor;
    final primaryTextColor = isDarkMode
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryTextColor = isDarkMode
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppColors.darkDivider
                        : const Color(0xFFD0D7DE),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? AppColors.primaryBlueLight.withAlpha(25)
                          : AppColors.primaryBlue.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CategoryIconHelper.getIconForCategory(category.name),
                      color: isDarkMode
                          ? AppColors.primaryBlueLight
                          : AppColors.primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                      Text(
                        '$quoteCount Alıntı',
                        style: TextStyle(
                          fontSize: 13,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(
                height: 1,
                color: isDarkMode ? AppColors.darkDivider : AppColors.lightDivider,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppColors.darkInputFill
                        : const Color(0xFFF0F3FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    color: isDarkMode
                        ? AppColors.primaryBlueLight
                        : AppColors.primaryBlue,
                    size: 22,
                  ),
                ),
                title: Text(
                  'Kategori İsmini Düzenle',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                ),
                subtitle: Text(
                  'Kategorinin başlığını güncelleyin',
                  style: TextStyle(fontSize: 12, color: secondaryTextColor),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  showDialog(
                    context: context,
                    builder: (_) => EditCategoryDialog(category: category),
                  );
                },
              ),
              const SizedBox(height: 4),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFFDC2626).withAlpha(30)
                        : const Color(0xFFFFECEB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFDC2626),
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Kategoriyi Sil',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDC2626),
                  ),
                ),
                subtitle: Text(
                  quoteCount > 0
                      ? '$quoteCount alıntı "Genel" kategorisine aktarılacak'
                      : 'Bu kategoriyi kalıcı olarak kaldırın',
                  style: TextStyle(fontSize: 12, color: secondaryTextColor),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showDeleteConfirmDialog(context, ref, category, quoteCount);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    Category category,
    int quoteCount,
  ) {
    final isDarkMode = ref.read(isDarkModeProvider);
    final secondaryTextColor = isDarkMode
        ? AppColors.darkTextSecondary
        : const Color(0xFF414751);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 10),
            Text(
              'Kategoriyi Sil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          quoteCount > 0
              ? '"${category.name}" kategorisini silmek istediğinize emin misiniz? Bu kategoriye ait $quoteCount alıntı "Genel" kategorisine taşınacaktır.'
              : '"${category.name}" kategorisini silmek istediğinize emin misiniz?',
          style: TextStyle(
            fontSize: 14,
            color: secondaryTextColor,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(categoryListProvider.notifier)
                  .deleteCategory(category.id);
              ref
                  .read(quoteListProvider.notifier)
                  .handleCategoryDeleted(category.name);

              if (ref.read(selectedCategoryFilterProvider) == category.name) {
                ref.read(selectedCategoryFilterProvider.notifier).state =
                    'Hepsi';
              }

              Navigator.of(dialogCtx).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${category.name}" kategorisi silindi.'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryListProvider);
    final quotes = ref.watch(quoteListProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    final cardBg = Theme.of(context).cardColor;
    final primaryTextColor = isDarkMode
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryTextColor = isDarkMode
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kategoriler',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode
                          ? AppColors.primaryBlueLight
                          : AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'İlham veren düşünceleri keşfet',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: categories.isEmpty
                  ? Center(
                      child: Text(
                        'Henüz bir kategori bulunmuyor.\nSağ alttaki butondan ekleyebilirsiniz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 15,
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final categoryQuotesCount = quotes
                            .where((q) => q.categoryName == category.name)
                            .length;
                        final displayCount = categoryQuotesCount;

                        final categoryIcon =
                            CategoryIconHelper.getIconForCategory(
                          category.name,
                        );

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              ref
                                  .read(
                                    selectedCategoryFilterProvider.notifier,
                                  )
                                  .state = category.name;
                              ref.read(currentTabProvider.notifier).state =
                                  0; // Go to home tab
                            },
                            onLongPress: () {
                              _showCategoryOptions(
                                context,
                                ref,
                                category,
                                displayCount,
                              );
                            },
                            child: Ink(
                              padding: const EdgeInsets.all(16),
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
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDarkMode
                                          ? AppColors.primaryBlueLight
                                              .withAlpha(25)
                                          : AppColors.primaryBlue
                                              .withAlpha(20),
                                    ),
                                    child: Icon(
                                      categoryIcon,
                                      color: isDarkMode
                                          ? AppColors.primaryBlueLight
                                          : AppColors.primaryBlue,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    category.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? AppColors.darkInputFill
                                          : const Color(0xFFF0F3FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$displayCount Alıntı',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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


