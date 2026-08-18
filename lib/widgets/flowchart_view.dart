import 'package:flutter/material.dart';
import 'package:pseudofy/core/representation/flow_chart/flow_node.dart';

const double _nodeWidth = 160;
const double _nodeHeight = 56;

/// Renders a static [FlowchartData] — hand-authored fixed x/y positions,
/// no auto-layout. Pannable/zoomable since node graphs can exceed the
/// visible viewport.
class FlowchartView extends StatelessWidget {
  const FlowchartView({super.key, required this.data});
  final FlowchartData data;

  @override
  Widget build(BuildContext context) {
    if (data.nodes.isEmpty) {
      return const Center(child: Text('No flowchart available for this variant yet.'));
    }

    final maxX = data.nodes.map((n) => n.x).reduce((a, b) => a > b ? a : b) + _nodeWidth + 40;
    final maxY = data.nodes.map((n) => n.y).reduce((a, b) => a > b ? a : b) + _nodeHeight + 40;
    final nodesById = {for (final n in data.nodes) n.id: n};

    return InteractiveViewer(
      constrained: false,
      minScale: 0.5,
      maxScale: 2.5,
      boundaryMargin: const EdgeInsets.all(80),
      child: SizedBox(
        width: maxX,
        height: maxY,
        child: Stack(
          children: [
            CustomPaint(
              size: Size(maxX, maxY),
              painter: _EdgePainter(edges: data.edges, nodesById: nodesById),
            ),
            for (final node in data.nodes)
              Positioned(
                left: node.x,
                top: node.y,
                width: _nodeWidth,
                height: _nodeHeight,
                child: _NodeBox(node: node),
              ),
          ],
        ),
      ),
    );
  }
}

class _NodeBox extends StatelessWidget {
  const _NodeBox({required this.node});
  final FlowNode node;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDecision = node.type == 'decision';
    final fill = switch (node.type) {
      'start' || 'end' => scheme.primaryContainer,
      'decision' => scheme.tertiaryContainer,
      _ => scheme.surfaceContainerHighest,
    };

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(isDecision ? 28 : 10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        node.label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class _EdgePainter extends CustomPainter {
  _EdgePainter({required this.edges, required this.nodesById});
  final List<FlowEdge> edges;
  final Map<String, FlowNode> nodesById;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      final from = nodesById[edge.from];
      final to = nodesById[edge.to];
      if (from == null || to == null) continue;

      final vertStart = Offset(from.x + _nodeWidth / 2, from.y + _nodeHeight);
      final vertEnd = Offset(to.x + _nodeWidth / 2, to.y);
      final horizStart = Offset(from.x + _nodeWidth, from.y + _nodeHeight / 2);
      final horizEnd = Offset(to.x, to.y + _nodeHeight / 2);

      final preferVertical =
          (vertStart.dy - vertEnd.dy).abs() >= (horizStart.dx - horizEnd.dx).abs();
      final start = preferVertical ? vertStart : horizStart;
      final end = preferVertical ? vertEnd : horizEnd;

      canvas.drawLine(start, end, paint);
      _drawArrowHead(canvas, start, end, paint);

      if (edge.label != null) {
        final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
        final tp = TextPainter(
          text: TextSpan(
            text: edge.label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, mid + const Offset(4, -12));
      }
    }
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Paint paint) {
    const arrowSize = 6.0;
    final angle = (to - from).direction;
    final a1 = to + Offset.fromDirection(angle + 2.6, arrowSize);
    final a2 = to + Offset.fromDirection(angle - 2.6, arrowSize);
    canvas.drawLine(to, a1, paint);
    canvas.drawLine(to, a2, paint);
  }

  @override
  bool shouldRepaint(covariant _EdgePainter oldDelegate) =>
      edges != oldDelegate.edges || nodesById != oldDelegate.nodesById;
}
