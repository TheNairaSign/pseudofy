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

**Project status:** MVP UI is wired up and working end to end (input → classify → library lookup →
substitution → tabbed pseudocode/flowchart/code output), backed by a one-entry seed library
(`merge_sort`). Growing the library (per the roadmap's target seed set below) is the main
remaining gap, not plumbing.

**Offline dev/test path:** `ClassificationService` calls the real Claude API only when
`ANTHROPIC_API_KEY` is passed via `--dart-define`. With no key (the default for `flutter test`
and local `flutter run`), it falls back to `LocalClassifier`
(`lib/core/services/local_classifier.dart`) — a pure-Dart, deterministic word-overlap matcher
against the library's titles/tags. This is what lets the whole app be exercised and tested
without a key; it is not a substitute for real classification quality.

## Commands

```bash
flutter pub get                 # install dependencies (run after pulling or editing pubspec.yaml)
flutter analyze                 # static analysis / lints (flutter_lints ruleset via analysis_options.yaml)
flutter test                    # run all tests in test/ (uses the offline LocalClassifier fallback)
flutter test --plain-name "solving via the offline classifier"  # run a single test by name
flutter run -d chrome           # run in a browser; offline fallback classifier, no key needed
flutter run --dart-define=ANTHROPIC_API_KEY=sk-...   # run against the real Claude API instead
flutter build <ios|apk|web|macos|...>                 # platform build
```

A `flutter run -d chrome` launch config is in `.claude/launch.json` (usable via the browser
preview tooling) — named `pseudofy-web`, port 8765.

There is no separate lint/format config beyond `analysis_options.yaml` (which just includes
`package:flutter_lints/flutter.yaml`). Use `dart format .` for formatting.

## Architecture

### Data flow

```
user free text + optional paradigm filter (HomeScreen)
        │
        ▼
ClassificationService.classify()   (lib/core/services/classification_service.dart)
  - the only network-touching code in the app, IF a key is configured
  - with ANTHROPIC_API_KEY set: calls Claude with a system prompt built by
    buildClassificationSystemPrompt() (lib/core/solution_model.dart), which embeds the full
    library catalog (ids/titles/tags) so the model can only choose from a known closed set;
    retries once on bad JSON; rejects any matchedProblemId not actually present in the library
  - with no key: delegates to LocalClassifier (lib/core/services/local_classifier.dart), a
    pure-Dart offline word-overlap matcher used for local dev/test — see note above
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
    placeholders in pseudocode templates, code templates, AND flowchart node/edge labels
    (all three carry the same placeholder syntax — easy to forget the flowchart one since its
    structure/positions otherwise pass through unchanged)
        │
        ▼
List<SolutionModel>   — one per paradigm variant, each also carrying problemId/problemTitle
so the UI can show which catalog entry matched
        │
        ▼
MainWorkspace (lib/widgets/workspace.dart) — Pseudocode / Flowchart / Code view-mode tabs,
persistent across which variant/algorithm is selected
```

Bypassing classification entirely (tapping a library entry, an alternative-match suggestion, or
the sidebar's algorithm dropdown) goes through `ClassificationNotifier.selectManually(id)`
instead, which synthesizes a `ClassificationResult` with confidence 1.0 and feeds the same
`resolveSolutions` path.

### UI layout: IDE/playground shell

`HomeScreen` (`lib/screens/home_screen.dart`) is a `Row`: a collapsible `AppSidebar` on the left,
a `VerticalDivider`, then `MainWorkspace` filling the rest.

- **`AppSidebar`** (`lib/widgets/app_sidebar.dart`) — collapses between `_expandedWidth` (272)
  and `_collapsedWidth` (56) via `sidebarExpandedProvider`. Holds the `AlgorithmDropdown`
  (jump straight to a catalog entry, bypassing classification), `ParadigmDropdown` (single-select
  hint sent to the classifier), and the `LibraryBrowser` list. The width animates via
  `AnimatedContainer`, but the inner content is laid out in a fixed-size `OverflowBox`
  (`_expandedWidth`) that the outer container clips — **don't replace that with a plain
  `SizedBox`**: a `SizedBox` doesn't override the tight width constraint an animating `Container`
  imposes on its child, so at intermediate widths a `ListTile` (title + trailing icon) can't fit
  and throws mid-animation. `OverflowBox` explicitly ignores the incoming constraint instead.
- **`MainWorkspace`** (`lib/widgets/workspace.dart`) — a `Column` of `_ContentArea` (`Expanded`)
  over a docked `_BottomInputBar` (the problem `TextField` + Solve button, always pinned to the
  bottom regardless of scroll — the "console input" of the IDE metaphor). `_ContentArea` owns a
  `TabController` for the Pseudocode/Flowchart/Code view-mode tabs, created eagerly in
  `initState` (not as a lazy `late` field initializer — see inline comment; a lazy field whose
  first access happens inside `dispose()` tries to create a vsync'd `AnimationController` on an
  already-deactivated element and crashes). A separate `_variantIndex` (local state, reset via
  `ref.listen` when the matched `problemId` changes) picks which `SolutionModel` variant is
  shown; changing algorithm/variant deliberately does **not** reset the view-mode tab, so a user
  parked on the Code tab stays there when they jump to a different problem.
- Multiple resolved variants for one problem surface as a `DropdownButton` in the workspace
  breadcrumb bar (only rendered when `solutions.length > 1`) — today unreachable since
  `merge_sort` has a single variant, but exercised as soon as a library entry gets a second one.

### Core types and where they live

- `lib/library/library_entry.dart` — `ProblemEntry` (id/title/tags/variants) and
  `ParadigmVariant` (pseudocode template, flowchart, per-language code templates, complexity,
  `defaultNaming`). This is the *shape* of a library entry.
- `lib/library/library_samples.dart` — the actual library *data*: the `algorithmLibrary` map
  (`Map<String, ProblemEntry>`). This file only ever grows by adding more `ProblemEntry`
  constants and must never touch core model/architecture files. Currently seeded with one
  entry (`merge_sort`); the roadmap's target seed set is listed in
  [algo-solver-app-flow-and-mvp.md](algo-solver-app-flow-and-mvp.md) (Fibonacci, N-Queens,
  Knapsack, Coin Change, Subset Sum, Activity Selection, Binary Search, ...).
- `lib/core/naming_context.dart` — `NamingContext`, the open-ended slot map (`person`, `object`,
  `activity`, ...) used purely for cosmetic personalization of rendered templates, kept
  intentionally separate from behavior-affecting params.
- `lib/core/solution_model.dart` — `SolutionModel` (final resolved output per variant, including
  `problemId`/`problemTitle`), `ClassificationResult` (the AI's only output shape), the
  `substituteAll` template-filling logic, `resolveSolutions` (classification → solutions), and
  `buildClassificationSystemPrompt`. This is the busiest file in the core layer — most
  cross-cutting logic lives here rather than being split across files that match filenames 1:1.
- `lib/core/representation/flow_chart/flow_node.dart` — flowchart primitives: `FlowNode`,
  `FlowEdge`, `FlowchartData`. Nodes are hand-authored with fixed `x`/`y` — there is no
  auto-layout by design (flowcharts are static per library entry).
- `lib/core/services/classification_service.dart` / `local_classifier.dart` — see data flow
  above.
- `lib/providers/providers.dart` — Riverpod wiring: `problemInputProvider` (text + paradigm
  filter), `algorithmLibraryProvider`, `classificationServiceProvider`,
  `classificationProvider` (`AsyncNotifier` with `.solve()` for the real/offline classify call,
  `.selectManually(id)` to bypass it, `.reset()` back to idle), `solutionsProvider` (pure
  derivation, no network), and `classificationOutcomeProvider` (collapses async state into
  `idle | loading | matched | noMatch | error` for UI branching).
- `lib/screens/home_screen.dart` — the single screen: problem input, paradigm filter chips,
  Solve button, and a results area that switches on `classificationOutcomeProvider`.
- `lib/widgets/` — `solution_view.dart` (tab structure described above), `flowchart_view.dart`
  (renders `FlowchartData` via `Positioned` nodes + a `CustomPainter` for edges inside an
  `InteractiveViewer` — no `flutter_flow_chart` package dependency), `code_view.dart` (language
  dropdown + copy), `paradigm_chips.dart`, `library_browser.dart` (used both as the idle-state
  default and inside the no-match fallback).

### Key invariants to preserve when extending

- Keep the network boundary singular: `ClassificationService` should remain the only place that
  can make HTTP calls (the `LocalClassifier` fallback it delegates to when no key is set must
  stay pure Dart). Solution rendering (`resolveSolutions`, `substituteAll`) must stay pure Dart.
- The classifier must only ever be able to return a `matchedProblemId` that exists in
  `algorithmLibrary` — `ClassificationService._callAndParse` enforces this for the real API path;
  preserve that check if the catalog-building logic changes.
- Keep `extractedParams` (behavior) and `namingContext` (cosmetic) separate rather than merging
  them into one params map — this is a deliberate safety boundary, not incidental structure.
- Any place a template can contain `{{slot}}` placeholders (pseudocode, code, AND flowchart
  labels) must go through `substituteAll`/`resolveSolutions` — don't pass raw template data to
  the UI.
- When adding a new library entry, don't touch `library_entry.dart` (the shape) unless the shape
  itself needs to change — new problems only add entries to the `algorithmLibrary` map in
  `library_samples.dart`.
- The Claude API key is read via `String.fromEnvironment('ANTHROPIC_API_KEY')` at build time
  (`--dart-define`), never hardcoded.
