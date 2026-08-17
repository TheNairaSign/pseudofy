// ============================================================
// CORE MODELS — problem-agnostic. No specific algorithms or
// library entries live in this file. Library data (fibonacci,
// merge_sort, n_queens, etc.) imports and uses these types but
// is defined elsewhere (see library_entries_sample.dart).
// ============================================================

// ---------- Flowchart primitives ----------

class FlowNode {
  final String id;
  final String type; // start | process | decision | end
  final String label; // may contain {{param}} / {{namingSlot}} placeholders
  final double x; // required by flutter_flow_chart — no auto-layout
  final double y;

  const FlowNode({
    required this.id,
    required this.type,
    required this.label,
    required this.x,
    required this.y,
  });
}

class FlowEdge {
  final String from;
  final String to;
  final String? label; // e.g. "yes" / "no"
  const FlowEdge({required this.from, required this.to, this.label});
}

class FlowchartData {
  final List<FlowNode> nodes;
  final List<FlowEdge> edges;
  const FlowchartData({required this.nodes, required this.edges});
}
