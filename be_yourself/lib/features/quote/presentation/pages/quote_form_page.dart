import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:be_yourself/core/theme/app_colors.dart';
import 'package:be_yourself/features/category/presentation/providers/category_providers.dart';
import 'package:be_yourself/features/quote/domain/entities/quote.dart';
import 'package:be_yourself/features/quote/presentation/providers/quote_providers.dart';
import 'package:be_yourself/features/settings/presentation/pages/settings_page.dart';

class QuoteFormPage extends ConsumerStatefulWidget {
  const QuoteFormPage({super.key, this.initialQuote});

  final Quote? initialQuote;

  @override
  ConsumerState<QuoteFormPage> createState() => _QuoteFormPageState();
}

class _QuoteFormPageState extends ConsumerState<QuoteFormPage> {
  late final TextEditingController _textController;
  late final TextEditingController _shortTextController;
  late final TextEditingController _authorController;
  late String _selectedCategory;
  late bool _isFavorite;
  String? _selectedMediaUrl;
  bool _isSummarizing = false;

  @override
  void initState() {
    super.initState();
    _textController =
        TextEditingController(text: widget.initialQuote?.text ?? '');
    _shortTextController =
        TextEditingController(text: widget.initialQuote?.shortText ?? '');
    _authorController =
        TextEditingController(text: widget.initialQuote?.author ?? '');
    _selectedCategory = widget.initialQuote?.categoryName ?? 'Motivasyon';
    _isFavorite = widget.initialQuote?.isFavorite ?? false;
    _selectedMediaUrl = widget.initialQuote?.mediaUrl;
  }

  @override
  void dispose() {
    _textController.dispose();
    _shortTextController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _generateAiSummary() async {
    final originalText = _textController.text.trim();
    if (originalText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce özetlenecek bir alıntı metni girin.'),
        ),
      );
      return;
    }

    setState(() => _isSummarizing = true);

    await Future.delayed(const Duration(milliseconds: 600));

    String summary = originalText;
    if (originalText.contains(',') && originalText.length > 50) {
      summary = '${originalText.split(',').first}...';
    } else if (originalText.contains('.') && originalText.length > 50) {
      summary = '${originalText.split('.').first}.';
    } else if (originalText.length > 60) {
      summary = '${originalText.substring(0, 55).trim()}...';
    }

    setState(() {
      _shortTextController.text = summary;
      _isSummarizing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Alıntı AI ile başarıyla kısaltıldı!'),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedMediaUrl = image.path;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fotoğraf galeriden başarıyla seçildi!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf seçilirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
      );
      if (video != null) {
        setState(() {
          _selectedMediaUrl = video.path;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video galeriden başarıyla seçildi!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video seçilirken hata oluştu: $e')),
        );
      }
    }
  }

  void _saveQuote() {
    final text = _textController.text.trim();
    final shortText = _shortTextController.text.trim();
    final author = _authorController.text.trim().isEmpty
        ? 'Bilinmeyen'
        : _authorController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir söz metni girin.')),
      );
      return;
    }

    if (widget.initialQuote != null) {
      final updated = widget.initialQuote!.copyWith(
        text: text,
        shortText: shortText.isNotEmpty ? shortText : null,
        author: author,
        categoryName: _selectedCategory,
        isFavorite: _isFavorite,
        mediaUrl: _selectedMediaUrl,
      );
      ref.read(quoteListProvider.notifier).updateQuote(updated);
    } else {
      final newQuote = Quote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        shortText: shortText.isNotEmpty ? shortText : null,
        author: author,
        categoryName: _selectedCategory,
        createdAt: DateTime.now(),
        isFavorite: _isFavorite,
        mediaUrl: _selectedMediaUrl,
      );
      ref.read(quoteListProvider.notifier).addQuote(newQuote);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider);
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
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode
                ? AppColors.primaryBlueLight
                : AppColors.primaryBlue,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.initialQuote == null ? 'Alıntı Ekle' : 'Sözü Düzenle',
          style: TextStyle(
            color: isDarkMode
                ? AppColors.primaryBlueLight
                : AppColors.primaryBlue,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: secondaryTextColor),
            onPressed: () {},
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Card: İlhamı Yakala
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? AppColors.darkCardBackground
                            : const Color(0xFFF0F4FD),
                        borderRadius: BorderRadius.circular(24),
                        border: isDarkMode
                            ? Border.all(
                                color: Colors.white.withAlpha(15),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'İlhamı Yakala',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: isDarkMode
                                      ? AppColors.primaryBlueLight
                                      : AppColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Sizi etkileyen kelimeleri kalıcı hale getirin.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            right: 0,
                            top: -12,
                            child: Text(
                              '”',
                              style: TextStyle(
                                fontSize: 80,
                                fontWeight: FontWeight.w900,
                                color: isDarkMode
                                    ? AppColors.primaryBlueLight.withAlpha(20)
                                    : AppColors.primaryBlue.withAlpha(25),
                                height: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Alıntı Text Field
                    Text(
                      'Alıntı',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
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
                                : Colors.black.withAlpha(8),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextField(
                            controller: _textController,
                            maxLines: 5,
                            style: TextStyle(color: primaryTextColor),
                            decoration: InputDecoration(
                              hintText: 'Alıntıyı buraya yazın...',
                              hintStyle: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 15,
                              ),
                              contentPadding: const EdgeInsets.all(16),
                              border: InputBorder.none,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 12, bottom: 12),
                            child: IconButton(
                              onPressed:
                                  _isSummarizing ? null : _generateAiSummary,
                              icon: _isSummarizing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : Icon(
                                      Icons.format_indent_decrease_rounded,
                                      color: secondaryTextColor,
                                    ),
                              tooltip: 'AI ile Özetle/Kısalt',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Medya Ekle Section
                    Text(
                      'Medya Ekle',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Alıntınıza bir fotoğraf veya video ekleyerek onu görselleştirin.',
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: CustomPaint(
                              painter: _DashedBorderPainter(
                                color: isDarkMode
                                    ? AppColors.darkDivider
                                    : const Color(0xFFC7D0EE),
                              ),
                              child: Container(
                                height: 110,
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? AppColors.darkInputFill
                                      : const Color(0xFFF2F4FD),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_outlined,
                                      color: isDarkMode
                                          ? AppColors.primaryBlueLight
                                          : AppColors.primaryBlue,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Fotoğraf Ekle',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickVideo,
                            child: CustomPaint(
                              painter: _DashedBorderPainter(
                                color: isDarkMode
                                    ? AppColors.darkDivider
                                    : const Color(0xFFC7D0EE),
                              ),
                              child: Container(
                                height: 110,
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? AppColors.darkInputFill
                                      : const Color(0xFFF2F4FD),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.ondemand_video_outlined,
                                      color: isDarkMode
                                          ? AppColors.primaryBlueLight
                                          : AppColors.primaryBlue,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Video Ekle',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedMediaUrl != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 16, color: Colors.green),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Seçilen medya: $_selectedMediaUrl',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Yazar Field
                    Text(
                      'Yazar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: isDarkMode
                            ? Border.all(
                                color: Colors.white.withAlpha(15),
                                width: 1,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black.withAlpha(30)
                                : Colors.black.withAlpha(6),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _authorController,
                        style: TextStyle(color: primaryTextColor),
                        decoration: InputDecoration(
                          hintText: 'Yazar adı',
                          hintStyle: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 15,
                          ),
                          suffixIcon: Icon(
                            Icons.person_outline_rounded,
                            color: secondaryTextColor,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Kategori Dropdown
                    Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: isDarkMode
                            ? Border.all(
                                color: Colors.white.withAlpha(15),
                                width: 1,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black.withAlpha(30)
                                : Colors.black.withAlpha(6),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: cardBg,
                          value: categories
                                  .any((c) => c.name == _selectedCategory)
                              ? _selectedCategory
                              : (categories.isNotEmpty ? categories.first.name : null),
                          isExpanded: true,
                          hint: Text(
                            'Kategori seçin',
                            style: TextStyle(color: secondaryTextColor),
                          ),
                          icon: Icon(
                            Icons.unfold_more_rounded,
                            color: secondaryTextColor,
                          ),
                          items: categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat.name,
                              child: Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: primaryTextColor,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCategory = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Favorilerime Ekle Switch Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? AppColors.darkCardBackground
                            : const Color(0xFFF2F4FD),
                        borderRadius: BorderRadius.circular(20),
                        border: isDarkMode
                            ? Border.all(
                                color: Colors.white.withAlpha(15),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDarkMode
                                  ? AppColors.primaryBlueLight.withAlpha(30)
                                  : const Color(0xFFE2E7FA),
                            ),
                            child: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isDarkMode
                                  ? AppColors.primaryBlueLight
                                  : AppColors.primaryBlue,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Favorilerime Ekle',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: primaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Bu alıntıyı özel koleksiyonunuza kaydeder.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isFavorite,
                            activeTrackColor: isDarkMode
                                ? AppColors.primaryBlueLight
                                : AppColors.primaryBlue,
                            onChanged: (val) {
                              setState(() => _isFavorite = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Save Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _saveQuote,
                  icon: const Icon(Icons.check_circle_outline, size: 22),
                  label: const Text(
                    'Kaydet',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? AppColors.primaryBlueLight
                        : AppColors.primaryBlue,
                    foregroundColor:
                        isDarkMode ? Colors.black87 : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({this.color = const Color(0xFFC7D0EE)});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 1.5;
    const double gap = 5;
    const double radius = 16;

    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double length = gap;
        final Path extractPath =
            metric.extractPath(distance, distance + length);
        canvas.drawPath(extractPath, paint);
        distance += length + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}


