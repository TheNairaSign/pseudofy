import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pseudofy/providers/providers.dart';
import 'package:pseudofy/widgets/algorithm_dropdown.dart';
import 'package:pseudofy/widgets/library_browser.dart';
import 'package:pseudofy/widgets/paradigm_dropdown.dart';

const _expandedWidth = 272.0;
const _collapsedWidth = 56.0;

/// Collapsible left rail holding everything that isn't the immediate
/// input/output workspace: quick-jump algorithm/paradigm dropdowns and the
/// full library browse list.
class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(sidebarExpandedProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      width: expanded ? _expandedWidth : _collapsedWidth,
      // Empty decoration + hardEdge clip lets the outer box crop the inner
      // content as it animates, instead of squeezing it — content below
      // (the library ListTiles in particular) needs its full target width
      // to lay out validly at every point in the animation, not just at
      // rest, or it throws mid-transition. A plain SizedBox isn't enough
      // here: this Container's own `width` imposes a *tight* constraint
      // that would still override a child's requested size, so the child
      // needs OverflowBox to actually ignore the incoming constraint.
      decoration: const BoxDecoration(),
      clipBehavior: Clip.hardEdge,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: _expandedWidth,
          maxWidth: _expandedWidth,
          child: expanded ? const _ExpandedSidebar() : const _CollapsedSidebar(),
        ),
      ),
    );
  }
}

class _CollapsedSidebar extends ConsumerWidget {
  const _CollapsedSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Content lives in a fixed-width (_expandedWidth) canvas that the
    // parent clips down to _collapsedWidth — align left so what remains
    // visible after clipping is the icon, not empty space.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Expand sidebar',
          onPressed: () => ref.read(sidebarExpandedProvider.notifier).setExpanded(true),
        ),
      ],
    );
  }
}

class _ExpandedSidebar extends ConsumerWidget {
  const _ExpandedSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Text('Pseudofy', style: Theme.of(context).textTheme.titleMedium),
              ),
              IconButton(
                icon: const Icon(Icons.menu_open),
                tooltip: 'Collapse sidebar',
                onPressed: () => ref.read(sidebarExpandedProvider.notifier).setExpanded(false),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: AlgorithmDropdown(),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: ParadigmDropdown(),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Divider(height: 1),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('Library', style: Theme.of(context).textTheme.labelLarge),
        ),
        const Expanded(child: LibraryBrowser()),
      ],
    );
  }
}
