<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages). 
-->

GADDAG_mmw is an implementation of the [GADDAG data structure](https://en.wikipedia.org/wiki/GADDAG), which is useful for
fast lookup of the existence of a string starting from any character within it.  This
is useful for finding words by substring, or backwards AND forwards from a constraint.
GADDAG_mmw is used for this purpose in [Mark My Words](https://markmywordsgame.com)

## Features
* Fast lookup of the existence of a string starting from any character within it.
* Find words by substring
* Find words by backwards AND forwards from a constraint
* direct access to underlying GADDAGNode for advanced traversal

## Usage

The GADDAG can be used like a Trie, for quick lookup of the existence of a string.

```dart
  GADDAG gaddag = GADDAG();
  gaddag.addWord('cat');
  print(gaddag.contains('cat'));
```
But to use it for advanced traversal, access the inner GADDAGNode
```dart
  GADDAG gaddag = GADDAG();
  gaddag.addWord('cat');
  GADDAGNode root = gaddag.root;
```
