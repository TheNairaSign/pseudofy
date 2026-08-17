# Algorithm Paradigm Solver — App Flow & MVP Roadmap (v2: Library-First)

> **Design shift from v1:** AI no longer generates the pseudocode/flowchart/code directly.
> AI's only job is to classify the user's free-text problem into a known entry in a
> hand-curated library and extract parameters. The library — pure Dart, no network call —
> holds the actual (correct, tested, hand-authored) solutions. This trades "AI can solve
> anything" for "the app is reliable and correct by construction," at the cost of needing
> to author the library up front.

---

## 1. General Application Flow

```
┌─────────────────────────────────────────────────────────────┐
│                         HOME SCREEN                            │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐   │
│  │  Problem Input                                           │   │
│  │  [ TextField: "Describe your problem..."            ]   │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐   │
│  │  Paradigm Filter (optional, multi-select chips)          │   │
│  │  [Divide & Conquer] [Backtracking] [Dynamic Programming]  │   │
│  │  [Greedy] [Branch & Bound] [Brute Force] [Two Pointers]   │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                                  │
│                      [  Solve  ]                                 │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
              ┌───────────────────────────┐
              │   ClassificationService     │
              │  - sends problem text +     │
              │    paradigm filter to Claude│
              │  - Claude returns SMALL JSON│
              │    (id, confidence, params, │
              │    alternatives) — NOT a    │
              │    full solution             │
              └───────────────────────────┘
                            │
              ┌─────────────┴─────────────┐
              │ confidence high & id found │  confidence low / no match
              ▼                            ▼
   ┌───────────────────────┐   ┌─────────────────────────────┐
   │  AlgorithmLibrary        │   │  Fallback UI                  │
   │  (pure Dart, in-app,     │   │  - show alternativeMatches    │
   │   no network call)       │   │    as tappable suggestions    │
   │  - Map<String,           │   │  - or let user browse/search  │
   │    ProblemEntry>         │   │    the library directly       │
   │  - lookup(id, paradigm)  │   │  - or "AI Freeform Mode"       │
   │  - returns pre-authored  │   │    (opt-in, visually distinct,│
   │    SolutionModel(s)      │   │    old full-generation path)  │
   └───────────────────────┘   └─────────────────────────────┘
                │
                ▼
   ┌───────────────────────────┐
   │  Parameter substitution      │
   │  (deterministic Dart)         │
   │  Fills {{param}} placeholders │
   │  in pseudocode/code templates │
   │  with extractedParams         │
   └───────────────────────────┘
                │
                ▼
        SolutionModel(s) → UI tabs
```

### Classification response contract (AI's only output)

```json
{
  "matchedProblemId": "n_queens",
  "confidence": 0.92,
  "extractedParams": { "n": 8 },
  "alternativeMatches": ["subset_sum", "sudoku_solver"]
}
```

This is deliberately small and flat — no nested graphs, no code, no pseudocode. Easy to validate, easy for the model to get right consistently.

### Library entry (hand-authored, static, reused forever)

```json
{
  "id": "n_queens",
  "title": "N-Queens",
  "tags": ["queens", "chessboard", "n-queens", "constraint satisfaction"],
  "variants": {
    "backtracking": {
      "pseudocodeTemplate": "function solveNQueens(n = {{n}}):\n  board = empty n x n\n  backtrack(row = 0)\n\nfunction backtrack(row):\n  if row == n: record solution; return\n  for col in 0..n:\n    if isSafe(row, col):\n      place queen at (row, col)\n      backtrack(row + 1)\n      remove queen at (row, col)",
      "flowchart": { "nodes": [ "hand-authored, fixed" ], "edges": [ "fixed" ] },
      "codeTemplates": {
        "dart": "List<List<int>> solveNQueens(int n) { /* ... */ }",
        "python": "def solve_n_queens(n): ..."
      },
      "complexityTime": "O(N!)",
      "complexitySpace": "O(N)"
    },
    "branchAndBound": { "note": "similar shape, different pruning strategy" }
  }
}
```

### Regeneration / "modify" loop (unchanged in spirit, cheaper now)

Because the underlying solution is a static template, "regenerate" mostly means re-running parameter substitution or letting the user directly edit the rendered pseudocode/code in place — no AI round-trip needed for typical edits. AI is only re-invoked if the user says "this isn't the problem I meant" (re-classification).

---

## 2. Step-by-Step to MVP

### Step 1 — Project scaffolding
- Create Flutter project, folder structure (`models/`, `services/`, `library/`, `providers/`, `screens/`, `widgets/`)
- Dependencies: `http`, `flutter_riverpod`, `flutter_flow_chart`, `flutter_highlight`, `json_annotation` + `json_serializable` (dev)
- `--dart-define` / `.env` for the Claude API key (git-excluded)

### Step 2 — Data models
- `ProblemEntry`, `ParadigmVariant`, `FlowchartData`, `SolutionModel` (see shapes above)
- `ClassificationResult` (matchedProblemId, confidence, extractedParams, alternativeMatches)
- `build_runner` for JSON (de)serialization

### Step 3 — Author the seed library (do this early — it's the real MVP bottleneck)
Start with 8–12 entries covering the core paradigms:

| Problem | Paradigms |
|---|---|
| Fibonacci | Recursion, DP (memo), DP (tabulation) |
| Merge Sort | Divide & Conquer |
| N-Queens | Backtracking, Branch & Bound |
| 0/1 Knapsack | DP, Brute Force |
| Coin Change | DP, Greedy (noted as non-optimal in general) |
| Subset Sum | Backtracking, DP |
| Activity Selection | Greedy |
| Binary Search | Divide & Conquer |

Each entry: pseudocode template, hand-built flowchart node/edge data (test it renders cleanly in `flutter_flow_chart` before moving on), code in 1–2 languages, complexity.

### Step 4 — AlgorithmLibrary service
- Static/in-memory `Map<String, ProblemEntry>` (loaded from bundled JSON assets or Dart const data — either works; JSON assets make future edits easier without recompiling)
- `lookup(id, {String? paradigm})` → `SolutionModel` or `List<SolutionModel>`
- Simple local search/filter by `tags` (used both for fallback browsing and sanity-checking AI matches)

### Step 5 — ClassificationService (the one AI call)
- System prompt: given problem text + optional paradigm filter + **the list of library problem IDs/tags**, return only the small JSON contract above
- Feed the library's own tag list into the prompt so the model is choosing from a known, closed set — this is what keeps accuracy high
- Validate response shape; if `confidence` below a threshold (e.g. 0.6) or `matchedProblemId` not in the library, treat as no-match

### Step 6 — Parameter substitution
- Deterministic Dart function: replace `{{param}}` tokens in pseudocode/code templates using `extractedParams`
- Missing/unparseable params → prompt user to fill them in manually via a small form (safer than guessing)

### Step 7 — State management
- `ProblemProvider`: problem text + paradigm filter
- `ClassificationProvider`: `AsyncNotifier<ClassificationResult>`
- `SolutionProvider`: derives `SolutionModel(s)` from library lookup + substitution once classification resolves

### Step 8 — Input & fallback UI
- Home screen: text field, paradigm chips, Solve button
- No-match / low-confidence state: tappable `alternativeMatches` chips, plus a "browse library" search screen using the tag index from Step 4

### Step 9 — Workspace UI
- Outer `TabBar`: one tab per resolved paradigm variant
- Inner `TabBar`: Pseudocode / Flowchart / Code
- Flowchart tab: render the entry's static `nodes`/`edges` via `flutter_flow_chart` (drag/zoom/pan)
- Code tab: `flutter_highlight`, language dropdown, copy button

### Step 10 — Manual QA
- Test classification against paraphrased versions of each library problem (not just exact titles) to check matching robustness
- Confirm every library entry's flowchart renders without overlap/orphan nodes

---

## MVP Cut Line

**In scope:** free-text input → AI classification (small JSON only) → curated library lookup → parameter substitution → three-tab output, fallback suggestions on low confidence, manual library browsing.

**Explicitly out of scope for MVP:** "AI Freeform Mode" full-generation fallback (add later, clearly labeled, opt-in), running/executing generated code, saving/loading past solutions, auto-layout for flowcharts (not needed — flowcharts are hand-authored and fixed), proxy backend for API key security.
