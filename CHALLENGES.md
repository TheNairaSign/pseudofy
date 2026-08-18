# Challenges & Solutions Log

A running log of real problems hit while building this app and how they were resolved —
kept for future-us (and future Claude Code sessions) so the same mistakes aren't repeated.
Ordered chronologically within each section. Append new entries as they come up; don't
rewrite history.

## UI implementation (input → classify → library → tabs)

### Flowchart labels never got `{{placeholder}}` substitution
**Symptom:** Pseudocode/code rendered correctly, but the Flowchart tab would show raw
`{{object}}` tokens instead of the filled-in value.
**Root cause:** `resolveSolutions` (`lib/core/solution_model.dart`) ran `substituteAll` on
`pseudocodeTemplate` and `codeTemplates`, but passed `variant.flowchart` straight through
unchanged — nobody had wired substitution into the third template surface.
**Fix:** Added `_substituteFlowchart()` to rebuild `FlowchartData` with substituted node/edge
labels, called from `resolveSolutions`.

### No way to know which problem matched
**Symptom:** `SolutionModel` only carried `paradigm` (the variant name, e.g. "Divide and
Conquer") — nothing indicated *which* library entry it came from, so the UI couldn't show a
title/header.
**Fix:** Added `problemId`/`problemTitle` to `SolutionModel`, populated from the matched
`ProblemEntry` in `resolveSolutions`.

### Needed a way to test the app without an Anthropic API key
**Symptom:** `ClassificationService.classify()` threw a `StateError` if
`ANTHROPIC_API_KEY` wasn't set via `--dart-define` — meaning `flutter test` and local dev
had no working path at all.
**Fix:** Added `LocalClassifier` (`lib/core/services/local_classifier.dart`), a pure-Dart
deterministic word-overlap matcher against the library's titles/tags.
`ClassificationService` now delegates to it when no key is configured, instead of throwing.
This is what makes `flutter test` deterministic and lets the whole app run offline.

### Widget test failed on `find.text('Browse the library')` right after `pumpWidget`
**Symptom:** The very first assertion after `pumpWidget()` failed even though the widget was
clearly there in later screenshots.
**Root cause:** `ClassificationNotifier.build()` is `async` (`Future<ClassificationResult?>
build() async => null`). Even though it resolves synchronously in practice, Riverpod's
`AsyncNotifier` reports `AsyncLoading` for the first frame until the microtask completes —
so `classificationOutcomeProvider` was `loading`, not `idle`, at the moment of the assertion.
**Fix:** Added one extra `await tester.pump();` after `pumpWidget()` in every test, to let the
initial future resolve before asserting on idle-state UI.

### Browser-automation typing appeared to silently fail on Flutter web
**Symptom:** Using the `computer` tool's `type` action on the problem `TextField` produced no
visible change in the screenshot, repeatedly, across several attempts.
**Root cause:** Not an app bug — Flutter web's debug build (DDC) renders to canvas and updates
asynchronously; keystrokes *did* land, but the visual update lagged behind the tool's
screenshot by a render cycle or more, especially under DDC's slower dev-mode recompilation.
Confirmed by sending a single `key` press and seeing it appear one screenshot later.
**Takeaway:** When verifying Flutter web via browser automation, don't trust the immediately-
following screenshot — click, wait (1–4s), *then* screenshot. Widget tests remain the more
reliable way to verify interaction logic; use the browser pass for visual/layout confirmation,
not as the primary correctness check.

## Sidebar/workspace (IDE-style) rewrite

### `StateProvider` doesn't exist in this Riverpod version
**Symptom:** `flutter analyze` error: `The function 'StateProvider' isn't defined`.
**Root cause:** This project pins `flutter_riverpod: ^3.4.2`; Riverpod 3.x dropped the old
`StateProvider`/`StateNotifierProvider` shorthands in favor of `Notifier`/`NotifierProvider`
everywhere, matching the pattern the codebase already used for `ProblemInputNotifier`.
**Fix:** Added a small `SidebarNotifier extends Notifier<bool>` with an explicit
`setExpanded(bool)` method instead of reaching for `StateProvider`.

### `DropdownButtonFormField.value` is deprecated in this Flutter version
**Symptom:** `flutter analyze` info: `'value' is deprecated... Use initialValue instead` on
both the Algorithm and Paradigm dropdowns.
**Root cause:** As of Flutter 3.33, `DropdownButtonFormField` moved to `initialValue` semantics
(seed once, like `TextFormField.initialValue`) — but these dropdowns need to be *externally
controlled*: their displayed value must update whenever `classificationProvider` or
`problemInputProvider` changes (e.g. picking a library entry should update what the Algorithm
dropdown shows). `initialValue` wouldn't react to that.
**Fix:** Swapped both to a plain `DropdownButton` (whose `value` remains fully controlled)
wrapped in `InputDecorator` + `DropdownButtonHideUnderline` to keep the same boxed/labeled
visual style.

### Sidebar `ListTile`s broke ink splashes: "background color or ink splashes may be invisible"
**Symptom:** A framework assertion fired (visible as a test failure and a red-screen error)
whenever the library list rendered inside the sidebar.
**Root cause:** `AppSidebar` set `color:` directly on the outer `AnimatedContainer`, which
paints via an intervening `DecoratedBox`. `ListTile` needs to paint its background/ink splashes
on the *nearest* `Material` ancestor — the opaque `DecoratedBox` sat between the `ListTile` and
any `Material`, breaking that.
**Fix:** Moved the background color onto an explicit `Material(color: ...)` wrapping the
sidebar content, instead of `Container`/`AnimatedContainer.color`.

### `TabController` crashed the app on dispose — "Looking up a deactivated widget's ancestor is unsafe"
**Symptom:** Intermittent crash when a `_ContentArea` was torn down (e.g. switching straight
from one test to the next, or a user closing the app before ever solving anything).
**Root cause:** `_viewModeController` was declared as `late final TabController
_viewModeController = TabController(length: 3, vsync: this);` — a **lazy** field. It's only
initialized the first time it's *read*. If the widget never rendered `_SolutionTabs` (i.e. the
user never reached the "matched" state), the field was never read during `build()` — so its
first read ended up happening inside `dispose()`, where the initializer tried to create a
vsync'd `AnimationController` against an element that was already deactivated.
**Fix:** Moved construction into `initState()` so the controller always exists by the time
`dispose()` runs, regardless of what the widget ever rendered.

### Duplicate "Expand sidebar" button made a test ambiguous — and was genuinely redundant UI
**Symptom:** `tester.tap(find.byTooltip('Expand sidebar'))` failed with "Found 2 widgets".
**Root cause:** Both the collapsed sidebar rail *and* the workspace breadcrumb bar independently
rendered an expand button whenever `sidebarExpandedProvider` was `false` — not just a test
problem, a real duplicate control visible to users.
**Fix:** Removed the breadcrumb's copy; the sidebar rail's own button is the single source of
truth for re-expanding.

### Sidebar collapse animation crashed mid-transition — "Trailing widget consumes the entire tile width"
**Symptom:** Tapping collapse/expand threw a rendering assertion from deep inside a `ListTile`
in the library list, but only *during* the animation, never at rest.
**Root cause:** `AnimatedContainer.width` interpolates the container's own width, which — via
`Container`'s implementation — imposes a **tight** `BoxConstraints` on its child at every frame.
A first-attempt fix wrapped the content in a plain `SizedBox(width: 272)`, but `SizedBox`
doesn't override an incoming *tight* constraint — the parent's tight width still won, so mid-
animation the `ListTile` (title + trailing chevron) was squeezed below its minimum usable width
and threw.
**Fix:** Replaced the `SizedBox` with `OverflowBox(minWidth: 272, maxWidth: 272, alignment:
Alignment.topLeft)`, which genuinely ignores the incoming constraint and always lays the content
out at its full target width; the outer `AnimatedContainer` (with `clipBehavior: Clip.hardEdge`)
just crops it visually as it shrinks/grows. Also had to left-align the collapsed rail's content
(`crossAxisAlignment.start`) since it now renders inside that same fixed-width canvas — without
that, the collapsed rail's icon centered itself outside the visible clipped strip.

## Library expansion (importing from TheAlgorithms/Dart)

### Direct library selection would have shown raw, unfilled `{{param}}` placeholders
**Symptom (caught before shipping, via a verification script — not a live bug):** Entries using
behavior-style placeholders (`{{n}}`, `{{capacity}}`, `{{target}}`) rely on
`classification.extractedParams` to fill them. But picking an entry directly from the sidebar
(`selectManually`) always passes `extractedParams: {}` — the primary, most common interaction
in this playground UI — so every such placeholder would render literally as `{{n}}` etc.
**Root cause:** `defaultNaming` (the existing fallback mechanism, previously only used for
cosmetic slots like `person`/`object`) was never populated for the new numeric-ish params, and
nothing else fills that gap.
**Fix:** Gave every new `ParadigmVariant` a `defaultNaming` entry covering *every* placeholder
it uses, including the behavior ones (e.g. `n_queens`'s `defaultNaming: {'n': '8'}`) — legitimate
use of the mechanism's documented purpose ("keeps templates readable even with zero context"),
not a hack. Verified with a throwaway script that resolves every entry with empty
params/naming and asserts no `{{` survives in pseudocode, code, or flowchart labels.

### `flutter analyze` can't catch bugs inside embedded code-template strings
**Symptom (anticipated, not observed):** The Dart source shown in the "Code" tab is just a
string literal from the analyzer's point of view — a typo inside `codeTemplates['dart']` would
compile the surrounding file fine and only surface as broken-looking code shown to the user.
**Fix:** Wrote a throwaway script that dumps every `codeTemplates['dart']` value to a standalone
`.dart` file (substituting placeholders with a dummy `1` first) and ran `dart analyze` over all
of them — confirms the embedded snippets are themselves syntactically/type valid Dart, not just
that the file containing them parses.
