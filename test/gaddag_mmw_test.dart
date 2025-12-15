import 'package:gaddag_mmw/gaddag_mmw.dart';
import 'package:test/test.dart';

void main() {
  group('GADDAG Tests', () {
    late GADDAG gaddag;

    setUp(() {
      gaddag = GADDAG();
    });

    test('contains returns false for empty or unknown words', () {
      expect(gaddag.contains(''), isFalse);
      expect(gaddag.contains('anything'), isFalse);
    });

    test('addWord adds a word that can be found with contains', () {
      gaddag.addWord('hello');
      expect(gaddag.contains('hello'), isTrue);
    });

    test('contains works for single letter words', () {
      gaddag.addWord('a');
      expect(gaddag.contains('a'), isTrue);
      expect(gaddag.contains('b'), isFalse);
    });

    test('GADDAG creates all expected paths for a word', () {
      // "cat"
      // Paths:
      // c+at
      // ac+t
      // tac
      
      gaddag.addWord('cat');
      
      // Helper to manually traverse the GADDAG
      bool hasPath(String path) {
        var currentNode = gaddag.root;
        for (var i = 0; i < path.length; i++) {
          var char = path[i];
          if (!currentNode.children.containsKey(char)) {
            return false;
          }
          currentNode = currentNode.children[char]!;
        }
        return currentNode.isTerminal;
      }
      
      expect(hasPath('c+at'), isTrue, reason: 'Should contain path c+at');
      expect(hasPath('ac+t'), isTrue, reason: 'Should contain path ac+t');
      expect(hasPath('tac'), isTrue, reason: 'Should contain path tac');
    });

    test('addWord handles multiple words', () {
      gaddag.addWord('dog');
      gaddag.addWord('dad');
      
      expect(gaddag.contains('dog'), isTrue);
      expect(gaddag.contains('dad'), isTrue);
      expect(gaddag.contains('cat'), isFalse);
    });

    test('findWordsWithSubstring returns correct words', () {
      gaddag.addWord('explain');
      gaddag.addWord('plain');
      gaddag.addWord('plane');
      gaddag.addWord('ex');

      var results = gaddag.findWordsWithSubstring('pla');
      expect(results, hasLength(3));
      expect(results, containsAll(['explain', 'plain', 'plane']));
      expect(results, isNot(contains('ex')));

      results = gaddag.findWordsWithSubstring('plain');
      expect(results, containsAll(['explain', 'plain']));
      expect(results, isNot(contains('plane')));

      results = gaddag.findWordsWithSubstring('ex');
      expect(results, containsAll(['explain', 'ex']));
      
      results = gaddag.findWordsWithSubstring('z');
      expect(results, isEmpty);
    });
  });
}
