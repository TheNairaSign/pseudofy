import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pseudofy/library/library_entry.dart';
import 'package:pseudofy/core/services/local_classifier.dart';
import 'package:pseudofy/core/solution_model.dart';

/// The single network-touching class in the whole app. Everything else
/// (library lookup, substitution, UI) is pure Dart and offline.
///
/// When no ANTHROPIC_API_KEY is configured, [classify] falls back to
/// [LocalClassifier] instead of throwing — so the rest of the app can be
/// exercised end to end without a key. That fallback path stays fully
/// offline; it's a dev/test convenience, not a replacement for real
/// classification.
class ClassificationService {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-5';

  // Read at build time: flutter run --dart-define=ANTHROPIC_API_KEY=sk-...
  // Never hardcode the key in source.
  static const _apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');

  final Map<String, ProblemEntry> library;
  ClassificationService(this.library);

  Future<ClassificationResult> classify({
    required String problemText,
    List<String>? paradigmFilter,
  }) async {
    if (_apiKey.isEmpty) {
      return LocalClassifier(library).classify(
        problemText,
        paradigmFilter: paradigmFilter,
      );
    }

    final systemPrompt = buildClassificationSystemPrompt(library);
    var userMessage = 'Problem: $problemText';
    if (paradigmFilter != null && paradigmFilter.isNotEmpty) {
      userMessage += '\nUser wants specifically these paradigms if available: '
          '${paradigmFilter.join(", ")}';
    }

    final result = await _callAndParse(systemPrompt, userMessage);
    if (result != null) return result;

    // One retry, with an explicit correction — covers the case where
    // the model wrapped JSON in prose or markdown fences despite instructions.
    final retryResult = await _callAndParse(
      systemPrompt,
      '$userMessage\n\nYour previous response was not valid JSON matching '
      'the required shape. Return ONLY the JSON object, nothing else.',
    );
    if (retryResult != null) return retryResult;

    throw const FormatException(
      'Claude did not return valid classification JSON after retry.',
    );
  }

  Future<ClassificationResult?> _callAndParse(
    String systemPrompt,
    String userMessage,
  ) async {
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 500, // classification JSON is small
        'system': systemPrompt,
        'messages': [
          {'role': 'user', 'content': userMessage},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw HttpException(
        'Claude API error ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final contentBlocks = data['content'] as List<dynamic>;
    final text = contentBlocks
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String)
        .join();

    final cleaned = text
        .replaceAll(RegExp(r'^```json\s*'), '')
        .replaceAll(RegExp(r'```\s*$'), '')
        .trim();

    try {
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final result = ClassificationResult.fromJson(json);
      // Basic sanity check beyond just "parses" — guards against the
      // model inventing an id outside the closed catalog.
      if (result.matchedProblemId != null && !library.containsKey(result.matchedProblemId)) {
        return ClassificationResult(
          matchedProblemId: null,
          confidence: 0,
          extractedParams: result.extractedParams,
          namingContext: result.namingContext,
          alternativeMatches: result.alternativeMatches,
        );
      }
      return result;
    } catch (_) {
      return null; // triggers the one retry in classify()
    }
  }
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  @override
  String toString() => message;
}