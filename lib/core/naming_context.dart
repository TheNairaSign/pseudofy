// ---------- Naming context ----------
//
// Holds free-form entity names the AI picked up from the user's own
// wording — people, objects, activities — so the rendered output can
// speak in the user's vocabulary instead of generic placeholders.
//
// This is deliberately separate from `extractedParams`:
//   - extractedParams  -> values that change algorithm BEHAVIOR (n=8, target=42)
//   - NamingContext     -> values that change algorithm FLAVOR/PRESENTATION
//                          (person="Maria", object="exam papers")
// Keeping them apart means a missing/wrong naming guess can never
// accidentally break the actual logic being substituted in.

class NamingContext {
  /// Open-ended slot map, e.g.
  /// {"person": "Maria", "person2": "Alex", "object": "exam papers",
  ///  "activity": "sorting"}
  /// Keys are not fixed — an entry's template defines whichever slots
  /// it cares about; unused slots are simply ignored at substitution time.
  final Map<String, String> values;

  const NamingContext({this.values = const {}});

  String get(String key, String fallback) => values[key] ?? fallback;

  /// Returns a new context where `overrides` wins on key collisions.
  /// Used to layer AI-extracted names on top of an entry's built-in
  /// defaults, so templates never render with a raw unfilled {{slot}}.
  NamingContext mergedWith(NamingContext overrides) {
    return NamingContext(values: {...values, ...overrides.values});
  }

  factory NamingContext.fromJson(Map<String, dynamic>? json) =>
      NamingContext(values: json == null ? {} : Map<String, String>.from(json));

  Map<String, dynamic> toJson() => values;
}


