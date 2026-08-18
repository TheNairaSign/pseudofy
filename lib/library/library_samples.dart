// ============================================================
// LIBRARY DATA — imports core_models.dart but contains none of
// the generic architecture. This file only ever grows by adding
// more ProblemEntry constants; it never touches core_models.dart.
//
// Some codeTemplates below are adapted from TheAlgorithms/Dart
// (https://github.com/TheAlgorithms/Dart, MIT License) — each such
// entry is marked with a "// Adapted from TheAlgorithms/Dart ..."
// comment naming the source file. Entries without that comment
// (Branch and Bound N-Queens, DP Knapsack, Greedy Coin Change,
// Subset Sum, Activity Selection) are original, written for this
// library where the source repo had no equivalent.
// ============================================================

import 'package:pseudofy/library/library_entry.dart';
import 'package:pseudofy/core/naming_context.dart';
import 'package:pseudofy/core/representation/flow_chart/flow_node.dart';
import 'package:pseudofy/core/solution_model.dart';


final Map<String, ProblemEntry> algorithmLibrary = {
  'merge_sort': ProblemEntry(
    id: 'merge_sort',
    title: 'Merge Sort',
    tags: ['merge sort', 'sorting', 'sort array', 'divide and conquer sort'],
    variants: {
      'Divide and Conquer': ParadigmVariant(
        // Sensible fallback if the AI found no naming context at all.
        defaultNaming: const NamingContext(values: {
          'person': 'the user',
          'object': 'the items',
        }),
        pseudocodeTemplate: '''
function sort{{object}}({{object}}):
    if length of {{object}} <= 1:
        return {{object}}
    mid = length of {{object}} / 2
    left = sort(first half of {{object}})
    right = sort(second half of {{object}})
    return merge(left, right)

// {{person}} ends up with {{object}}, fully sorted.
''',
        flowchart: const FlowchartData(
          nodes: [
            FlowNode(id: 'start', type: 'start', label: 'Start: {{object}}', x: 40, y: 20),
            FlowNode(id: 'base', type: 'decision', label: 'Length <= 1?', x: 40, y: 100),
            FlowNode(id: 'done', type: 'end', label: 'Return as-is', x: 300, y: 100),
            FlowNode(id: 'split', type: 'process', label: 'Split in half', x: 40, y: 184),
            FlowNode(id: 'recurse', type: 'process', label: 'Sort each half', x: 40, y: 268),
            FlowNode(id: 'merge', type: 'process', label: 'Merge sorted halves', x: 40, y: 352),
          ],
          edges: [
            FlowEdge(from: 'start', to: 'base'),
            FlowEdge(from: 'base', to: 'done', label: 'yes'),
            FlowEdge(from: 'base', to: 'split', label: 'no'),
            FlowEdge(from: 'split', to: 'recurse'),
            FlowEdge(from: 'recurse', to: 'merge'),
          ],
        ),
        codeTemplates: {
          'dart': '''
// Sorts {{object}} for {{person}}.
List<int> sort{{object}}(List<int> {{object}}) {
  if ({{object}}.length <= 1) return {{object}};
  final mid = {{object}}.length ~/ 2;
  final left = sort{{object}}({{object}}.sublist(0, mid));
  final right = sort{{object}}({{object}}.sublist(mid));
  return _merge(left, right);
}

List<int> _merge(List<int> left, List<int> right) {
  final result = <int>[];
  var i = 0, j = 0;
  while (i < left.length && j < right.length) {
    result.add(left[i] <= right[j] ? left[i++] : right[j++]);
  }
  result.addAll(left.sublist(i));
  result.addAll(right.sublist(j));
  return result;
}
''',
        },
        complexityTime: 'O(n log n)',
        complexitySpace: 'O(n)',
      ),
    },
  ),

  'fibonacci': ProblemEntry(
    id: 'fibonacci',
    title: 'Fibonacci',
    tags: ['fibonacci', 'fibonacci sequence', 'fib', 'nth fibonacci number'],
    variants: {
      'Recursion': ParadigmVariant(
        defaultNaming: const NamingContext(values: {'n': '10'}),
        pseudocodeTemplate: '''
function fibonacci(n = {{n}}):
    if n == 1 or n == 2:
        return 1
    return fibonacci(n - 1) + fibonacci(n - 2)
''',
        flowchart: const FlowchartData(
          nodes: [
            FlowNode(id: 'start', type: 'start', label: 'Start: n = {{n}}', x: 40, y: 20),
            FlowNode(id: 'base', type: 'decision', label: 'n <= 2?', x: 40, y: 100),
            FlowNode(id: 'baseReturn', type: 'end', label: 'Return 1', x: 300, y: 100),
            FlowNode(id: 'left', type: 'process', label: 'fib(n - 1)', x: 40, y: 184),
            FlowNode(id: 'right', type: 'process', label: 'fib(n - 2)', x: 40, y: 268),
            FlowNode(id: 'sum', type: 'end', label: 'Add results, return', x: 40, y: 352),
          ],
          edges: [
            FlowEdge(from: 'start', to: 'base'),
            FlowEdge(from: 'base', to: 'baseReturn', label: 'yes'),
            FlowEdge(from: 'base', to: 'left', label: 'no'),
            FlowEdge(from: 'left', to: 'right'),
            FlowEdge(from: 'right', to: 'sum'),
          ],
        ),
        codeTemplates: {
          'dart': '''
// Adapted from TheAlgorithms/Dart (MIT License): maths/fibonacci_recursion.dart
int fibonacci(int n) => n == 1 || n == 2 ? 1 : fibonacci(n - 1) + fibonacci(n - 2);

void main() {
  print(fibonacci({{n}}));
}
''',
        },
        complexityTime: 'O(2^n)',
        complexitySpace: 'O(n)',
      ),
      'Dynamic Programming': ParadigmVariant(
        defaultNaming: const NamingContext(values: {'n': '10'}),
        pseudocodeTemplate: '''
function fibonacci(n = {{n}}):
    if n == 1 or n == 2:
        return 1
    previous, current = 1, 1
    for i in 3..n:
        previous, current = current, previous + current
    return current
''',
        flowchart: const FlowchartData(
          nodes: [
            FlowNode(id: 'start', type: 'start', label: 'Start: n = {{n}}', x: 40, y: 20),
            FlowNode(id: 'base', type: 'decision', label: 'n <= 2?', x: 40, y: 100),
            FlowNode(id: 'baseReturn', type: 'end', label: 'Return 1', x: 300, y: 100),
            FlowNode(id: 'init', type: 'process', label: 'previous, current = 1, 1', x: 40, y: 184),
            FlowNode(id: 'loop', type: 'process', label: 'Advance previous, current up to n', x: 40, y: 268),
            FlowNode(id: 'done', type: 'end', label: 'Return current', x: 40, y: 352),
          ],
          edges: [
            FlowEdge(from: 'start', to: 'base'),
            FlowEdge(from: 'base', to: 'baseReturn', label: 'yes'),
            FlowEdge(from: 'base', to: 'init', label: 'no'),
            FlowEdge(from: 'init', to: 'loop'),
            FlowEdge(from: 'loop', to: 'done'),
          ],
        ),
        codeTemplates: {
          'dart': '''
// Adapted from TheAlgorithms/Dart (MIT License): maths/fibonacci_dynamic_programming.dart
// (simplified to a rolling O(1)-space tabulation — the source uses a
// precomputed memo array with modular arithmetic for competitive-programming
// use, which isn't relevant for a general-purpose worked example here).
int fibonacci(int n) {
  if (n == 1 || n == 2) return 1;
  var previous = 1, current = 1;
  for (var i = 3; i <= n; i++) {
    final next = previous + current;
    previous = current;
    current = next;
  }
  return current;
}
''',
        },
        complexityTime: 'O(n)',
        complexitySpace: 'O(1)',
      ),
    },
  ),

  'n_queens': ProblemEntry(
    id: 'n_queens',
    title: 'N-Queens',
    tags: ['n queens', 'n-queens', 'queens', 'chessboard', 'constraint satisfaction'],
    variants: {
      'Backtracking': ParadigmVariant(
        defaultNaming: const NamingContext(values: {'n': '8'}),
        pseudocodeTemplate: '''
function solveNQueens(n = {{n}}):
    board = empty n x n
    return backtrack(row = 0, n, board)

function backtrack(row, n, board):
    if row == n:
        return 1              // one full, valid arrangement found
    ways = 0
    for col in 0..n:
        if isSafe(board, row, col):
            place queen at (row, col)
            ways += backtrack(row + 1, n, board)
            remove queen at (row, col)   // backtrack
    return ways
''',
        flowchart: const FlowchartData(
          nodes: [
            FlowNode(id: 'start', type: 'start', label: 'Start: n = {{n}}', x: 40, y: 20),
            FlowNode(id: 'base', type: 'decision', label: 'row == n?', x: 40, y: 100),
            FlowNode(id: 'found', type: 'end', label: 'Solution found', x: 300, y: 100),
            FlowNode(id: 'tryCol', type: 'process', label: 'Try next column in row', x: 40, y: 184),
            FlowNode(id: 'safe', type: 'decision', label: 'Column/diagonals free?', x: 40, y: 268),
            FlowNode(id: 'place', type: 'process', label: 'Place queen, go to row + 1', x: 300, y: 268),
            FlowNode(id: 'remove', type: 'process', label: 'Remove queen (backtrack)', x: 40, y: 352),
          ],
          edges: [
            FlowEdge(from: 'start', to: 'base'),
            FlowEdge(from: 'base', to: 'found', label: 'yes'),
            FlowEdge(from: 'base', to: 'tryCol', label: 'no'),
            FlowEdge(from: 'tryCol', to: 'safe'),
            FlowEdge(from: 'safe', to: 'place', label: 'yes'),
            FlowEdge(from: 'safe', to: 'remove', label: 'no'),
            FlowEdge(from: 'place', to: 'remove'),
          ],
        ),
        codeTemplates: {
          'dart': '''
// Adapted from TheAlgorithms/Dart (MIT License): backtracking/n-queen.dart
int solveNQueens(int n) {
  final board = List.generate(n, (_) => List.filled(n, 0));
  return _backtrack(0, n, board);
}

bool _isSafe(List<List<int>> board, int size, int row, int col) {
  for (var k = 0; k < row; k++) {
    if (board[k][col] == 1) return false;
  }
  for (var i = row, j = col; i >= 0 && j >= 0; i--, j--) {
    if (board[i][j] == 1) return false;
  }
  for (var i = row, j = col; i >= 0 && j < size; i--, j++) {
    if (board[i][j] == 1) return false;
  }
  return true;
}

int _backtrack(int row, int size, List<List<int>> board) {
  if (row == size) return 1;
  var ways = 0;
  for (var col = 0; col < size; col++) {
    if (_isSafe(board, size, row, col)) {
      board[row][col] = 1;
      ways += _backtrack(row + 1, size, board);
      board[row][col] = 0;
    }
  }
  return ways;
}
''',
        },
        complexityTime: 'O(N!)',
        complexitySpace: 'O(N^2)',
      ),
      'Branch and Bound': ParadigmVariant(
        defaultNaming: const NamingContext(values: {'n': '8'}),
        pseudocodeTemplate: '''
function solveNQueensBB(n = {{n}}):
    cols, diag1, diag2 = empty boolean sets   // bounds: track attacked lines
    return branchAndBound(row = 0, n, cols, diag1, diag2)

function branchAndBound(row, n, cols, diag1, diag2):
    if row == n:
        return 1
    ways = 0
    for col in 0..n:
        d1 = row - col
        d2 = row + col
        if col not in cols and d1 not in diag1 and d2 not in diag2:
            mark col, d1, d2 as attacked        // bound: prune this branch early
            ways += branchAndBound(row + 1, n, cols, diag1, diag2)
            unmark col, d1, d2                  // backtrack
    return ways
''',
        flowchart: const FlowchartData(
          nodes: [
            FlowNode(id: 'start', type: 'start', label: 'Start: n = {{n}}', x: 40, y: 20),
            FlowNode(id: 'base', type: 'decision', label: 'row == n?', x: 40, y: 100),
            FlowNode(id: 'found', type: 'end', label: 'Solution found', x: 300, y: 100),
            FlowNode(id: 'tryCol', type: 'process', label: 'Try next column in row', x: 40, y: 184),
            FlowNode(id: 'bound', type: 'decision', label: 'Column/diagonal bound free?', x: 40, y: 268),
            FlowNode(id: 'mark', type: 'process', label: 'Mark bounds, go to row + 1', x: 300, y: 268),
            FlowNode(id: 'unmark', type: 'process', label: 'Unmark bounds (backtrack)', x: 40, y: 352),
          ],
          edges: [
            FlowEdge(from: 'start', to: 'base'),
            FlowEdge(from: 'base', to: 'found', label: 'yes'),
            FlowEdge(from: 'base', to: 'tryCol', label: 'no'),
            FlowEdge(from: 'tryCol', to: 'bound'),
            FlowEdge(from: 'bound', to: 'mark', label: 'yes'),
            FlowEdge(from: 'bound', to: 'unmark', label: 'no'),
            FlowEdge(from: 'mark', to: 'unmark'),
          ],
        ),
        codeTemplates: {
          'dart': '''
// Original — TheAlgorithms/Dart only has the plain backtracking variant
// (backtracking/n-queen.dart). This swaps its per-cell board scan for
// three boolean "bound" arrays tracking attacked columns/diagonals, so
// each candidate placement is checked in O(1) instead of O(n) — the
// pruning strategy that makes this branch-and-bound rather than
// backtracking, even though the recursion shape looks similar.
int solveNQueensBranchAndBound(int n) {
  final cols = List.filled(n, false);
  final diag1 = List.filled(2 * n - 1, false); // indexed by row - col + (n - 1)
  final diag2 = List.filled(2 * n - 1, false); // indexed by row + col

  int search(int row) {
    if (row == n) return 1;
    var ways = 0;
    for (var col = 0; col < n; col++) {
      final d1 = row - col + (n - 1);
      final d2 = row + col;
      if (!cols[col] && !diag1[d1] && !diag2[d2]) {
        cols[col] = diag1[d1] = diag2[d2] = true;
        ways += search(row + 1);
        cols[col] = diag1[d1] = diag2[d2] = false;
      }
    }
    return ways;
  }

  return search(0);
}
''',
        },
        complexityTime: 'O(N!)',
        complexitySpace: 'O(N)',
      ),
    },
  ),

  'knapsack_01': ProblemEntry(
    id: 'knapsack_01',
    title: '0/1 Knapsack',
    tags: ['knapsack', '0/1 knapsack', 'knapsack problem', 'maximize value capacity'],
    variants: {
      'Brute Force': ParadigmVariant(
        defaultNaming: const NamingContext(values: {'capacity': '15', 'object': 'the items'}),
        pseudocodeTemplate: '''
function knapsack(capacity = {{capacity}}, values, weights):
    return choose(capacity, values, weights, values.length)

function choose(capacity, values, weights, itemsLeft):
    if itemsLeft == 0 or capacity == 0:
        return 0
    item = itemsLeft - 1
    if weights[item] > capacity:
        return choose(capacity, values, weights, itemsLeft - 1)
    take = values[item] + choose(capacity - weights[item], values, weights, itemsLeft - 1)
    skip = choose(capacity, values, weights, itemsLeft - 1)
    return max(take, skip)

// Choosing from among {{object}}, capacity {{capacity}}.
''',
        flowchart: const FlowchartData(
          nodes: [
            FlowNode(id: 'start', type: 'start', label: 'Start: capacity = {{capacity}}', x: 40, y: 20),
            FlowNode(id: 'base', type: 'decision', label: 'No items left or capacity 0?', x: 40, y: 100),
            FlowNode(id: 'baseReturn', type: 'end', label: 'Return 0', x: 300, y: 100),
            FlowNode(id: 'fits', type: 'decision', label: 'Item fits in capacity?', x: 40, y: 184),
            FlowNode(id: 'skipOnly', type: 'process', label: 'Skip item (too heavy)', x: 300, y: 184),
            FlowNode(id: 'branch', type: 'process', label: 'Try take vs. skip item', x: 40, y: 268),
            FlowNode(id: 'best', type: 'end', label: 'Return the better of the two', x: 40, y: 352),
          ],
          edges: [
            FlowEdge(from: 'start', to: 'base'),
            FlowEdge(from: 'base', to: 'baseReturn', label: 'yes'),
            FlowEdge(from: 'base', to: 'fits', label: 'no'),
            FlowEdge(from: 'fits', to: 'skipOnly', label: 'no'),
            FlowEdge(from: 'fits', to: 'branch', label: 'yes'),
            FlowEdge(from: 'branch', to: 'best'),
            FlowEdge(from: 'skipOnly', to: 'best'),
          ],
        ),
        codeTemplates: {
          'dart': '''
// Adapted from TheAlgorithms/Dart (MIT License): dynamic_programming/01knapsack_recursive.dart
// (the source file's name is misleading — this is plain exhaustive
// recursion with no memoization, i.e. brute force; see the Dynamic
// Programming variant of this entry for the memoized version).
int knapsack(int capacity, List<int> values, List<int> weights, [int? itemsLeft]) {
  itemsLeft ??= values.length;
  if (itemsLeft == 0 || capacity == 0) return 0;

  final item = itemsLeft - 1;
  if (weights[item] > capacity) {
    return knapsack(capacity, values, weights, itemsLeft - 1);
  }
  final take = values[item] + knapsack(capacity - weights[item], values, weights, itemsLeft - 1);
  final skip = knapsack(capacity, values, weights, itemsLeft - 1);
  return take > skip ? take : skip;
}
''',
        },
        complexityTime: 'O(2^n)',
        complexitySpace: 'O(n)',
      ),
      'Dynamic Programming': ParadigmVariant(
        defaultNaming: const NamingContext(values: {'capacity': '15', 'object': 'the items'}),
        pseudocodeTemplate: '''
function knapsack(capacity = {{capacity}}, values, weights):
    n = values.length
    table = (n + 1) x (capacity + 1) grid of 0

    for i in 1..n:
        for c in 0..capacity:
            if weights[i - 1] <= c:
                table[i][c] = max(table[i - 1][c], values[i - 1] + table[i - 1][c - weights[i - 1]])
            else:
                table[i][c] = table[i - 1][c]

    return table[n][capacity]

// Filling {{capacity}} worth of capacity from {{object}}.
''',
        flowchart: const FlowchartData(
          nodes: [
            FlowNode(id: 'start', type: 'start', label: 'Start: capacity = {{capacity}}', x: 40, y: 20),
            FlowNode(id: 'init', type: 'process', label: 'Build (n+1) x (capacity+1) table of 0s', x: 40, y: 100),
            FlowNode(id: 'loopItems', type: 'process', label: 'For each item i', x: 40, y: 184),
            FlowNode(id: 'loopCap', type: 'process', label: 'For each capacity c', x: 40, y: 268),
            FlowNode(id: 'fits', type: 'decision', label: 'Item i fits in c?', x: 300, y: 268),
            FlowNode(id: 'fill', type: 'process', label: 'table[i][c] = best of take/skip', x: 40, y: 352),
            FlowNode(id: 'done', type: 'end', label: 'Return table[n][capacity]', x: 300, y: 352),
          ],
          edges: [
            FlowEdge(from: 'start', to: 'init'),
            FlowEdge(from: 'init', to: 'loopItems'),
            FlowEdge(from: 'loopItems', to: 'loopCap'),
            FlowEdge(from: 'loopCap', to: 'fits'),
            FlowEdge(from: 'fits', to: 'fill', label: 'yes/no'),
            FlowEdge(from: 'fill', to: 'done'),
          ],
        ),
        codeTemplates: {
          'dart': '''
// Original — TheAlgorithms/Dart only has the recursive brute-force
// version (see the Brute Force variant of this entry). This is the
// classic bottom-up tabulation.
int knapsackDp(int capacity, List<int> values, List<int> weights) {
  final n = values.length;
  final table = List.generate(n + 1, (_) => List.filled(capacity + 1, 0));

  for (var i = 1; i <= n; i++) {
    for (var c = 0; c <= capacity; c++) {
      if (weights[i - 1] <= c) {
        final take = values[i - 1] + table[i - 1][c - weights[i - 1]];
        final skip = table[i - 1][c];
        table[i][c] = take > skip ? take : skip;
      } else {
        table[i][c] = table[i - 1][c];
      }
    }
  }

  return table[n][capacity];
}
''',
        },
        complexityTime: 'O(n * capacity)',
        complexitySpace: 'O(n * capacity)',
      ),
    },
  ),

  'coin_change': ProblemEntry(
    id: 'coin_change',
    title: 'Coin Change',
    tags: ['coin change', 'minimum coins', 'make change', 'coin denominations'],
    variants: {
      'Dynamic Programming': ParadigmVariant(
        defaultNaming: const NamingContext(values: {'target': '11', 'object': 'the coin denominations'}),
        pseudocodeTemplate: '''
function minCoins(target = {{target}}, coins):
    best = array of size target + 1, filled with infinity
    best[0] = 0

    for coin in coins:
        for amount in coin..target:
            best[amount] = min(best[amount], best[amount - coin] + 1)

    if best[target] is infinity:
        return -1     // no combination reaches target
    return best[target]

// Making change for {{target}} using {{object}}.
''',
        flowchart: const FlowchartData(
          nodes: [
            FlowNode(id: 'start', type: 'start', label: 'Start: target = {{target}}', x: 40, y: 20),
            FlowNode(id: 'init', type: 'process', label: 'best[0..target] = infinity, best[0] = 0', x: 40, y: 100),
            FlowNode(id: 'loopCoins', type: 'process', label: 'For each coin', x: 40, y: 184),
            FlowNode(id: 'loopAmt', type: 'process', label: 'For amount from coin to target', x: 40, y: 268),
            FlowNode(id: 'relax', type: 'process', label: 'best[amount] = min(best[amount], best[amount-coin]+1)', x: 40, y: 352),
            FlowNode(id: 'check', type: 'decision', label: 'best[target] reachable?', x: 300, y: 268),
            FlowNode(id: 'done', type: 'end', label: 'Return best[target]', x: 300, y: 352),
            FlowNode(id: 'none', type: 'end', label: 'Return -1', x: 300, y: 184),
          ],
          edges: [
            FlowEdge(from: 'start', to: 'init'),
            FlowEdge(from: 'init', to: 'loopCoins'),
            FlowEdge(from: 'loopCoins', to: 'loopAmt'),
            FlowEdge(from: 'loopAmt', to: 'relax'),
            FlowEdge(from: 'relax', to: 'check'),
            FlowEdge(from: 'check', to: 'done', label: 'yes'),
            FlowEdge(from: 'check', to: 'none', label: 'no'),
          ],
        ),
        codeTemplates: {
          'dart': '''
// Adapted from TheAlgorithms/Dart (MIT License): dynamic_programming/coin_change.dart
int minCoins(int target, List<int> coins) {
  const unreachable = 1000000000;
  final best = List<int>.filled(target + 1, unreachable);
  best[0] = 0;

  for (final coin in coins) {
    for (var amount = coin; amount <= target; amount++) {
      final withCoin = best[amount - coin] + 1;
      if (withCoin < best[amount]) best[amount] = withCoin;
    }
  }

  return best[target] == unreachable ? -1 : best[target];
}
''',
        },
        complexityTime: 'O(target * coins)',
        complexitySpace: 'O(target)',
      ),
      'Greedy': ParadigmVariant(
        defaultNaming: const NamingContext(values: {'target': '11', 'object': 'the coin denominations'}),
        pseudocodeTemplate: '''
function minCoinsGreedy(target = {{target}}, coins):
    sort coins descending
    used = []
    remaining = target

    for coin in coins:
        while remaining >= coin:
            used.add(coin)
            remaining -= coin

    if remaining != 0:
        return -1     // greedy couldn't reach target exactly
    return used.length

// NOTE: greedy is only optimal for "canonical" coin systems (like most
// real-world currencies). For arbitrary denominations it can overshoot,
// e.g. coins=[1,3,4], target=6 -> greedy picks 4+1+1 (3 coins) instead
// of the optimal 3+3 (2 coins). Use the Dynamic Programming variant when
// correctness matters.
''',
        flowchart: const FlowchartData(
          nodes: [
            FlowNode(id: 'start', type: 'start', label: 'Start: target = {{target}}', x: 40, y: 20),
            FlowNode(id: 'sort', type: 'process', label: 'Sort coins, largest first', x: 40, y: 100),
            FlowNode(id: 'loopCoins', type: 'process', label: 'For each coin (largest first)', x: 40, y: 184),
            FlowNode(id: 'take', type: 'process', label: 'Take coin while it still fits', x: 40, y: 268),
            FlowNode(id: 'check', type: 'decision', label: 'remaining == 0?', x: 300, y: 268),
            FlowNode(id: 'done', type: 'end', label: 'Return coin count', x: 300, y: 352),
            FlowNode(id: 'fail', type: 'end', label: 'Return -1 (no exact match)', x: 40, y: 352),
          ],
          edges: [
            FlowEdge(from: 'start', to: 'sort'),
            FlowEdge(from: 'sort', to: 'loopCoins'),
            FlowEdge(from: 'loopCoins', to: 'take'),
            FlowEdge(from: 'take', to: 'check'),
            FlowEdge(from: 'check', to: 'done', label: 'yes'),
            FlowEdge(from: 'check', to: 'fail', label: 'no'),
          ],
        ),
        codeTemplates: {
          'dart': '''
// Original — TheAlgorithms/Dart's coin_change.dart is the DP version
// (see the Dynamic Programming variant of this entry). Greedy is NOT
// guaranteed optimal for arbitrary coin systems — see the pseudocode
// note. Included mainly for contrast with the DP variant.
int minCoinsGreedy(int target, List<int> coins) {
  final sorted = [...coins]..sort((a, b) => b.compareTo(a));
  var remaining = target;
  var used = 0;

  for (final coin in sorted) {
    while (remaining >= coin) {
      remaining -= coin;
      used++;
    }
  }

  return remaining == 0 ? used : -1;
}
''',
        },
        complexityTime: 'O(coins log coins + target / smallest coin)',
        complexitySpace: 'O(coins)',
      ),
    },
  ),

  'subset_sum': ProblemEntry(
    id: 'subset_sum',
    title: 'Subset Sum',
    tags: ['subset sum', 'subset sum problem', 'target sum from set'],
    variants: {
      'Backtracking': ParadigmVariant(
        defaultNaming: const NamingContext(values: {'target': '9', 'object': 'the numbers'}),
        pseudocodeTemplate: '''
function hasSubsetSum(target = {{target}}, numbers):
    return search(numbers, index = 0, remaining = target)

function search(numbers, index, remaining):
    if remaining == 0:
        return true
    if remaining < 0 or index == numbers.length:
        return false

    // try including numbers[index]...
    if search(numbers, index + 1, remaining - numbers[index]):
        return true
    // ...or backtrack and skip it
    return search(numbers, index + 1, remaining)

// Looking for a subset of {{object}} that sums to {{target}}.
''',
        flowchart: const FlowchartData(
          nodes: [
            FlowNode(id: 'start', type: 'start', label: 'Start: target = {{target}}', x: 40, y: 20),
            FlowNode(id: 'base', type: 'decision', label: 'remaining == 0?', x: 40, y: 100),
            FlowNode(id: 'yesFound', type: 'end', label: 'Subset found', x: 300, y: 100),
            FlowNode(id: 'exhausted', type: 'decision', label: 'remaining < 0 or out of numbers?', x: 40, y: 184),
            FlowNode(id: 'noneFound', type: 'end', label: 'No subset works', x: 300, y: 184),
            FlowNode(id: 'include', type: 'process', label: 'Include current number, recurse', x: 40, y: 268),
            FlowNode(id: 'exclude', type: 'process', label: 'Backtrack: exclude it, recurse', x: 40, y: 352),
          ],
          edges: [
            FlowEdge(from: 'start', to: 'base'),
            FlowEdge(from: 'base', to: 'yesFound', label: 'yes'),
            FlowEdge(from: 'base', to: 'exhausted', label: 'no'),
            FlowEdge(from: 'exhausted', to: 'noneFound', label: 'yes'),
            FlowEdge(from: 'exhausted', to: 'include', label: 'no'),
            FlowEdge(from: 'include', to: 'exclude'),
          ],
        ),
        codeTemplates: {
          'dart': '''
// Original — TheAlgorithms/Dart has no Subset Sum entry.
bool hasSubsetSum(int target, List<int> numbers) {
  bool search(int index, int remaining) {
    if (remaining == 0) return true;
    if (remaining < 0 || index == numbers.length) return false;

    if (search(index + 1, remaining - numbers[index])) return true;
    return search(index + 1, remaining);
  }

  return search(0, target);
}
''',
        },
        complexityTime: 'O(2^n)',
        complexitySpace: 'O(n)',
      ),
      'Dynamic Programming': ParadigmVariant(
        defaultNaming: const NamingContext(values: {'target': '9', 'object': 'the numbers'}),
        pseudocodeTemplate: '''
function hasSubsetSum(target = {{target}}, numbers):
    reachable = boolean array of size target + 1, all false
    reachable[0] = true

    for number in numbers:
        for sum from target down to number:
            if reachable[sum - number]:
                reachable[sum] = true

    return reachable[target]

// Looking for a subset of {{object}} that sums to {{target}}.
''',
        flowchart: const FlowchartData(
          nodes: [
            FlowNode(id: 'start', type: 'start', label: 'Start: target = {{target}}', x: 40, y: 20),
            FlowNode(id: 'init', type: 'process', label: 'reachable[0..target] = false, reachable[0] = true', x: 40, y: 100),
            FlowNode(id: 'loopNum', type: 'process', label: 'For each number', x: 40, y: 184),
            FlowNode(id: 'loopSum', type: 'process', label: 'For sum from target down to number', x: 40, y: 268),
            FlowNode(id: 'update', type: 'process', label: 'reachable[sum] |= reachable[sum - number]', x: 40, y: 352),
            FlowNode(id: 'done', type: 'end', label: 'Return reachable[target]', x: 300, y: 268),
          ],
          edges: [
            FlowEdge(from: 'start', to: 'init'),
            FlowEdge(from: 'init', to: 'loopNum'),
            FlowEdge(from: 'loopNum', to: 'loopSum'),
            FlowEdge(from: 'loopSum', to: 'update'),
            FlowEdge(from: 'update', to: 'done'),
          ],
        ),
        codeTemplates: {
          'dart': '''
// Original — TheAlgorithms/Dart has no Subset Sum entry.
bool hasSubsetSumDp(int target, List<int> numbers) {
  final reachable = List<bool>.filled(target + 1, false);
  reachable[0] = true;

  for (final number in numbers) {
    for (var sum = target; sum >= number; sum--) {
      if (reachable[sum - number]) reachable[sum] = true;
    }
  }

  return reachable[target];
}
''',
        },
        complexityTime: 'O(n * target)',
        complexitySpace: 'O(target)',
      ),
    },
  ),

  'activity_selection': ProblemEntry(
    id: 'activity_selection',
    title: 'Activity Selection',
    tags: ['activity selection', 'interval scheduling', 'maximum non overlapping activities'],
    variants: {
      'Greedy': ParadigmVariant(
        defaultNaming: const NamingContext(values: {'object': 'the activities'}),
        pseudocodeTemplate: '''
function selectActivities({{object}}):
    sort {{object}} by finish time, ascending
    selected = [first activity]
    lastFinish = finish time of first activity

    for activity in remaining {{object}}:
        if activity.start >= lastFinish:
            selected.add(activity)
            lastFinish = activity.finish

    return selected
''',
        flowchart: const FlowchartData(
          nodes: [
            FlowNode(id: 'start', type: 'start', label: 'Start: {{object}}', x: 40, y: 20),
            FlowNode(id: 'sort', type: 'process', label: 'Sort by finish time', x: 40, y: 100),
            FlowNode(id: 'pick', type: 'process', label: 'Select first activity', x: 40, y: 184),
            FlowNode(id: 'loop', type: 'process', label: 'For each remaining activity', x: 40, y: 268),
            FlowNode(id: 'fits', type: 'decision', label: 'Starts after last selected finishes?', x: 40, y: 352),
            FlowNode(id: 'add', type: 'process', label: 'Select it, update last finish', x: 300, y: 352),
            FlowNode(id: 'skip', type: 'process', label: 'Skip it', x: 300, y: 268),
          ],
          edges: [
            FlowEdge(from: 'start', to: 'sort'),
            FlowEdge(from: 'sort', to: 'pick'),
            FlowEdge(from: 'pick', to: 'loop'),
            FlowEdge(from: 'loop', to: 'fits'),
            FlowEdge(from: 'fits', to: 'add', label: 'yes'),
            FlowEdge(from: 'fits', to: 'skip', label: 'no'),
          ],
        ),
        codeTemplates: {
          'dart': '''
// Original — TheAlgorithms/Dart has no Activity Selection entry.
class Activity {
  final int start;
  final int finish;
  const Activity(this.start, this.finish);
}

List<Activity> selectActivities(List<Activity> activities) {
  final sorted = [...activities]..sort((a, b) => a.finish.compareTo(b.finish));
  final selected = <Activity>[sorted.first];
  var lastFinish = sorted.first.finish;

  for (final activity in sorted.skip(1)) {
    if (activity.start >= lastFinish) {
      selected.add(activity);
      lastFinish = activity.finish;
    }
  }

  return selected;
}
''',
        },
        complexityTime: 'O(n log n)',
        complexitySpace: 'O(n)',
      ),
    },
  ),

  'binary_search': ProblemEntry(
    id: 'binary_search',
    title: 'Binary Search',
    tags: ['binary search', 'search sorted array', 'find in sorted list'],
    variants: {
      'Divide and Conquer': ParadigmVariant(
        defaultNaming: const NamingContext(values: {'object': 'the sorted list', 'target': '55'}),
        pseudocodeTemplate: '''
function search({{object}}, target = {{target}}, low = 0, high = length({{object}}) - 1):
    if low > high:
        return -1          // not found

    mid = low + (high - low) / 2
    if {{object}}[mid] == target:
        return mid
    if {{object}}[mid] > target:
        return search({{object}}, target, low, mid - 1)
    return search({{object}}, target, mid + 1, high)
''',
        flowchart: const FlowchartData(
          nodes: [
            FlowNode(id: 'start', type: 'start', label: 'Start: search for {{target}} in {{object}}', x: 40, y: 20),
            FlowNode(id: 'base', type: 'decision', label: 'low > high?', x: 40, y: 100),
            FlowNode(id: 'notFound', type: 'end', label: 'Return -1 (not found)', x: 300, y: 100),
            FlowNode(id: 'mid', type: 'process', label: 'mid = middle of [low, high]', x: 40, y: 184),
            FlowNode(id: 'match', type: 'decision', label: 'Element at mid == target?', x: 40, y: 268),
            FlowNode(id: 'found', type: 'end', label: 'Return mid', x: 300, y: 268),
            FlowNode(id: 'narrow', type: 'process', label: 'Search left or right half', x: 40, y: 352),
          ],
          edges: [
            FlowEdge(from: 'start', to: 'base'),
            FlowEdge(from: 'base', to: 'notFound', label: 'yes'),
            FlowEdge(from: 'base', to: 'mid', label: 'no'),
            FlowEdge(from: 'mid', to: 'match'),
            FlowEdge(from: 'match', to: 'found', label: 'yes'),
            FlowEdge(from: 'match', to: 'narrow', label: 'no'),
          ],
        ),
        codeTemplates: {
          'dart': '''
// Adapted from TheAlgorithms/Dart (MIT License): search/binary_Search.dart
int search(List<int> sortedList, int target, [int? low, int? high]) {
  low ??= 0;
  high ??= sortedList.length - 1;
  if (low > high) return -1;

  final mid = low + ((high - low) ~/ 2);
  if (sortedList[mid] == target) return mid;
  if (sortedList[mid] > target) return search(sortedList, target, low, mid - 1);
  return search(sortedList, target, mid + 1, high);
}
''',
        },
        complexityTime: 'O(log n)',
        complexitySpace: 'O(log n)',
      ),
    },
  ),
};

// ---------- Example: naming context flowing end to end ----------

void exampleUsage() {
  // Simulated AI response for user input:
  // "Help Maria sort her stack of exam papers by score"
  final classification = ClassificationResult.fromJson({
    'matchedProblemId': 'merge_sort',
    'confidence': 0.9,
    'extractedParams': {},
    'namingContext': {'person': 'Maria', 'object': 'examPapers'},
    'alternativeMatches': [],
  });

  final solutions = resolveSolutions(classification, algorithmLibrary);
  // solutions.first.pseudocode now reads "function sortExamPapers(examPapers): ..."
  // and "// Maria ends up with examPapers, fully sorted." — personalized,
  // with zero change needed to the substitution logic itself.
  print(solutions.first.pseudocode);
}
