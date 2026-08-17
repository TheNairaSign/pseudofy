import 'package:pseudofy/core/naming_context.dart';
import 'package:pseudofy/core/representation/flow_chart/flow_node.dart';

// Library entry shape ----------

class ParadigmVariant {
  final String pseudocodeTemplate;
  final FlowchartData flowchart;
  final Map<String, String> codeTemplates; // language -> code, with placeholders
  final String complexityTime;
  final String complexitySpace;

  /// Fallback names used when the AI didn't extract anything relevant —
  /// keeps templates readable even with zero naming context. E.g. a
  /// sorting entry might default {"object": "the items"}.
  final NamingContext defaultNaming;

  const ParadigmVariant({
    required this.pseudocodeTemplate,
    required this.flowchart,
    required this.codeTemplates,
    required this.complexityTime,
    required this.complexitySpace,
    this.defaultNaming = const NamingContext(),
  });
}

class ProblemEntry {
  final String id;
  final String title;
  final List<String> tags;
  final Map<String, ParadigmVariant> variants; // key = paradigm name

  const ProblemEntry({
    required this.id,
    required this.title,
    required this.tags,
    required this.variants,
  });
}
