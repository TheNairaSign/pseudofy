import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pseudofy/providers/providers.dart';

/// Multi-select paradigm filter chips. Purely a hint passed alongside the
/// problem text to the classifier — it doesn't filter library entries
/// client-side.
class ParadigmChips extends ConsumerWidget {
  const ParadigmChips({super.key, required this.paradigms});
  final List<String> paradigms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(problemInputProvider).selectedParadigms;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: paradigms.map((p) {
        return FilterChip(
          label: Text(p),
          selected: selected.contains(p),
          onSelected: (_) => ref.read(problemInputProvider.notifier).toggleParadigm(p),
        );
      }).toList(),
    );
  }
}
