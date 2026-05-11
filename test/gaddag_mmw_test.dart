import 'package:gaddag_mmw/gaddag_mmw.dart';
import 'package:test/test.dart';

void main() {
  group('GADDAG Tests', () {
    late Gaddag gaddag;

    setUp(() {
      gaddag = Gaddag();
    });

    test('contains returns false for empty or unknown words', () {
      expect(gaddag.contains(''), isFalse);
      expect(gaddag.contains('anything'), isFalse);
    });

    test('addWord adds a word that can be found with contains', () {
      gaddag.addWord('hello');
      gaddag.minimize();
      expect(gaddag.contains('hello'), isTrue);
    });

    test('contains works for single letter words', () {
      gaddag.addWord('a');
      gaddag.minimize();
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
      gaddag.minimize();

      // Helper to manually traverse the GADDAG
      bool hasPath(String path) {
        var currentNode = gaddag.root;
        for (var i = 0; i < path.length; i++) {
          var char = path[i].codeUnitAt(0);
          if (currentNode.get(char) == null) {
            return false;
          }
          currentNode = currentNode.get(char)!;
        }
        return currentNode.isTerminal;
      }
      
      expect(hasPath('c+at'), isTrue, reason: 'Should contain path c+at');
      expect(hasPath('ac+t'), isTrue, reason: 'Should contain path ac+t');
      expect(hasPath('tac+'), isTrue, reason: 'Should contain path tac');
    });

    test('addWord handles multiple words', () {
      gaddag.addWord('dog');
      gaddag.addWord('dad');
      gaddag.minimize();

      expect(gaddag.contains('dog'), isTrue);
      expect(gaddag.contains('dad'), isTrue);
      expect(gaddag.contains('cat'), isFalse);
    });

    test('findWordsWithSubstring returns correct words', () {
      gaddag.addWord('explain');
      gaddag.addWord('plain');
      gaddag.addWord('plane');
      gaddag.addWord('ex');
      gaddag.minimize();

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

    test('explain and complain use common node for common suffix', () {
      gaddag.addWord("explain");
      gaddag.addWord("complain");
      gaddag.minimize();

      GaddagNode? exCurrent = gaddag.root;
      //walk path for xe+p
      String pathprefix = "xe+p";
      List<String> pathLetters = pathprefix.split('');
      for (String letter in pathLetters){
        exCurrent = exCurrent?.get(letter.codeUnitAt(0));
      }
      GaddagNode? comCurrent = gaddag.root;
      //walk path for moc+p
      pathprefix = "moc+p";
      pathLetters = pathprefix.split('');
      for (String letter in pathLetters) {
        comCurrent = comCurrent?.get(letter.codeUnitAt(0));
      }

      if (exCurrent == null || comCurrent == null) {
        expect(false, isTrue);
      }

      expect(exCurrent == comCurrent, isTrue);
    });

    test('does not contain synthetic words caused by graph mistakes', () {
      // see https://jbp.dev/blog/dawg-basics.html for origin of test case

      //intentionally not alphabetical.  SHOULDN'T MATTER

      gaddag.addWord('cat');
      gaddag.addWord('fact');
      gaddag.addWord('facet');
      gaddag.minimize();

      expect(gaddag.contains('cat'), isTrue);
      expect(gaddag.contains('caet'), isFalse);

    });

    test('only get out what we put in', () {
      // see https://jbp.dev/blog/dawg-basics.html for origin of test case

      //intentionally not alphabetical.  SHOULDN'T MATTER

      List<String> words = ['cat', 'fact', 'facet', 'car', 'care', 'caret', 'faucet', 'vicar'];
      for (String word in words){
        gaddag.addWord(word);
      }
      gaddag.minimize();

      var results = gaddag.findWordsWithSubstring('');

      expect(results.length == words.length, isTrue);
      for (String word in words) {
        expect(results.contains(word), isTrue);
      }
    });
  });
}
