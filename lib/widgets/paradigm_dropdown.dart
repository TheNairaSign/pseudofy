import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pseudofy/providers/providers.dart';

const _paradigms = [
  'Divide and Conquer',
  'Backtracking',
  'Dynamic Programming',
  'Greedy',
  'Branch and Bound',
  'Brute Force',
  'Two Pointers',
];

/// Optional paradigm/operation filter, sent alongside the problem text as a
/// hint to the classifier. Single-select — "Any" clears it.
class ParadigmDropdown extends ConsumerWidget {
  const ParadigmDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(problemInputProvider).selectedParadigms;
    final value = selected.isEmpty ? null : selected.first;

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Paradigm',
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          items: [
            const DropdownMenuItem(value: null, child: Text('Any')),
            for (final p in _paradigms) DropdownMenuItem(value: p, child: Text(p)),
          ],
          onChanged: (p) => ref.read(problemInputProvider.notifier).setParadigm(p),
        ),
      ),
    );
  }
}
