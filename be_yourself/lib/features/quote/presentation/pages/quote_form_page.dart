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
  late final TextEditingController _authorController;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _textController =
        TextEditingController(text: widget.initialQuote?.text ?? '');
    _authorController =
        TextEditingController(text: widget.initialQuote?.author ?? '');
    _selectedCategory = widget.initialQuote?.categoryName ?? 'Motivasyon';
  }

  @override
  void dispose() {
    _textController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  void _saveQuote() {
    final text = _textController.text.trim();
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
        author: author,
        categoryName: _selectedCategory,
      );
      ref.read(quoteListProvider.notifier).updateQuote(updated);
    } else {
      final newQuote = Quote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
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
              const Text(
                'Alıntı Metni',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111C2D),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                maxLines: 5,
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
