import 'dart:math';

class RankedExercise {
  final String name;
  final int score;

  const RankedExercise(this.name, this.score);
}

class ExerciseSearchHelper {
  /// Ranks a list of candidate exercise names based on how closely they match the [query].
  /// Returns a sorted list of exercise names by relevance (highest score first).
  static List<String> searchAndRank({
    required String query,
    required List<String> candidates,
  }) {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) return candidates;

    final queryWords = trimmedQuery.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final List<RankedExercise> ranked = [];

    for (final name in candidates) {
      final nameLower = name.toLowerCase();
      final nameWords = nameLower.split(RegExp(r'[\s\-\(\)]+')).where((w) => w.isNotEmpty).toList();

      int score = 0;

      // 1. Exact match
      if (nameLower == trimmedQuery) {
        score = 1000;
      }
      // 2. Starts with full query string
      else if (nameLower.startsWith(trimmedQuery)) {
        score = 800 + max(0, 50 - nameLower.length);
      }
      // 3. Word starts with full query string
      else if (nameWords.any((w) => w.startsWith(trimmedQuery))) {
        score = 600 + max(0, 50 - nameLower.length);
      }
      // 4. Token match - All query words exist in exercise name
      else if (queryWords.every((qw) => nameWords.any((nw) => nw.contains(qw)))) {
        score = 400 + max(0, 50 - nameLower.length);
      }
      // 5. General Substring match
      else if (nameLower.contains(trimmedQuery)) {
        score = 300;
      }
      // 6. Fuzzy matching (Typo tolerance)
      else if (trimmedQuery.length >= 3) {
        int minDistance = 999;
        for (final nw in nameWords) {
          final dist = _levenshteinDistance(trimmedQuery, nw);
          if (dist < minDistance) minDistance = dist;
        }

        // Allow 1 typo for 3-4 char queries, 2 typos for 5+ char queries
        final maxAllowedTypo = trimmedQuery.length >= 5 ? 2 : 1;
        if (minDistance <= maxAllowedTypo) {
          score = 200 - (minDistance * 50);
        }
      }

      if (score > 0) {
        ranked.add(RankedExercise(name, score));
      }
    }

    // Sort by score descending
    ranked.sort((a, b) => b.score.compareTo(a.score));

    return ranked.map((e) => e.name).toList();
  }

  /// Returns top N suggestion names for quick-selection chips.
  static List<String> getTopSuggestions({
    required String query,
    required List<String> candidates,
    int limit = 5,
  }) {
    if (query.trim().isEmpty) return [];
    final ranked = searchAndRank(query: query, candidates: candidates);
    return ranked.take(limit).toList();
  }

  /// Calculates Levenshtein Distance between two strings.
  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final v0 = List<int>.generate(s2.length + 1, (i) => i);
    final v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        final cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce(min);
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }
}
