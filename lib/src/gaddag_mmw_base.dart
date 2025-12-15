/// A GADDAG is a specialized Trie, a data structure used to store strings for efficient lookup of
/// the existence of a string starting from any character within it.
/// This is achieved by storing both a (non-empty) reversed prefix, separator value,
/// and suffix for each letter in the word.
///
/// For example, the word "explain" will be stored with all of the following paths
/// e+xplain
/// xe+plain
/// pxe+lain
/// lpxe+ain
/// alpxe+in
/// ialpxe+n
/// nialpxe
class GADDAGNode {
  final Map<String, GADDAGNode> children = {};
  bool isTerminal = false;
}

class GADDAG {
  final GADDAGNode root = GADDAGNode();
  static const String separator = '+';

  /// Adds a word to the GADDAG.
  void addWord(String word) {
    if (word.isEmpty) return;

    List<String> chars = word.split('');
    // Insert a path for every character in the word
    for (int i = 0; i < chars.length; i++) {
      _addPath(chars, i);
    }
  }

  void _addPath(List<String> chars, int startIndex) {
    GADDAGNode currentNode = root;

    // 1. The character at the start index (the 'root' of this GADDAG path)
    currentNode = _getOrCreateChild(currentNode, chars[startIndex]);

    // 2. The reversed prefix (characters before startIndex, in reverse order)
    for (int i = startIndex - 1; i >= 0; i--) {
      currentNode = _getOrCreateChild(currentNode, chars[i]);
    }

    // 3. Separator and Suffix (characters after startIndex)
    // The separator is only added if there is a suffix (i.e., we are not at the last character)
    if (startIndex < chars.length - 1) {
      currentNode = _getOrCreateChild(currentNode, separator);
      for (int i = startIndex + 1; i < chars.length; i++) {
        currentNode = _getOrCreateChild(currentNode, chars[i]);
      }
    }

    currentNode.isTerminal = true;
  }

  GADDAGNode _getOrCreateChild(GADDAGNode node, String char) {
    return node.children.putIfAbsent(char, () => GADDAGNode());
  }

  /// Checks if the GADDAG contains the given word.
  /// This checks for the specific path corresponding to the word starting at the first character,
  /// which is consistent with the standard Trie lookup if we treat GADDAG as containing the word.
  bool contains(String word) {
    if (word.isEmpty) return false;
    
    // To check for a word "W", we can look for the path corresponding to its first character.
    // For "explain", this is "e+xplain".
    
    GADDAGNode? node = root.children[word[0]];
    if (node == null) return false;
    
    if (word.length > 1) {
      node = node.children[separator];
      if (node == null) return false;
      
      for (int i = 1; i < word.length; i++) {
        node = node!.children[word[i]];
        if (node == null) return false;
      }
    }
    
    return node!.isTerminal;
  }

  /// Finds words that contain some substring
  List<String> findWordsWithSubstring(String substring) {
    if (substring.isEmpty) return [];

    GADDAGNode? currentNode = root;
    List<String> path = [];

    // 1. Traverse the reversed substring.
    // If we search for "bcd", we look for the path d -> c -> b.
    // This path leads to the state where we have matched "bcd" backwards.
    for (int i = substring.length - 1; i >= 0; i--) {
      String char = substring[i];
      currentNode = currentNode?.children[char];
      if (currentNode == null) {
        return []; // Substring not found in any word
      }
      path.add(char);
    }

    // 2. From this node, find all terminal nodes via DFS.
    Set<String> results = {};
    if (currentNode != null) {
      _dfsCollectWords(currentNode, path, results);
    }

    return results.toList();
  }

  void _dfsCollectWords(GADDAGNode node, List<String> currentPath, Set<String> results) {
    if (node.isTerminal) {
      results.add(_reconstructWord(currentPath));
    }

    node.children.forEach((char, childNode) {
      currentPath.add(char);
      _dfsCollectWords(childNode, currentPath, results);
      currentPath.removeLast();
    });
  }

  String _reconstructWord(List<String> path) {
    int sepIndex = path.indexOf(separator);
    if (sepIndex == -1) {
      return path.reversed.join('');
    }
    String prefix = path.sublist(0, sepIndex).reversed.join('');
    String suffix = path.sublist(sepIndex + 1).join('');
    return prefix + suffix;
  }
}
