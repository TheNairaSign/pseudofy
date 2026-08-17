# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Pseudofy is a Flutter app (targets iOS/Android/desktop/web) that turns a free-text algorithm
problem description into pseudocode, a flowchart, and code — for a **closed, hand-curated
library** of known problems (N-Queens, Merge Sort, Knapsack, etc.), not open-ended AI generation.

The design (see [algo-solver-app-flow-and-mvp.md](algo-solver-app-flow-and-mvp.md) for full
rationale) is deliberately "library-first": the one AI call (Claude, via `ClassificationService`)
only classifies the user's text into a `matchedProblemId` from a closed catalog and extracts
small JSON parameters. It never generates pseudocode, flowcharts, or code directly. All actual
solution content is hand-authored Dart data in `lib/core/library_samples.dart`, and template
placeholders are filled in deterministically. This trades "AI can solve anything" for
"correct by construction," at the cost of the library needing to be authored up front.

**Project status:** early scaffolding. `lib/main.dart` is still the stock Flutter counter demo —
no real UI has been built yet. The core data layer (models, one library entry for merge sort,
classification service, Riverpod providers) exists and works standalone, but nothing in `main.dart`
wires into it yet. `lib/library/` exists but is empty (intended home for future UI/browsing code
per the roadmap doc's `library/` folder convention).

## Commands

```bash
flutter pub get                 # install dependencies (run after pulling or editing pubspec.yaml)
flutter analyze                 # static analysis / lints (flutter_lints ruleset via analysis_options.yaml)
flutter test                    # run all tests in test/
flutter test test/widget_test.dart --plain-name "Counter increments smoke test"  # run a single test
flutter run --dart-define=ANTHROPIC_API_KEY=sk-...   # run the app; classification calls fail without this
flutter build <ios|apk|web|macos|...>                 # platform build
```

There is no separate lint/format config beyond `analysis_options.yaml` (which just includes
`package:flutter_lints/flutter.yaml`). Use `dart format .` for formatting.

## Architecture

### Data flow (per the MVP roadmap — only partially wired into UI so far)

```
user free text + optional paradigm filter
        │
        ▼
ClassificationService.classify()   (lib/core/services/classification_service.dart)
  - the ONLY network-touching code in the app
  - calls Claude (model set in ClassificationService._model) with a system prompt built by
    buildClassificationSystemPrompt() (lib/core/solution_model.dart), which embeds the full
    library catalog (ids/titles/tags) so the model can only choose from a known closed set
  - parses/validates the response into a ClassificationResult; retries once on bad JSON;
    rejects any matchedProblemId not actually present in the library
        │
        ▼
ClassificationResult                (lib/core/solution_model.dart)
  - matchedProblemId, confidence, extractedParams (behavior-affecting, e.g. n=8),
    namingContext (cosmetic/flavor, e.g. person="Maria", object="exam papers"),
    alternativeMatches
  - extractedParams and namingContext are deliberately separate: a wrong/missing naming
    guess can never corrupt actual algorithm behavior
        │
        ▼
resolveSolutions(classification, library)   (lib/core/solution_model.dart)
  - pure Dart, no network — looks up the ProblemEntry by id, layers namingContext over each
    variant's defaultNaming, and runs substituteAll() to fill {{param}}/{{namingSlot}}
    placeholders in pseudocode/code templates
        │
        ▼
List<SolutionModel>   — one per paradigm variant, ready for UI tabs
```

### Core types and where they live

- `lib/core/library_entry.dart` — `ProblemEntry` (id/title/tags/variants) and `ParadigmVariant`
  (pseudocode template, flowchart, per-language code templates, complexity, `defaultNaming`).
  This is the *shape* of a library entry.
- `lib/core/library_samples.dart` — the actual library *data*: the `algorithmLibrary` map
  (`Map<String, ProblemEntry>`). This file only ever grows by adding more `ProblemEntry`
  constants and must never touch core model/architecture files. Currently seeded with one
  entry (`merge_sort`); the roadmap's target seed set is listed in
  [algo-solver-app-flow-and-mvp.md](algo-solver-app-flow-and-mvp.md) (Fibonacci, N-Queens,
  Knapsack, Coin Change, Subset Sum, Activity Selection, Binary Search, ...).
- `lib/core/naming_context.dart` — `NamingContext`, the open-ended slot map (`person`, `object`,
  `activity`, ...) used purely for cosmetic personalization of rendered templates, kept
  intentionally separate from behavior-affecting params.
- `lib/core/solution_model.dart` — `SolutionModel` (final resolved output per variant),
  `ClassificationResult` (the AI's only output shape), the `substituteAll` template-filling
  logic, `resolveSolutions` (classification → solutions), and `buildClassificationSystemPrompt`.
  This is the busiest file in the core layer — most cross-cutting logic lives here rather than
  being split across files that match filenames 1:1.
- `lib/core/representation/flow_chart/flow_node.dart` — flowchart primitives: `FlowNode`,
  `FlowEdge`, `FlowchartData`. Nodes are hand-authored with fixed `x`/`y` — there is no
  auto-layout by design (flowcharts are static per library entry).
- `lib/core/core_models.dart` — currently empty; not yet in use.
- `lib/core/services/classification_service.dart` — see data flow above.
- `lib/providers/providers.dart` — Riverpod wiring: `problemInputProvider` (text + paradigm
  filter), `algorithmLibraryProvider`, `classificationServiceProvider`,
  `classificationProvider` (`AsyncNotifier` that makes the one API call on `.solve()`),
  `solutionsProvider` (pure derivation, no network), and `classificationOutcomeProvider`
  (collapses async state into `idle | loading | matched | noMatch | error` for UI branching).

### Key invariants to preserve when extending

- Keep the network boundary singular: `ClassificationService` should remain the only place that
  makes HTTP calls. Solution rendering (`resolveSolutions`, `substituteAll`) must stay pure Dart.
- The classifier must only ever be able to return a `matchedProblemId` that exists in
  `algorithmLibrary` — `ClassificationService._callAndParse` enforces this; preserve that check
  if the catalog-building logic changes.
- Keep `extractedParams` (behavior) and `namingContext` (cosmetic) separate rather than merging
  them into one params map — this is a deliberate safety boundary, not incidental structure.
- When adding a new library entry, don't touch `library_entry.dart` (the shape) unless the shape
  itself needs to change — new problems only add entries to the `algorithmLibrary` map in
  `library_samples.dart`.
- The Claude API key is read via `String.fromEnvironment('ANTHROPIC_API_KEY')` at build time
  (`--dart-define`), never hardcoded.
