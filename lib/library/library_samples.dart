// ============================================================
// LIBRARY DATA — imports core_models.dart but contains none of
// the generic architecture. This file only ever grows by adding
// more ProblemEntry constants; it never touches core_models.dart.
// ============================================================

import 'package:pseudofy/library/library_entry.dart';
import 'package:pseudofy/core/naming_context.dart';
import 'package:pseudofy/core/representation/flow_chart/flow_node.dart';
import 'package:pseudofy/core/solution_model.dart';


final Map<String, ProblemEntry> algorithmLibrary = {
  'merge_sort': ProblemEntry(
    id: 'merge_sort',
    title: 'Merge Sort',
    tags: ['merge sort', 'sorting', 'sort array', 'divide and conquer sort'],
    variants: {
      'Divide and Conquer': ParadigmVariant(
        // Sensible fallback if the AI found no naming context at all.
        defaultNaming: const NamingContext(values: {
          'person': 'the user',
          'object': 'the items',
        }),
        pseudocodeTemplate: '''
function sort{{object}}({{object}}):
    if length of {{object}} <= 1:
        return {{object}}
    mid = length of {{object}} / 2
    left = sort(first half of {{object}})
    right = sort(second half of {{object}})
    return merge(left, right)

// {{person}} ends up with {{object}}, fully sorted.
''',
        flowchart: const FlowchartData(
          nodes: [
            FlowNode(id: 'start', type: 'start', label: 'Start: {{object}}', x: 40, y: 20),
            FlowNode(id: 'base', type: 'decision', label: 'Length <= 1?', x: 40, y: 100),
            FlowNode(id: 'done', type: 'end', label: 'Return as-is', x: 300, y: 100),
            FlowNode(id: 'split', type: 'process', label: 'Split in half', x: 40, y: 184),
            FlowNode(id: 'recurse', type: 'process', label: 'Sort each half', x: 40, y: 268),
            FlowNode(id: 'merge', type: 'process', label: 'Merge sorted halves', x: 40, y: 352),
          ],
          edges: [
            FlowEdge(from: 'start', to: 'base'),
            FlowEdge(from: 'base', to: 'done', label: 'yes'),
            FlowEdge(from: 'base', to: 'split', label: 'no'),
            FlowEdge(from: 'split', to: 'recurse'),
            FlowEdge(from: 'recurse', to: 'merge'),
          ],
        ),
        codeTemplates: {
          'dart': '''
// Sorts {{object}} for {{person}}.
List<int> sort{{object}}(List<int> {{object}}) {
  if ({{object}}.length <= 1) return {{object}};
  final mid = {{object}}.length ~/ 2;
  final left = sort{{object}}({{object}}.sublist(0, mid));
  final right = sort{{object}}({{object}}.sublist(mid));
  return _merge(left, right);
}

List<int> _merge(List<int> left, List<int> right) {
  final result = <int>[];
  var i = 0, j = 0;
  while (i < left.length && j < right.length) {
    result.add(left[i] <= right[j] ? left[i++] : right[j++]);
  }
  result.addAll(left.sublist(i));
  result.addAll(right.sublist(j));
  return result;
}
''',
        },
        complexityTime: 'O(n log n)',
        complexitySpace: 'O(n)',
      ),
    },
  ),
};

// ---------- Example: naming context flowing end to end ----------

void exampleUsage() {
  // Simulated AI response for user input:
  // "Help Maria sort her stack of exam papers by score"
  final classification = ClassificationResult.fromJson({
    'matchedProblemId': 'merge_sort',
    'confidence': 0.9,
    'extractedParams': {},
    'namingContext': {'person': 'Maria', 'object': 'examPapers'},
    'alternativeMatches': [],
  });

  final solutions = resolveSolutions(classification, algorithmLibrary);
  // solutions.first.pseudocode now reads "function sortExamPapers(examPapers): ..."
  // and "// Maria ends up with examPapers, fully sorted." — personalized,
  // with zero change needed to the substitution logic itself.
  print(solutions.first.pseudocode);
}