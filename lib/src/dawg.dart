import 'dawg_walker.dart';

abstract class Dawg {
  //Use '+' as delimiter for path reversal in GADDAG
  static const String delimiter = '+';

  DawgWalker getRootDawgWalker();

  bool contains(String word);
}