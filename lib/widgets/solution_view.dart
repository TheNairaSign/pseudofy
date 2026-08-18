import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pseudofy/core/solution_model.dart';
import 'package:pseudofy/widgets/code_view.dart';
import 'package:pseudofy/widgets/flowchart_view.dart';

/// Outer tab per resolved paradigm variant; inner tab for
/// Pseudocode / Flowchart / Code, per the app-flow doc's workspace UI.
class SolutionView extends StatelessWidget {
  const SolutionView({super.key, required this.solutions});
  final List<SolutionModel> solutions;

  @override
  Widget build(BuildContext context) {
    if (solutions.isEmpty) {
      return const Center(child: Text('No variants available for this problem yet.'));
    }

    return DefaultTabController(
      length: solutions.length,
      child: Column(
        children: [
          if (solutions.length > 1)
            TabBar(
              isScrollable: true,
              tabs: [for (final s in solutions) Tab(text: s.paradigm)],
            ),
          Expanded(
            child: TabBarView(
              children: [for (final s in solutions) _VariantView(solution: s)],
            ),
          ),
        ],
      ),
    );
  }
}

class _VariantView extends StatelessWidget {
  const _VariantView({required this.solution});
  final SolutionModel solution;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Time ${solution.complexityTime}  ·  Space ${solution.complexitySpace}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Pseudocode'),
              Tab(text: 'Flowchart'),
              Tab(text: 'Code'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _TextBlock(text: solution.pseudocode),
                FlowchartView(data: solution.flowchart),
                CodeView(code: solution.code),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: SelectableText(
            text,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: IconButton(
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Copy',
            onPressed: () => Clipboard.setData(ClipboardData(text: text)),
          ),
        ),
      ],
    );
  }
}
