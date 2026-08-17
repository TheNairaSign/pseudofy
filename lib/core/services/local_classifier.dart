import 'package:pseudofy/core/naming_context.dart';
import 'package:pseudofy/core/solution_model.dart';
import 'package:pseudofy/library/library_entry.dart';

/// Offline fallback used by [ClassificationService] when no API key is
/// configured. Pure Dart, deterministic word-overlap matching against the
/// closed catalog's titles/tags — good enough to exercise the full
/// classify -> lookup -> substitute -> render pipeline without a network
/// call. Not a substitute for the real model's language understanding.
class LocalClassifier {
  final Map<String, ProblemEntry> library;
  const LocalClassifier(this.library);

  static final _wordSplit = RegExp(r'[^a-z0-9]+');
  static const _matchThreshold = 2;

  ClassificationResult classify(
    String problemText, {
    List<String>? paradigmFilter,
  }) {
    final lower = problemText.toLowerCase();
    final textWords = lower.split(_wordSplit).where((w) => w.isNotEmpty).toSet();
    final wantedParadigms = (paradigmFilter ?? const [])
        .map((p) => p.toLowerCase())
        .toSet();

    final scores = <String, int>{};
    for (final entry in library.values) {
      var score = 0;
      for (final phrase in [entry.title, ...entry.tags]) {
        final phraseWords =
            phrase.toLowerCase().split(_wordSplit).where((w) => w.isNotEmpty);
        score += phraseWords.where(textWords.contains).length;
      }
      if (wantedParadigms.isNotEmpty &&
          entry.variants.keys.any((v) => wantedParadigms.contains(v.toLowerCase()))) {
        score += 1;
      }
      if (score > 0) scores[entry.id] = score;
    }

    final ranked = scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));

    if (ranked.isEmpty) {
      return ClassificationResult(
        matchedProblemId: null,
        confidence: 0,
        extractedParams: _extractParams(lower),
        namingContext: _extractNaming(problemText),
        alternativeMatches: library.keys.take(3).toList(),
      );
    }

    final bestId = ranked.first;
    final bestScore = scores[bestId]!;
    final confidence = (bestScore / 5).clamp(0.0, 1.0);
    final isMatch = bestScore >= _matchThreshold;

    return ClassificationResult(
      matchedProblemId: isMatch ? bestId : null,
      confidence: confidence,
      extractedParams: _extractParams(lower),
      namingContext: _extractNaming(problemText),
      alternativeMatches: ranked.where((id) => id != bestId || !isMatch).take(3).toList(),
    );
  }

  Map<String, dynamic> _extractParams(String lowerText) {
    final params = <String, dynamic>{};
    final nMatch = RegExp(r'\bn\s*=\s*(\d+)\b').firstMatch(lowerText) ??
        RegExp(r'\b(\d+)\s*[- ]?queens\b').firstMatch(lowerText) ??
        RegExp(r'\bboard(?:\s*of|\s*size)?\s*(\d+)\b').firstMatch(lowerText);
    if (nMatch != null) params['n'] = int.parse(nMatch.group(1)!);

    final targetMatch =
        RegExp(r'\btarget\s*(?:of|is|=)?\s*(\d+)\b').firstMatch(lowerText);
    if (targetMatch != null) params['target'] = int.parse(targetMatch.group(1)!);

    return params;
  }

  NamingContext _extractNaming(String originalText) {
    final values = <String, String>{};
    final personMatch =
        RegExp(r'\b(?:help|for)\s+([A-Z][a-z]+)\b').firstMatch(originalText);
    if (personMatch != null) values['person'] = personMatch.group(1)!;
    return NamingContext(values: values);
  }
}
