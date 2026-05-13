/**
Represents an interface to a node in a Gaddag
 */
abstract class DawgWalker {
  DawgWalker? getChild(String letter);

  bool isTerminal();
}