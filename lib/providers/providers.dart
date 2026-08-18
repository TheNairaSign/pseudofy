import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pseudofy/library/library_entry.dart';
import 'package:pseudofy/core/naming_context.dart';
import 'package:pseudofy/core/services/classification_service.dart';
import 'package:pseudofy/core/solution_model.dart';
import 'package:pseudofy/library/library_samples.dart' show algorithmLibrary;

// ---------- Input state ----------

class ProblemInput {
  final String text;
  final List<String> selectedParadigms;
  const ProblemInput({this.text = '', this.selectedParadigms = const []});

  ProblemInput copyWith({String? text, List<String>? selectedParadigms}) =>
    ProblemInput(
      text: text ?? this.text,
      selectedParadigms: selectedParadigms ?? this.selectedParadigms,
    );
}

class ProblemInputNotifier extends Notifier<ProblemInput> {
  @override
  ProblemInput build() => const ProblemInput();

  void setText(String text) => state = state.copyWith(text: text);

  void toggleParadigm(String paradigm) {
    final current = List<String>.from(state.selectedParadigms);
    current.contains(paradigm) ? current.remove(paradigm) : current.add(paradigm);
    state = state.copyWith(selectedParadigms: current);
  }
}

final problemInputProvider = NotifierProvider<ProblemInputNotifier, ProblemInput>(ProblemInputNotifier.new);

// ---------- Service + library (no network until classify() is called) ----------

final algorithmLibraryProvider = Provider<Map<String, ProblemEntry>>((ref) {
  return algorithmLibrary;
});

final classificationServiceProvider = Provider<ClassificationService>((ref) {
  return ClassificationService(ref.watch(algorithmLibraryProvider));
});

// ---------- Classification: the AsyncNotifier that makes the one API call ----------

class ClassificationNotifier extends AsyncNotifier<ClassificationResult?> {
  @override
  Future<ClassificationResult?> build() async => null; // nothing until Solve is pressed

  Future<void> solve() async {
    final input = ref.read(problemInputProvider);
    if (input.text.trim().isEmpty) return;

    state = const AsyncLoading();
    final service = ref.read(classificationServiceProvider);

    state = await AsyncValue.guard(() {
      return service.classify(
        problemText: input.text,
        paradigmFilter: input.selectedParadigms.isEmpty ? null : input.selectedParadigms,
      );
    });
  }

  /// Bypasses classification entirely — used when the user picks a problem
  /// directly from an alternative-match chip or the library browser.
  void selectManually(String problemId) {
    state = AsyncData(
      ClassificationResult(
        matchedProblemId: problemId,
        confidence: 1.0,
        extractedParams: const {},
        namingContext: const NamingContext(),
        alternativeMatches: const [],
      ),
    );
  }

  /// Returns to the idle/library-browsing state.
  void reset() => state = const AsyncData(null);
}

final classificationProvider = AsyncNotifierProvider<ClassificationNotifier, ClassificationResult?>(
  ClassificationNotifier.new,
);

// ---------- Solutions: pure Dart derivation, no AI, no network ----------

final solutionsProvider = Provider<List<SolutionModel>>((ref) {
  final classificationAsync = ref.watch(classificationProvider);
  final library = ref.watch(algorithmLibraryProvider);

  return classificationAsync.when(
    data: (classification) {
      if (classification == null) return [];
      return resolveSolutions(classification, library);
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

// ---------- Convenience: did we get a match, or should the UI show fallback? ----------

enum ClassificationOutcome { idle, loading, matched, noMatch, error }

final classificationOutcomeProvider = Provider<ClassificationOutcome>((ref) {
  final async = ref.watch(classificationProvider);
  return async.when(
    data: (result) {
      if (result == null) return ClassificationOutcome.idle;
      return result.matchedProblemId != null
          ? ClassificationOutcome.matched
          : ClassificationOutcome.noMatch;
    },
    loading: () => ClassificationOutcome.loading,
    error: (_, _) => ClassificationOutcome.error,
  );
});