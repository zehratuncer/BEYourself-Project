import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:be_yourself/features/quote/domain/entities/quote.dart';

class QuoteLocalDataSource {
  final SharedPreferences prefs;

  QuoteLocalDataSource(this.prefs);

  static const String _quotesKey = 'saved_quotes_list_v1';

  List<Quote> getQuotes() {
    final rawJson = prefs.getString(_quotesKey);
    if (rawJson == null || rawJson.trim().isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
      return decoded
          .map((item) => Quote.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveQuotes(List<Quote> quotes) async {
    final encoded = jsonEncode(quotes.map((q) => q.toJson()).toList());
    return await prefs.setString(_quotesKey, encoded);
  }
}
