import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quote_reminder/core/theme/app_colors.dart';
import 'package:quote_reminder/core/utils/category_icon_helper.dart';
import 'package:quote_reminder/features/category/domain/entities/category.dart';
import 'package:quote_reminder/features/category/presentation/providers/category_providers.dart';
import 'package:quote_reminder/features/quote/presentation/providers/quote_providers.dart';
import 'package:quote_reminder/features/settings/presentation/pages/settings_page.dart';

class EditCategoryDialog extends ConsumerStatefulWidget {
  const EditCategoryDialog({super.key, required this.category});

  final Category category;

  @override
  ConsumerState<EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends ConsumerState<EditCategoryDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.category.name);
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveCategory() {
    final newName = _controller.text.trim();
    if (newName.isEmpty) return;

    final oldName = widget.category.name;

    // Kategori adını güncelle
    ref
        .read(categoryListProvider.notifier)
        .updateCategory(widget.category.id, newName);

    // Bağlı alıntıların kategori adını senkronize et
    ref.read(quoteListProvider.notifier).renameCategory(oldName, newName);

    // Aktif filtre bu kategori ise filtreyi de güncelle
    final currentFilter = ref.read(selectedCategoryFilterProvider);
    if (currentFilter == oldName) {
      ref.read(selectedCategoryFilterProvider.notifier).state = newName;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final previewIcon =
        CategoryIconHelper.getIconForCategory(_controller.text);
    final isDarkMode = ref.watch(isDarkModeProvider);

    final primaryTextColor = isDarkMode
        ? AppColors.darkTextPrimary
        : const Color(0xFF111C2D);
    final secondaryTextColor = isDarkMode
        ? AppColors.darkTextSecondary
        : const Color(0xFF5E6C84);

    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppColors.primaryBlueLight.withAlpha(30)
                        : AppColors.primaryBlue.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    previewIcon,
                    color: isDarkMode
                        ? AppColors.primaryBlueLight
                        : AppColors.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kategoriyi Düzenle',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kategori ismini güncelleyin',
                        style: TextStyle(
                          fontSize: 13,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              autofocus: true,
              style: TextStyle(color: primaryTextColor),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Kategori Adı',
                hintStyle: TextStyle(
                  color: isDarkMode
                      ? AppColors.darkTextSecondary
                      : const Color(0xFFA0AAB8),
                ),
                prefixIcon: Icon(
                  previewIcon,
                  color: isDarkMode
                      ? AppColors.primaryBlueLight
                      : AppColors.primaryBlue,
                ),
                filled: true,
                fillColor: isDarkMode
                    ? AppColors.darkInputFill
                    : const Color(0xFFF0F3FF),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: isDarkMode
                      ? BorderSide(color: Colors.white.withAlpha(20))
                      : BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _saveCategory(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'İptal',
                    style: TextStyle(
                      color: isDarkMode
                          ? AppColors.darkTextSecondary
                          : const Color(0xFF717783),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? AppColors.primaryBlueLight
                        : AppColors.primaryBlue,
                    foregroundColor:
                        isDarkMode ? Colors.black87 : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Güncelle'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

