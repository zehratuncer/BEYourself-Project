import 'package:flutter/material.dart';

/// Kategori adına ve türüne göre otomatik ve uyumlu ikon ve renk sağlayan yardımcı sınıf.
final class CategoryIconHelper {
  const CategoryIconHelper._();

  /// Kategori ismine göre uygun bir Material Icon döndürür.
  static IconData getIconForCategory(String categoryName) {
    final name = categoryName.toLowerCase().trim();

    if (name.contains('psikoloji') ||
        name.contains('zihin') ||
        name.contains('düşünce') ||
        name.contains('terapi') ||
        name.contains('farkındalık') ||
        name.contains('ruh')) {
      return Icons.psychology_rounded;
    } else if (name.contains('motivasyon') ||
        name.contains('güç') ||
        name.contains('başarı') ||
        name.contains('hedef') ||
        name.contains('azim') ||
        name.contains('spor') ||
        name.contains('fitness') ||
        name.contains('enerji')) {
      return Icons.fitness_center_rounded;
    } else if (name.contains('kitap') ||
        name.contains('edebiyat') ||
        name.contains('şiir') ||
        name.contains('yazar') ||
        name.contains('roman') ||
        name.contains('okuma') ||
        name.contains('öykü')) {
      return Icons.menu_book_rounded;
    } else if (name.contains('müzik') ||
        name.contains('şarkı') ||
        name.contains('melodi') ||
        name.contains('nota') ||
        name.contains('akustik') ||
        name.contains('sanat') ||
        name.contains('resim')) {
      return Icons.music_note_rounded;
    } else if (name.contains('felsefe') ||
        name.contains('bilgelik') ||
        name.contains('filozof') ||
        name.contains('akıl') ||
        name.contains('mantık') ||
        name.contains('fikir')) {
      return Icons.school_rounded;
    } else if (name.contains('aşk') ||
        name.contains('sevgi') ||
        name.contains('ilişki') ||
        name.contains('kalp') ||
        name.contains('romantik') ||
        name.contains('duygu') ||
        name.contains('sevda')) {
      return Icons.favorite_rounded;
    } else if (name.contains('doğa') ||
        name.contains('huzur') ||
        name.contains('yaşam') ||
        name.contains('hayat') ||
        name.contains('çevre') ||
        name.contains('çiçek') ||
        name.contains('ağaç')) {
      return Icons.spa_rounded;
    } else if (name.contains('iş') ||
        name.contains('kariyer') ||
        name.contains('para') ||
        name.contains('finans') ||
        name.contains('yatırım') ||
        name.contains('ekonomi') ||
        name.contains('ofis')) {
      return Icons.work_outline_rounded;
    } else if (name.contains('seyahat') ||
        name.contains('gezi') ||
        name.contains('yol') ||
        name.contains('tatil') ||
        name.contains('keşif') ||
        name.contains('macera')) {
      return Icons.explore_rounded;
    } else if (name.contains('bilim') ||
        name.contains('teknoloji') ||
        name.contains('yazılım') ||
        name.contains('kod') ||
        name.contains('icat') ||
        name.contains('fikir')) {
      return Icons.lightbulb_rounded;
    }

    // Varsayılan / Fallback İkon
    return Icons.grid_view_rounded;
  }
}
