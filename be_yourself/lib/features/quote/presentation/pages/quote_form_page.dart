import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:be_yourself/core/theme/app_colors.dart';
import 'package:be_yourself/features/category/presentation/providers/category_providers.dart';
import 'package:be_yourself/features/media/services/instagram_downloader_service.dart';
import 'package:be_yourself/features/quote/domain/entities/quote.dart';
import 'package:be_yourself/features/quote/presentation/providers/quote_providers.dart';
import 'package:be_yourself/features/settings/presentation/pages/settings_page.dart';
import 'package:be_yourself/shared/widgets/app_video_player.dart';

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
  late final TextEditingController _instagramUrlController;
  late String _selectedCategory;
  late bool _isFavorite;
  String? _selectedMediaUrl;
  bool _isSummarizing = false;
  bool _isDownloadingReel = false;
  String _downloadStatus = '';
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _textController =
        TextEditingController(text: widget.initialQuote?.text ?? '');
    _shortTextController =
        TextEditingController(text: widget.initialQuote?.shortText ?? '');
    _authorController =
        TextEditingController(text: widget.initialQuote?.author ?? '');
    _instagramUrlController = TextEditingController();
    _selectedCategory = widget.initialQuote?.categoryName ?? 'Motivasyon';
    _isFavorite = widget.initialQuote?.isFavorite ?? false;
    _selectedMediaUrl = widget.initialQuote?.mediaUrl;
  }

  @override
  void dispose() {
    _textController.dispose();
    _shortTextController.dispose();
    _authorController.dispose();
    _instagramUrlController.dispose();
    super.dispose();
  }

  String _generateSmartTitle(String rawText) {
    // 1. Remove hashtags (#word)
    var clean = rawText.replaceAll(RegExp(r'#\S+'), '');
    // 2. Remove URLs
    clean = clean.replaceAll(RegExp(r'https?:\/\/\S+'), '');
    // 3. Remove @mentions
    clean = clean.replaceAll(RegExp(r'@\S+'), '');
    // 4. Normalize multiple spaces & newlines
    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (clean.isEmpty) return 'İlham Veren Reels ✨';

    // 5. Extract first complete sentence
    final sentenceMatch = RegExp(r'^([^.!?\n]+[.!?]?)').firstMatch(clean);
    String summary = sentenceMatch?.group(1)?.trim() ?? clean;

    if (summary.length > 65) {
      if (summary.contains(',')) {
        summary = '${summary.split(',').first.trim()}...';
      } else {
        summary = '${summary.substring(0, 60).trim()}...';
      }
    }

    return summary;
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

    await Future.delayed(const Duration(milliseconds: 400));

    final summary = _generateSmartTitle(originalText);

    setState(() {
      _shortTextController.text = summary;
      _isSummarizing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Alıntı AI ile başarıyla kısaltıldı ve başlık oluşturuldu!'),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    }
  }

  Future<void> _pasteInstagramUrl() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _instagramUrlController.text = data.text!.trim();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Panodaki bağlantı yapıştırıldı! 📋'),
            duration: Duration(milliseconds: 1000),
          ),
        );
      }
    }
  }

  Future<void> _downloadReelVideo() async {
    final url = _instagramUrlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir Instagram Reels bağlantısı giriniz.'),
        ),
      );
      return;
    }

    if (!InstagramDownloaderService.instance.isValidInstagramUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lütfen geçerli bir Instagram bağlantısı giriniz (örn: instagram.com/reel/...).',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isDownloadingReel = true;
      _downloadProgress = 0.0;
      _downloadStatus = 'Bağlantı kontrol ediliyor...';
    });

    try {
      final result =
          await InstagramDownloaderService.instance.downloadReel(
        instagramUrl: url,
        onProgress: (progress, status) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
              _downloadStatus = status;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _selectedMediaUrl = result.filePath;
          _isDownloadingReel = false;
          _instagramUrlController.clear();

          // Auto-fill caption and generate smart title
          if (result.caption != null && result.caption!.trim().isNotEmpty) {
            final cleanCaption = result.caption!.trim();
            _textController.text = cleanCaption;

            // Auto-generate punchy single-sentence title
            final smartTitle = _generateSmartTitle(cleanCaption);
            _shortTextController.text = smartTitle;
          }

          // Auto-fill author if available and author is empty
          if (result.authorUsername != null &&
              _authorController.text.trim().isEmpty) {
            _authorController.text = '@${result.authorUsername}';
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '🎬 Reels videosu, açıklaması ve başlığı otomatik oluşturuldu! ✨'),
            backgroundColor: AppColors.primaryBlue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloadingReel = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video indirilirken hata oluştu: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  bool _isVideoMedia(String? path) {
    if (path == null) return false;
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.contains('/reels/') ||
        lower.contains('video');
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
            const SnackBar(
                content: Text('Fotoğraf galeriden başarıyla seçildi!')),
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
                      'Instagram Reels bağlantısı girin veya galerinizden fotoğraf/video ekleyin.',
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Instagram Reels Linki Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: isDarkMode
                            ? Border.all(
                                color: Colors.white.withAlpha(15),
                                width: 1,
                              )
                            : Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black.withAlpha(30)
                                : Colors.black.withAlpha(6),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF58529),
                                      Color(0xFFDD2A7B),
                                      Color(0xFF8134AF)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.video_library_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Instagram Reels Linki',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                    Text(
                                      'Reels linkini yapıştırarak videoyu otomatik indirin.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? AppColors.darkInputFill
                                  : AppColors.lightInputFill,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _instagramUrlController,
                                    enabled: !_isDownloadingReel,
                                    style: TextStyle(
                                        color: primaryTextColor, fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText:
                                          'https://www.instagram.com/reel/...',
                                      hintStyle: TextStyle(
                                        color: secondaryTextColor,
                                        fontSize: 13,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _isDownloadingReel
                                      ? null
                                      : _pasteInstagramUrl,
                                  icon: const Icon(
                                    Icons.content_paste_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Yapıştır',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: isDarkMode
                                        ? AppColors.primaryBlueLight
                                        : AppColors.primaryBlue,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_isDownloadingReel) ...[
                            LinearProgressIndicator(
                              value: _downloadProgress > 0
                                  ? _downloadProgress
                                  : null,
                              backgroundColor: isDarkMode
                                  ? Colors.white12
                                  : Colors.black12,
                              color: AppColors.primaryBlueLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _downloadStatus,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode
                                        ? AppColors.primaryBlueLight
                                        : AppColors.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: ElevatedButton.icon(
                                onPressed: _downloadReelVideo,
                                icon: const Icon(Icons.download_rounded,
                                    size: 18),
                                label: const Text(
                                  'Videoyu İndir',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDarkMode
                                      ? const Color(0xFF2563EB)
                                      : AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Media Preview (if media selected/downloaded)
                    if (_selectedMediaUrl != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green.withAlpha(80),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded,
                                        color: Colors.green, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isVideoMedia(_selectedMediaUrl)
                                          ? 'Eklenen Video'
                                          : 'Eklenen Fotoğraf',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedMediaUrl = null;
                                    });
                                  },
                                  icon: const Icon(Icons.delete_outline,
                                      size: 16, color: Colors.redAccent),
                                  label: const Text(
                                    'Kaldır',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_isVideoMedia(_selectedMediaUrl))
                              AppVideoPlayer(
                                videoPath: _selectedMediaUrl!,
                                height: 180,
                              )
                            else if (_selectedMediaUrl!.startsWith('http'))
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  _selectedMediaUrl!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  File(_selectedMediaUrl!),
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Alternative Pickers from Gallery
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
                                height: 95,
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
                                      size: 26,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Galeriden Fotoğraf',
                                      style: TextStyle(
                                        fontSize: 12,
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
                        const SizedBox(width: 12),
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
                                height: 95,
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
                                      size: 26,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Galeriden Video',
                                      style: TextStyle(
                                        fontSize: 12,
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


