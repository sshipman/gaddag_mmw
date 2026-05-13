import 'dart:io';
import 'dart:typed_data';

import 'package:gaddag_mmw/gaddag_mmw.dart';
import 'package:test/test.dart';

void main() {
  group('HotDawg tests', () {
    late HotDawg hotDawg;

    setUp(() async {
      final file = File('test/assets/enable.hotdawg');
      final Uint8List bytes = await file.readAsBytes();
      hotDawg = HotDawg.fromZlibData(bytes);
    });

    test('has a few arbitrary words', () {
      // these words were picked at random from the input dictionary
      expect(hotDawg.contains('trump'), isTrue);
      expect(hotDawg.contains('guilty'), isTrue);
      expect(hotDawg.contains('of'), isTrue);
      expect(hotDawg.contains('treason'), isTrue);
    });

    test('does not have a few arbitrary nonsense words', () {
      expect(hotDawg.contains('cromulentx'), isFalse);
      expect(hotDawg.contains('diks'), isFalse);

    });

    test('has expected paths for cat', () {
      // "cat"
      // Paths:
      // c+at
      // ac+t
      // tac

      // Helper to manually traverse the GADDAG
      bool hasPath(String path) {
        var walker = hotDawg.getRootDawgWalker();
        for (var i = 0; i < path.length; i++) {
          var char = path[i];
          if (walker.getChild(char) == null) {
            return false;
          }
          walker = walker.getChild(char)!;
        }
        return walker.isTerminal();
      }

      expect(hasPath('c+at'), isTrue, reason: 'Should contain path c+at');
      expect(hasPath('ac+t'), isTrue, reason: 'Should contain path ac+t');
      expect(hasPath('tac'), isTrue, reason: 'Should contain path tac');

    });
  });
}