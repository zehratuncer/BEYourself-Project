import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quote_reminder/core/theme/app_colors.dart';
import 'package:quote_reminder/core/utils/category_icon_helper.dart';
import 'package:quote_reminder/features/category/domain/entities/category.dart';
import 'package:quote_reminder/features/category/presentation/providers/category_providers.dart';
import 'package:quote_reminder/features/category/presentation/widgets/edit_category_dialog.dart';
import 'package:quote_reminder/features/quote/presentation/providers/quote_providers.dart';
import 'package:quote_reminder/shared/providers/navigation_provider.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  void _showCategoryOptions(
    BuildContext context,
    WidgetRef ref,
    Category category,
    int quoteCount,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                    color: const Color(0xFFD0D7DE),
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
                      color: AppColors.primaryBlue.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CategoryIconHelper.getIconForCategory(category.name),
                      color: AppColors.primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111C2D),
                        ),
                      ),
                      Text(
                        '$quoteCount Alıntı',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF516072),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F3FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primaryBlue,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Kategori İsmini Düzenle',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111C2D),
                  ),
                ),
                subtitle: const Text(
                  'Kategorinin başlığını güncelleyin',
                  style: TextStyle(fontSize: 12, color: Color(0xFF717783)),
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
                    color: const Color(0xFFFFECEB),
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
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF717783)),
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
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF414751),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kategoriler',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'İlham veren düşünceleri keşfet',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF516072),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: categories.isEmpty
                  ? const Center(
                      child: Text(
                        'Henüz bir kategori bulunmuyor.\nSağ alttaki butondan ekleyebilirsiniz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF516072),
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
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        const Color(0xFF60A5FA).withAlpha(15),
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
                                      color: AppColors.primaryBlue
                                          .withAlpha(20),
                                    ),
                                    child: Icon(
                                      categoryIcon,
                                      color: AppColors.primaryBlue,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    category.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111C2D),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F3FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$displayCount Alıntı',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF516072),
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

