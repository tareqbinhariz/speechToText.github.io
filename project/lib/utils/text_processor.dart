import 'dart:math' as math;

class TextProcessor {
  /// Applies common Arabic corrections, spell checking, and formatting.
  static String improvedArabicTextCorrection(String text) {
    if (text.isEmpty) return text;

    // Remove extra spaces and normalize
    text = text.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Common Arabic corrections
    final corrections = {
      'مرحبا': 'مرحباً',
      'صباح الخير': 'صباح الخير',
      'مساء الخير': 'مساء الخير',
      'شكرا': 'شكراً',
      'الى': 'إلى',
      'ان': 'أن',
      'انا': 'أنا',
      'انت': 'أنت',
      'هو': 'هو',
      'هي': 'هي',
      'هم': 'هم',
    };

    // Apply word-by-word corrections
    var words = text.split(' ');
    for (int i = 0; i < words.length; i++) {
      final word = words[i].trim();
      if (corrections.containsKey(word)) {
        words[i] = corrections[word]!;
      }

      // Handle common ending corrections
      if (word.endsWith('ه') && word.length > 2) {
        final feminineWords = [
          'سيار',
          'شجر',
          'مدر',
          'طاول',
          'ساع',
          'بيت',
          'غرف',
          'شباب',
          'طريق',
        ];
        final stem = word.substring(0, word.length - 1);
        if (feminineWords.contains(stem)) {
          words[i] = '$stemة';
        }
      }
    }

    return words.join(' ');
  }

  /// Basic English text cleaning and capitalization.
  static String cleanEnglishText(String text) {
    if (text.isEmpty) return text;

    // Basic English text cleaning
    text = text.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Capitalize first letter of sentences
    if (text.length > 1) {
      text = text[0].toUpperCase() + text.substring(1);
    }

    return text;
  }

  /// Check if the new text is a duplicate or extremely similar to recent entries.
  static bool isDuplicateText(String newText, String lastFinalText, List<String> history) {
    if (newText.isEmpty) return true;

    // Check if it's exactly the same as the last final text
    if (newText == lastFinalText) return true;

    // Check if it's very similar to recent texts (fuzzy match)
    for (final previousText in history) {
      if (textsAreVerySimilar(newText, previousText)) {
        return true;
      }
    }

    return false;
  }

  /// Calculates word overlap or exact matching to find fuzzy duplicates.
  static bool textsAreVerySimilar(String text1, String text2) {
    if (text1 == text2) return true;

    // Simple similarity check - if one text contains the other (for partial duplicates)
    if (text1.contains(text2) || text2.contains(text1)) {
      return true;
    }

    // Check word overlap (more than 70% similar words)
    final words1 = text1.toLowerCase().split(' ');
    final words2 = text2.toLowerCase().split(' ');

    if (words1.length < 3 || words2.length < 3) return false;

    final commonWords = words1.where((word) => words2.contains(word)).length;
    final similarity = commonWords / math.max(words1.length, words2.length);

    return similarity > 0.7;
  }

  /// Determines if partial results should be updated, preventing flickering.
  static bool shouldUpdatePartialText(String newText, String currentText) {
    if (currentText.isEmpty) return true;

    // Don't update if the new text is just a subset of the current text
    final currentWords = currentText.split(' ');
    final newWords = newText.split(' ');

    if (newWords.length < currentWords.length - 1) return false;

    // Update if there's significant difference
    return newText != currentText;
  }
}
