import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pseudofy/providers/providers.dart';

/// Quick-jump selector: pick a catalog entry directly, bypassing
/// classification (same effect as tapping it in the library list below).
class AlgorithmDropdown extends ConsumerWidget {
  const AlgorithmDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(algorithmLibraryProvider);
    final matchedId = ref.watch(classificationProvider).value?.matchedProblemId;
    final value = matchedId != null && library.containsKey(matchedId) ? matchedId : null;

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Algorithm',
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: const Text('Jump to…'),
          items: [
            for (final entry in library.values)
              DropdownMenuItem(value: entry.id, child: Text(entry.title, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (id) {
            if (id != null) ref.read(classificationProvider.notifier).selectManually(id);
          },
        ),
      ),
    );
  }
}
