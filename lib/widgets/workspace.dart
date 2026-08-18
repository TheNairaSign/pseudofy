import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pseudofy/core/solution_model.dart';
import 'package:pseudofy/providers/providers.dart';
import 'package:pseudofy/widgets/code_view.dart';
import 'package:pseudofy/widgets/flowchart_view.dart';
import 'package:pseudofy/widgets/pseudocode_view.dart';

/// Right-hand IDE pane: a breadcrumb/variant bar, the Pseudocode/Flowchart/
/// Code view-mode tabs (persistent across variant/algorithm switches), and
/// a docked problem-input bar pinned to the bottom.
class MainWorkspace extends StatelessWidget {
  const MainWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Expanded(child: _ContentArea()),
        _BottomInputBar(),
      ],
    );
  }
}

class _ContentArea extends ConsumerStatefulWidget {
  const _ContentArea();

  @override
  ConsumerState<_ContentArea> createState() => _ContentAreaState();
}

class _ContentAreaState extends ConsumerState<_ContentArea> with SingleTickerProviderStateMixin {
  late final TabController _viewModeController;
  int _variantIndex = 0;

  @override
  void initState() {
    super.initState();
    // Created eagerly (not as a lazy `late` initializer) so it always
    // exists by the time dispose() runs, even if this widget is torn down
    // without ever rendering a matched solution (_SolutionTabs) — a lazy
    // field would otherwise run its vsync-dependent initializer *inside*
    // dispose(), on an already-deactivated element.
    _viewModeController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _viewModeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Switching to a different matched problem resets which variant is
    // shown, but deliberately leaves _viewModeController alone — if the
    // user was on the Code tab, jumping to another algorithm should keep
    // them on Code.
    ref.listen(classificationProvider, (previous, next) {
      if (previous?.value?.matchedProblemId != next.value?.matchedProblemId) {
        setState(() => _variantIndex = 0);
      }
    });

    final outcome = ref.watch(classificationOutcomeProvider);
    final solutions =
        outcome == ClassificationOutcome.matched ? ref.watch(solutionsProvider) : const <SolutionModel>[];
    final variantIndex = solutions.isEmpty ? 0 : _variantIndex.clamp(0, solutions.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Breadcrumb(
          outcome: outcome,
          solutions: solutions,
          variantIndex: variantIndex,
          onVariantChanged: (i) => setState(() => _variantIndex = i),
        ),
        const Divider(height: 1),
        Expanded(
          child: switch (outcome) {
            ClassificationOutcome.idle => const _EmptyState(
                message: 'Pick an algorithm from the sidebar, or describe a problem below.',
              ),
            ClassificationOutcome.loading => const Center(child: CircularProgressIndicator()),
            ClassificationOutcome.matched => solutions.isEmpty
                ? const _EmptyState(message: 'No variants available for this problem yet.')
                : _SolutionTabs(controller: _viewModeController, solution: solutions[variantIndex]),
            ClassificationOutcome.noMatch => const _NoMatchState(),
            ClassificationOutcome.error => const _ErrorState(),
          },
        ),
      ],
    );
  }
}

class _Breadcrumb extends ConsumerWidget {
  const _Breadcrumb({
    required this.outcome,
    required this.solutions,
    required this.variantIndex,
    required this.onVariantChanged,
  });

  final ClassificationOutcome outcome;
  final List<SolutionModel> solutions;
  final int variantIndex;
  final ValueChanged<int> onVariantChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confidence = ref.watch(classificationProvider).value?.confidence;
    final matched = outcome == ClassificationOutcome.matched && solutions.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              matched ? solutions.first.problemTitle : _statusLabel(outcome),
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (matched && solutions.length > 1) ...[
            DropdownButton<int>(
              value: variantIndex,
              underline: const SizedBox.shrink(),
              items: [
                for (var i = 0; i < solutions.length; i++)
                  DropdownMenuItem(value: i, child: Text(solutions[i].paradigm)),
              ],
              onChanged: (i) => i == null ? null : onVariantChanged(i),
            ),
            const SizedBox(width: 12),
          ],
          if (matched && confidence != null) ...[
            Text('${(confidence * 100).round()}% match', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 4),
          ],
          if (matched)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Back to start',
              onPressed: () => ref.read(classificationProvider.notifier).reset(),
            ),
        ],
      ),
    );
  }

  String _statusLabel(ClassificationOutcome outcome) => switch (outcome) {
        ClassificationOutcome.idle => 'No algorithm selected',
        ClassificationOutcome.loading => 'Solving…',
        ClassificationOutcome.noMatch => 'No confident match',
        ClassificationOutcome.error => 'Something went wrong',
        ClassificationOutcome.matched => '',
      };
}

class _SolutionTabs extends StatelessWidget {
  const _SolutionTabs({required this.controller, required this.solution});
  final TabController controller;
  final SolutionModel solution;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: controller,
                  tabs: const [
                    Tab(text: 'Pseudocode'),
                    Tab(text: 'Flowchart'),
                    Tab(text: 'Code'),
                  ],
                ),
              ),
              Text(
                'Time ${solution.complexityTime} · Space ${solution.complexitySpace}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: [
              PseudocodeView(text: solution.pseudocode),
              FlowchartView(data: solution.flowchart),
              CodeView(code: solution.code),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
}

class _NoMatchState extends ConsumerWidget {
  const _NoMatchState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(classificationProvider).value;
    final library = ref.watch(algorithmLibraryProvider);
    final alternatives =
        (result?.alternativeMatches ?? const []).where(library.containsKey).toList();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Couldn't confidently match that to a known problem."),
            if (alternatives.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Did you mean:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: alternatives
                    .map((id) => ActionChip(
                          label: Text(library[id]!.title),
                          onPressed: () =>
                              ref.read(classificationProvider.notifier).selectManually(id),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            const Text('Or pick one from the sidebar.'),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends ConsumerWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(classificationProvider).error;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          error?.toString() ?? 'Unknown error',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}

class _BottomInputBar extends ConsumerWidget {
  const _BottomInputBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outcome = ref.watch(classificationOutcomeProvider);
    final input = ref.watch(problemInputProvider);
    final loading = outcome == ClassificationOutcome.loading;
    final canSolve = !loading && input.text.trim().isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const Key('problemInput'),
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  hintText: 'Describe your problem… e.g. "Help Maria sort her exam papers"',
                ),
                onChanged: (text) => ref.read(problemInputProvider.notifier).setText(text),
                onSubmitted: (_) {
                  if (canSolve) ref.read(classificationProvider.notifier).solve();
                },
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: const Key('solveButton'),
              onPressed: canSolve ? () => ref.read(classificationProvider.notifier).solve() : null,
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Solve'),
            ),
          ],
        ),
      ),
    );
  }
}
