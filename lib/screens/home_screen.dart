import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pseudofy/providers/providers.dart';
import 'package:pseudofy/widgets/library_browser.dart';
import 'package:pseudofy/widgets/paradigm_chips.dart';
import 'package:pseudofy/widgets/solution_view.dart';

const _paradigms = [
  'Divide and Conquer',
  'Backtracking',
  'Dynamic Programming',
  'Greedy',
  'Branch and Bound',
  'Brute Force',
  'Two Pointers',
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pseudofy')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _ProblemInput(),
              const SizedBox(height: 12),
              const ParadigmChips(paradigms: _paradigms),
              const SizedBox(height: 12),
              const _SolveButton(),
              const SizedBox(height: 16),
              const Expanded(child: _ResultsArea()),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProblemInput extends ConsumerWidget {
  const _ProblemInput();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      key: const Key('problemInput'),
      minLines: 2,
      maxLines: 4,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Describe your problem',
        hintText: 'e.g. "Help Maria sort her stack of exam papers by score"',
      ),
      onChanged: (text) => ref.read(problemInputProvider.notifier).setText(text),
    );
  }
}

class _SolveButton extends ConsumerWidget {
  const _SolveButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outcome = ref.watch(classificationOutcomeProvider);
    final input = ref.watch(problemInputProvider);
    final loading = outcome == ClassificationOutcome.loading;

    return FilledButton(
      key: const Key('solveButton'),
      onPressed: loading || input.text.trim().isEmpty
          ? null
          : () => ref.read(classificationProvider.notifier).solve(),
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Solve'),
    );
  }
}

class _ResultsArea extends ConsumerWidget {
  const _ResultsArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outcome = ref.watch(classificationOutcomeProvider);

    return switch (outcome) {
      ClassificationOutcome.idle => const _BrowseSection(),
      ClassificationOutcome.loading => const Center(child: CircularProgressIndicator()),
      ClassificationOutcome.matched => const _MatchedView(),
      ClassificationOutcome.noMatch => const _NoMatchView(),
      ClassificationOutcome.error => const _ErrorView(),
    };
  }
}

class _BrowseSection extends StatelessWidget {
  const _BrowseSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Browse the library', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        const Expanded(child: LibraryBrowser()),
      ],
    );
  }
}

class _MatchedView extends ConsumerWidget {
  const _MatchedView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solutions = ref.watch(solutionsProvider);
    final confidence = ref.watch(classificationProvider).value?.confidence;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (solutions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    solutions.first.problemTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (confidence != null)
                  Text(
                    '${(confidence * 100).round()}% match',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Back to library',
                  onPressed: () => ref.read(classificationProvider.notifier).reset(),
                ),
              ],
            ),
          ),
        Expanded(child: SolutionView(solutions: solutions)),
      ],
    );
  }
}

class _NoMatchView extends ConsumerWidget {
  const _NoMatchView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(classificationProvider).value;
    final library = ref.watch(algorithmLibraryProvider);
    final alternatives =
        (result?.alternativeMatches ?? const []).where(library.containsKey).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Couldn't confidently match that to a known problem.",
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (alternatives.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Did you mean:'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: alternatives
                  .map((id) => ActionChip(
                        label: Text(library[id]!.title),
                        onPressed: () =>
                            ref.read(classificationProvider.notifier).selectManually(id),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 20),
          Text('Or browse the library:', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          const LibraryBrowser(shrinkWrap: true),
        ],
      ),
    );
  }
}

class _ErrorView extends ConsumerWidget {
  const _ErrorView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(classificationProvider).error;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Something went wrong classifying that problem.',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error?.toString() ?? 'Unknown error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ),
    );
  }
}
