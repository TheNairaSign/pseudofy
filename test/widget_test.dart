// End-to-end widget tests for the IDE/playground layout: collapsible
// sidebar (algorithm/paradigm dropdowns + library list) on the left, and a
// workspace on the right with view-mode tabs on top and a docked problem
// input at the bottom. Classification runs through the offline
// LocalClassifier fallback since no ANTHROPIC_API_KEY is set during
// `flutter test`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pseudofy/main.dart';

void main() {
  testWidgets('sidebar renders and picking a library entry opens the workspace', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PseudofyApp()));
    await tester.pump(); // let ClassificationNotifier.build()'s initial future resolve

    expect(find.text('Pseudofy'), findsOneWidget);
    expect(find.byKey(const Key('problemInput')), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('No algorithm selected'), findsOneWidget);
    expect(find.text('Merge Sort'), findsOneWidget);

    await tester.tap(find.text('Merge Sort'));
    await tester.pumpAndSettle();

    // Now shown in the breadcrumb, the algorithm dropdown, and the library list.
    expect(find.text('Merge Sort'), findsWidgets);
    expect(find.text('Pseudocode'), findsOneWidget);
    expect(find.text('Flowchart'), findsOneWidget);
    expect(find.text('Code'), findsOneWidget);
  });

  testWidgets('collapsing and expanding the sidebar works', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PseudofyApp()));
    await tester.pump();

    expect(find.text('Library'), findsOneWidget);

    await tester.tap(find.byTooltip('Collapse sidebar'));
    await tester.pumpAndSettle();
    expect(find.text('Library'), findsNothing);

    await tester.tap(find.byTooltip('Expand sidebar'));
    await tester.pumpAndSettle();
    expect(find.text('Library'), findsOneWidget);
  });

  testWidgets('solving via the offline classifier fallback resolves a match', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PseudofyApp()));
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('problemInput')),
      'Please sort my array of numbers',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('solveButton')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Merge Sort'), findsWidgets);
    expect(find.textContaining('% match'), findsOneWidget);
    expect(find.text('Pseudocode'), findsOneWidget);
  });

  testWidgets('unmatched input shows fallback suggestions', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PseudofyApp()));
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('problemInput')),
      'zzz completely unrelated gibberish zzz',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('solveButton')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('No confident match'), findsOneWidget);
    expect(find.text("Couldn't confidently match that to a known problem."), findsOneWidget);
  });
}
