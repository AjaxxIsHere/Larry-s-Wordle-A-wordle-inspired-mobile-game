import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:collection';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WordHelper {
  // static final Set<String> _validatedWordsCache = {};
  static final Queue<String> _randomWordsQueue = Queue();
  static const int _queueSize = 5;

  /// Populates the queue with 5 random 5-letter English words from the API.
  static Future<void> _populateQueue() async {
    while (_randomWordsQueue.length < _queueSize) {
      final String apiUrl = dotenv.env['NEW_WORD_API']!;
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String word = data['word'].toUpperCase();
        _randomWordsQueue.add(word);
      } else {
        throw Exception('Failed to fetch word from API');
      }
    }
  }

  /// Returns a random 5-letter English word from the queue, maintaining the queue size.
  static Future<String> getRandomFiveLetterWord() async {
    if (_randomWordsQueue.isEmpty) {
      await _populateQueue();
    }

    final String word = _randomWordsQueue.removeFirst();
    await _populateQueue(); // Fetch a new word to maintain the queue size
    return word;
  }

  static Future<String> getDailyWord() async {
    final String apiUrl = dotenv.env['DAILY_WORD_API']!;
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      // print('Daily word fetched: ${data['word']}');
      return data['word'].toUpperCase();
    } else {
      throw Exception('Failed to fetch daily word from API');
    }
  }
}
