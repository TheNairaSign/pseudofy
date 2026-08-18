import 'package:pseudofy/library/library_entry.dart';
import 'package:pseudofy/core/naming_context.dart';
import 'package:pseudofy/core/representation/flow_chart/flow_node.dart';

class SolutionModel {
  final String problemId;
  final String problemTitle;
  final String paradigm;
  final String pseudocode;
  final FlowchartData flowchart;
  final Map<String, String> code;
  final String complexityTime;
  final String complexitySpace;

  const SolutionModel({
    required this.problemId,
    required this.problemTitle,
    required this.paradigm,
    required this.pseudocode,
    required this.flowchart,
    required this.code,
    required this.complexityTime,
    required this.complexitySpace,
  });
}

// ---------- The one thing the AI returns ----------

class ClassificationResult {
  final String? matchedProblemId;
  final double confidence;
  final Map<String, dynamic> extractedParams; // behavior-affecting values
  final NamingContext namingContext; // cosmetic/flavor values
  final List<String> alternativeMatches;

  const ClassificationResult({
    required this.matchedProblemId,
    required this.confidence,
    required this.extractedParams,
    required this.namingContext,
    required this.alternativeMatches,
  });

  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    return ClassificationResult(
      matchedProblemId: json['matchedProblemId'] as String?,
      confidence: (json['confidence'] as num).toDouble(),
      extractedParams: Map<String, dynamic>.from(json['extractedParams'] ?? {}),
      namingContext: NamingContext.fromJson(json['namingContext']),
      alternativeMatches: List<String>.from(json['alternativeMatches'] ?? []),
    );
  }
}

// ---------- Substitution ----------

/// Fills {{key}} placeholders in a template using params first, then
/// naming values. Both use the same {{key}} syntax — a template author
/// doesn't need to know or care which bucket a given slot came from.
String substituteAll(
  String template,
  Map<String, dynamic> params,
  NamingContext naming,
) {
  var result = template;
  params.forEach((key, value) {
    result = result.replaceAll('{{$key}}', value.toString());
  });
  naming.values.forEach((key, value) {
    result = result.replaceAll('{{$key}}', value);
  });
  return result;
}

// ---------- Resolution ----------

/// Given a classification result, look up the library entry and build
/// the SolutionModel(s) the UI will render. Pure Dart, no network call.
List<SolutionModel> resolveSolutions(
  ClassificationResult classification,
  Map<String, ProblemEntry> library, {
  String? paradigmFilter,
}) {
  if (classification.matchedProblemId == null) return [];
  final entry = library[classification.matchedProblemId];
  if (entry == null) return [];

  final variantsToUse = paradigmFilter != null
      ? entry.variants.entries.where((e) => e.key == paradigmFilter)
      : entry.variants.entries;

  return variantsToUse.map((e) {
    final variant = e.value;
    // Defaults first, AI-extracted naming overrides where present —
    // so a template never renders with a raw unfilled {{slot}}.
    final naming = variant.defaultNaming.mergedWith(classification.namingContext);

    return SolutionModel(
      problemId: entry.id,
      problemTitle: entry.title,
      paradigm: e.key,
      pseudocode: substituteAll(
        variant.pseudocodeTemplate,
        classification.extractedParams,
        naming,
      ),
      // Node/edge positions and structure are static, but labels can carry
      // the same {{param}}/{{namingSlot}} placeholders as pseudocode/code —
      // substitute those too, or they'd render literally in the UI.
      flowchart: _substituteFlowchart(
        variant.flowchart,
        classification.extractedParams,
        naming,
      ),
      code: variant.codeTemplates.map(
        (lang, code) => MapEntry(
          lang,
          substituteAll(code, classification.extractedParams, naming),
        ),
      ),
      complexityTime: variant.complexityTime,
      complexitySpace: variant.complexitySpace,
    );
  }).toList();
}

FlowchartData _substituteFlowchart(
  FlowchartData data,
  Map<String, dynamic> params,
  NamingContext naming,
) {
  return FlowchartData(
    nodes: data.nodes
        .map((n) => FlowNode(
              id: n.id,
              type: n.type,
              label: substituteAll(n.label, params, naming),
              x: n.x,
              y: n.y,
            ))
        .toList(),
    edges: data.edges
        .map((edge) => FlowEdge(
              from: edge.from,
              to: edge.to,
              label: edge.label == null
                  ? null
                  : substituteAll(edge.label!, params, naming),
            ))
        .toList(),
  );
}

// ---------- Classification prompt ----------

/// The library's ids/tags are injected so the model chooses from a
/// CLOSED set. It's also asked to extract both functional params and
/// free-form naming entities in the same pass — one AI call does both.
String buildClassificationSystemPrompt(Map<String, ProblemEntry> library) {
  final catalogLines = library.values
      .map((e) => '- id: "${e.id}", title: "${e.title}", tags: ${e.tags}')
      .join('\n');

  return '''
You are a strict classifier. You do NOT solve problems or write code.

Given a user's free-text problem description, match it to exactly one entry
from the CLOSED catalog below, or determine no good match exists.

CATALOG:
$catalogLines

Extract two separate kinds of information:

1. "extractedParams" — values that affect the algorithm's BEHAVIOR, e.g.
   n, array size, a target value. Only include what's actually stated.

2. "namingContext" — free-form names the user used for people, objects,
   or activities, so the output can be personalized. Use these
   conventional slot names where they fit: "person", "person2", "object",
   "activity", "location". Only fill a slot if the user's text actually
   supports it — never invent a name. E.g. "help Maria sort her exam
   papers" -> {"person": "Maria", "object": "exam papers"}.

Respond with ONLY this JSON shape, no prose, no markdown fences:
{
  "matchedProblemId": "<catalog id, or null if no confident match>",
  "confidence": <float 0.0-1.0>,
  "extractedParams": { "<param>": <value>, ... },
  "namingContext": { "<slot>": "<name>", ... },
  "alternativeMatches": ["<catalog id>", ...]
}

If nothing in the catalog is a good fit, set matchedProblemId to null and
still populate alternativeMatches with your best 1-3 guesses.
''';
}