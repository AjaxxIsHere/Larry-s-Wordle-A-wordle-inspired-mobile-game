import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:collection'; // For HashSet

class WordLoader {
  static HashSet<String>? _wordSet; // Use a nullable HashSet to indicate if it's loaded

  // Method to load words. Call this once, e.g., in main() or in your app's initState.
  static Future<void> loadWords() async {
    if (_wordSet != null) {
      // Words already loaded, no need to load again
      return;
    }

    debugPrint('Loading words from assets...');
    final String fileContent = await rootBundle.loadString('assets/words.txt');
    _wordSet = HashSet<String>();

    // Split the content by lines and add each word to the HashSet
    // Ensure words are trimmed and converted to lowercase for consistent lookup
    for (String line in fileContent.split('\n')) {
      final word = line.trim().toLowerCase();
      if (word.isNotEmpty) {
        _wordSet!.add(word);
      }
    }
    debugPrint('Words loaded: ${_wordSet!.length} words.');
  }

  // Method to check if a word exists in the loaded set
  static bool isValidWordLocally(String word) {
    if (_wordSet == null) {
      // This should ideally not happen if loadWords() is called at startup
      // You might want to throw an error or log a warning here.
      debugPrint('Warning: Word set not loaded!');
      return false;
    }
    // Trim and lowercase the input word for consistent lookup
    return _wordSet!.contains(word.trim().toLowerCase());
  }
}