
import 'package:meta/meta.dart';

class GaddagNode {
  // Using a Map for sparse edges. For production builds with fixed dictionaries,
  // this can later be flattened into parallel arrays to drop object overhead entirely.
  Map<int, GaddagNode>? edges;
  bool isTerminal = false;

  // Cached hash to speed up the minimization phase
  int? _cachedHash;

  GaddagNode();

  GaddagNode putIfAbsent(int charCode) {
    edges ??= {};
    return edges!.putIfAbsent(charCode, () => GaddagNode());
  }

  GaddagNode? get(int charCode) => edges?[charCode];

  /// Structural equality: Two nodes are equivalent if they have the same
  /// terminal status and their outgoing edges point to the exact same child nodes.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GaddagNode) return false;
    if (isTerminal != other.isTerminal) return false;

    final thisEdges = edges;
    final otherEdges = other.edges;

    if (thisEdges == null && otherEdges == null) return true;
    if (thisEdges == null || otherEdges == null) return false;
    if (thisEdges.length != otherEdges.length) return false;

    for (var entry in thisEdges.entries) {
      if (!identical(otherEdges[entry.key], entry.value)) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    if (_cachedHash != null) return _cachedHash!;

    int hash = isTerminal ? 1 : 0;
    if (edges != null) {
      // Sort keys to ensure stable structural hashing
      var keys = edges!.keys.toList(growable: false)..sort();
      for (var k in keys) {
        // Use the identity hash of the child, as children will already
        // be canonicalized when the parent's hash is calculated.
        hash = Object.hash(hash, k, identityHashCode(edges![k]));
      }
    }
    _cachedHash = hash;
    return hash;
  }
}

class Gaddag {
  GaddagNode root;

  // Using '+' (0x2B) as the delimiter. You can use any integer outside your alphabet.
  static const int delimiter = 0x2B;

  Gaddag() : root = GaddagNode();

  /// Adds a word to the GADDAG.
  /// Generates the paths: Reverse(Prefix) + Delimiter + Suffix
  void addWord(String word) {
    List<int> codes = word.codeUnits;
    int n = codes.length;

    for (int i = 0; i < n; i++) {
      GaddagNode current = root;

      // 1. Insert the prefix in reverse
      for (int j = i; j >= 0; j--) {
        current = current.putIfAbsent(codes[j]);
      }

      // 2. Insert the delimiter
      if (i+1 < n) {
        current = current.putIfAbsent(delimiter);
      }

      // 3. Insert the remaining suffix
      for (int j = i + 1; j < n; j++) {
        current = current.putIfAbsent(codes[j]);
      }

      // Mark the end of this specific GADDAG path
      current.isTerminal = true;
    }
  }

  /// Compresses the Trie into a minimal DAWG.
  /// Call this ONCE after all words have been added.
  void minimize() {
    var uniqueNodes = <GaddagNode, GaddagNode>{};
    root = _minimizeNode(root, uniqueNodes);
  }

  /// Post-order traversal: minimizes children before minimizing the parent.
  GaddagNode _minimizeNode(GaddagNode node, Map<GaddagNode, GaddagNode> uniqueNodes) {
    if (node.edges != null) {
      for (var entry in node.edges!.entries) {
        node.edges![entry.key] = _minimizeNode(entry.value, uniqueNodes);
      }
    }

    // After children are canonicalized, check if this node already exists
    if (uniqueNodes.containsKey(node)) {
      return uniqueNodes[node]!;
    } else {
      uniqueNodes[node] = node;
      return node;
    }
  }

  /// Checks if a complete word exists in the GADDAG.
  bool contains(String word) {
    if (word.isEmpty) return false;

    List<int> codes = word.codeUnits;
    GaddagNode? current = root;

    // To verify a full word, we follow the path of its completely reversed 
    // prefix (which is just the reversed word) followed by the delimiter.
    for (int i = codes.length - 1; i >= 0; i--) {
      current = current?.get(codes[i]);
      if (current == null) return false;
    }

    // Step into the delimiter node
    //current = current?.get(delimiter);

    // If we reached it and it's terminal, the word exists.
    return current?.isTerminal ?? false;
  }

  /// Returns a Set of all words that contain the given substring.
  /// Returns an empty set if the substring is not found.
  Set<String> findWordsWithSubstring(String substring) {
    List<int> codes = substring.codeUnits;
    GaddagNode? current = root;
    List<int> currentPath = [];

    // 1. Trace the reversed substring from the root.
    // If the substring exists anywhere in the dictionary, this reverse 
    // trace will successfully lead us to a valid node.
    for (int i = codes.length - 1; i >= 0; i--) {
      current = current?.get(codes[i]);
      if (current == null) return {}; // Substring doesn't exist in any word
      currentPath.add(codes[i]);
    }

    // 2. Perform a Depth-First Search (DFS) from this node to find all valid words.
    // We use a Set because words containing the substring multiple times 
    // (e.g., "A" in "BANANA") will be discovered through multiple prefix paths.
    Set<String> results = {};
    _dfsCollectWords(current!, currentPath, results);
    return results;
  }

  @visibleForTesting
  int countNodes() {
    // Set.identity() ignores your operator == and hashCode overrides,
    // counting the actual distinct objects in the heap.
    final seen = Set<GaddagNode>.identity();
    _dfsCountNodes(root, seen);
    return seen.length;
  }

  void _dfsCountNodes(GaddagNode node, Set<GaddagNode> seen) {
    if (!seen.add(node)) return; // .add returns false if already present

    final edges = node.edges;
    if (edges != null) {
      for (final child in edges.values) {
        _dfsCountNodes(child, seen);
      }
    }
  }
  /// Recursive helper to traverse the DAWG and reconstruct words.
  void _dfsCollectWords(GaddagNode node, List<int> pathChars, Set<String> results) {
    if (node.isTerminal) {
      // Find where our prefix trace ended and the suffix began
      int delimIndex = pathChars.indexOf(delimiter);

      if (delimIndex != -1) {
        // Characters before the delimiter are the reversed prefix
        Iterable<int> revPrefix = pathChars.take(delimIndex);
        // Characters after the delimiter are the standard suffix
        Iterable<int> suffix = pathChars.skip(delimIndex + 1);

        // Reconstruct the full word: Reverse(revPrefix) + suffix
        String word = String.fromCharCodes([
          ...revPrefix.toList(growable: false).reversed,
          ...suffix
        ]);
        results.add(word);
      } else {
        results.add(String.fromCharCodes(pathChars.reversed));
      }
    }

    // Continue DFS down all available edges
    if (node.edges != null) {
      for (var entry in node.edges!.entries) {
        pathChars.add(entry.key);
        _dfsCollectWords(entry.value, pathChars, results);
        pathChars.removeLast(); // Backtrack
      }
    }
  }  
}