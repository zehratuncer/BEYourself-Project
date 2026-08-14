import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:be_yourself/core/config/supabase_config.dart';
import 'package:be_yourself/features/quote/domain/entities/quote.dart';

class QuoteRemoteDataSource {
  const QuoteRemoteDataSource();

  SupabaseClient? get _client => SupabaseConfig.client;

  /// Fetches all quotes for the specified device ID from Supabase.
  Future<List<Quote>> getQuotes(String deviceId) async {
    final client = _client;
    if (client == null) return [];

    try {
      final response = await client
          .from('quotes')
          .select()
          .eq('device_id', deviceId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) {
        final map = json as Map<String, dynamic>;
        return Quote(
          id: map['id']?.toString() ?? '',
          text: map['text']?.toString() ?? '',
          author: map['author']?.toString() ?? '',
          categoryName: map['category_name']?.toString() ?? 'Genel',
          shortText: map['short_text']?.toString(),
          mediaUrl: map['media_url']?.toString(),
          mediaUrls: (map['media_urls'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          isFavorite: map['is_favorite'] == true,
          createdAt: map['created_at'] != null
              ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
              : DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('QuoteRemoteDataSource getQuotes error: $e');
      return [];
    }
  }

  /// Inserts or updates a quote in Supabase for the device.
  Future<bool> upsertQuote(Quote quote, String deviceId) async {
    final client = _client;
    if (client == null) return false;

    try {
      await client.from('quotes').upsert({
        'id': quote.id,
        'device_id': deviceId,
        'text': quote.text,
        'author': quote.author,
        'category_name': quote.categoryName,
        'short_text': quote.shortText,
        'media_url': quote.mediaUrl,
        'media_urls': quote.allMediaUrls,
        'is_favorite': quote.isFavorite,
        'created_at': quote.createdAt.toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('QuoteRemoteDataSource upsertQuote error: $e');
      return false;
    }
  }

  /// Deletes a quote by ID for the device.
  Future<bool> deleteQuote(String quoteId, String deviceId) async {
    final client = _client;
    if (client == null) return false;

    try {
      await client
          .from('quotes')
          .delete()
          .eq('id', quoteId)
          .eq('device_id', deviceId);
      return true;
    } catch (e) {
      debugPrint('QuoteRemoteDataSource deleteQuote error: $e');
      return false;
    }
  }

  /// Clears all quotes belonging to the device.
  Future<bool> clearAllQuotes(String deviceId) async {
    final client = _client;
    if (client == null) return false;

    try {
      await client.from('quotes').delete().eq('device_id', deviceId);
      return true;
    } catch (e) {
      debugPrint('QuoteRemoteDataSource clearAllQuotes error: $e');
      return false;
    }
  }
}
