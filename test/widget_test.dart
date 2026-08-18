// End-to-end widget test for the real app flow: type a problem, tap Solve,
// and confirm it resolves through the offline classifier fallback (no
// ANTHROPIC_API_KEY is set during `flutter test`) into rendered pseudocode.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pseudofy/main.dart';

void main() {
  testWidgets('home screen renders and browsing the library works', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PseudofyApp()));
    await tester.pump(); // let ClassificationNotifier.build()'s initial future resolve

    expect(find.text('Pseudofy'), findsWidgets);
    expect(find.byKey(const Key('problemInput')), findsOneWidget);
    expect(find.text('Browse the library'), findsOneWidget);
    expect(find.text('Merge Sort'), findsOneWidget);

    await tester.tap(find.text('Merge Sort'));
    await tester.pumpAndSettle();

    expect(find.text('Pseudocode'), findsOneWidget);
    expect(find.text('Flowchart'), findsOneWidget);
    expect(find.text('Code'), findsOneWidget);
  });

  testWidgets('solving via the offline classifier fallback resolves a match', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PseudofyApp()));

    await tester.enterText(
      find.byKey(const Key('problemInput')),
      'Please sort my array of numbers',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('solveButton')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Merge Sort'), findsOneWidget);
    expect(find.textContaining('% match'), findsOneWidget);
    expect(find.text('Pseudocode'), findsOneWidget);
  });

  testWidgets('unmatched input shows fallback suggestions', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PseudofyApp()));

    await tester.enterText(
      find.byKey(const Key('problemInput')),
      'zzz completely unrelated gibberish zzz',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('solveButton')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text("Couldn't confidently match that to a known problem."), findsOneWidget);
  });
}
