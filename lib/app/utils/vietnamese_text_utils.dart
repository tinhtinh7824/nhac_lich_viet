class VietnameseTextUtils {
  /// Remove Vietnamese diacritics from text
  static String removeDiacritics(String text) {
    const vietnamese = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
        'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
    const normalized = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
        'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';

    String result = text;
    for (int i = 0; i < vietnamese.length; i++) {
      result = result.replaceAll(vietnamese[i], normalized[i]);
    }
    return result;
  }

  /// Normalize text for comparison (lowercase + remove diacritics)
  static String normalize(String text) {
    return removeDiacritics(text.toLowerCase().trim());
  }

  /// Fuzzy match between keyword and text (Vietnamese-aware)
  static bool fuzzyMatch(String keyword, String text) {
    if (keyword.isEmpty || text.isEmpty) return false;

    final normalizedKeyword = normalize(keyword);
    final normalizedText = normalize(text);

    // Exact match
    if (normalizedText.contains(normalizedKeyword)) {
      return true;
    }

    // Word-by-word match
    final keywordWords = normalizedKeyword.split(' ');
    int matchedWords = 0;
    for (final word in keywordWords) {
      if (word.isEmpty) continue;
      if (normalizedText.contains(word)) {
        matchedWords++;
      }
    }

    // Consider a match if at least 50% of words match
    return matchedWords >= (keywordWords.length * 0.5);
  }

  /// Calculate similarity score between two strings (0.0 to 1.0)
  static double calculateSimilarity(String keyword, String text) {
    if (keyword.isEmpty || text.isEmpty) return 0.0;

    final normalizedKeyword = normalize(keyword);
    final normalizedText = normalize(text);

    // Exact match = 1.0
    if (normalizedText == normalizedKeyword) return 1.0;

    // Contains match = 0.8
    if (normalizedText.contains(normalizedKeyword)) return 0.8;

    // Word-by-word similarity
    final keywordWords = normalizedKeyword.split(' ');
    final textWords = normalizedText.split(' ');

    if (keywordWords.isEmpty || textWords.isEmpty) return 0.0;

    int matchedWords = 0;
    for (final kwWord in keywordWords) {
      if (kwWord.isEmpty) continue;
      for (final txtWord in textWords) {
        if (txtWord.isEmpty) continue;
        if (txtWord.contains(kwWord) || kwWord.contains(txtWord)) {
          matchedWords++;
          break;
        }
      }
    }

    // Return ratio of matched words
    return matchedWords / keywordWords.length;
  }

  /// Check if text starts with keyword (Vietnamese-aware)
  static bool startsWith(String text, String keyword) {
    if (keyword.isEmpty) return true;
    final normalizedText = normalize(text);
    final normalizedKeyword = normalize(keyword);
    return normalizedText.startsWith(normalizedKeyword);
  }

  /// Extract first letter of each word for abbreviation search
  static String getAbbreviation(String text) {
    final words = normalize(text).split(' ');
    return words.map((w) => w.isNotEmpty ? w[0] : '').join('');
  }

  /// Match by abbreviation (e.g., "tnlt" matches "Tet Nguyen Lieu Tieu")
  static bool matchAbbreviation(String keyword, String text) {
    if (keyword.isEmpty || text.isEmpty) return false;
    final abbr = getAbbreviation(text);
    final normalizedKeyword = normalize(keyword);
    return abbr.contains(normalizedKeyword);
  }
}
