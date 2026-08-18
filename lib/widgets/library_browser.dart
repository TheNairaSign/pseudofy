import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pseudofy/providers/providers.dart';

/// Lists every catalog entry so the user can browse/search directly instead
/// of going through classification — used both as the idle-state default
/// and inside the no-match fallback.
class LibraryBrowser extends ConsumerWidget {
  const LibraryBrowser({super.key, this.shrinkWrap = false});
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(algorithmLibraryProvider).values.toList();

    if (entries.isEmpty) {
      return const Center(child: Text('The library is empty.'));
    }

    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: entries.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return ListTile(
          title: Text(entry.title),
          subtitle: Text(entry.tags.join(', ')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => ref.read(classificationProvider.notifier).selectManually(entry.id),
        );
      },
    );
  }
}
