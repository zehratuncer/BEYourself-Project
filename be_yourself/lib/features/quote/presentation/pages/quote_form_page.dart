import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quote_reminder/core/theme/app_colors.dart';
import 'package:quote_reminder/features/category/presentation/providers/category_providers.dart';
import 'package:quote_reminder/features/quote/domain/entities/quote.dart';
import 'package:quote_reminder/features/quote/presentation/providers/quote_providers.dart';

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

    // AI Özetleme Simülasyonu / İşlemi
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
          content: Text('✨ Alıntı AI ile başarıyla özetlendi!'),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
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
      );
      ref.read(quoteListProvider.notifier).addQuote(newQuote);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        title: Text(
          widget.initialQuote == null ? 'Yeni Söz Ekle' : 'Sözü Düzenle',
          style: const TextStyle(
            color: Color(0xFF111C2D),
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryBlue),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Alıntı Metni',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111C2D),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isSummarizing ? null : _generateAiSummary,
                    icon: _isSummarizing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome,
                            size: 16, color: AppColors.primaryBlue),
                    label: Text(
                      _isSummarizing ? 'Kısaltılıyor...' : 'AI ile Kısalt',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Sana ilham veren sözü buraya yaz...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kısaltılmış Metin / Özet (Kartlarda gözükecek)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF414751),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _shortTextController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText:
                      'AI butonu ile otomatik kısaltabilir veya kendiniz yazabilirsiniz...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Yazar / Kaynak',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111C2D),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _authorController,
                decoration: InputDecoration(
                  hintText: 'Ör. Albert Einstein veya Bilinmeyen',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Kategori',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111C2D),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: categories
                            .any((c) => c.name == _selectedCategory)
                        ? _selectedCategory
                        : categories.first.name,
                    isExpanded: true,
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.name,
                        child: Text(cat.name),
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

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saveQuote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Kaydet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
