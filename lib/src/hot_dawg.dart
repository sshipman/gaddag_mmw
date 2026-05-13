import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'dawg.dart';
import 'dawg_walker.dart';

class HotDawg implements Dawg {
  final Int32List data;
  late final int rootAddress;

  HotDawg(this.data) {
    this.rootAddress = data[0];
  }

  factory HotDawg.fromZlibData(Uint8List compressedData) {
    Uint8List unzippedContent = ZLibDecoder().decodeBytes(compressedData);
    Int32List d = unzippedContent.buffer.asInt32List();
    return HotDawg(d);
  }

  DawgWalker getRootDawgWalker() {
    return HotDawgWalker(this, rootAddress);
  }

  /// Standard GADDAG traversal to find a child node
  int? getChild(int currentAddress, int charCode) {
    int header = data[currentAddress];
    int edgeCount = header & 0x7FFFFFFF; // Mask out terminal bit

    if (edgeCount == 0) return null;

    // Binary search through the edge pairs
    // Edges start at currentAddr + 1, each edge is 2 integers (char, addr)
    int low = 0;
    int high = edgeCount - 1;

    while (low <= high) {
      int mid = (low + high) >> 1;
      int edgeIndex = currentAddress + 1 + (mid * 2);
      int edgeChar = data[edgeIndex];

      if (edgeChar < charCode) {
        low = mid + 1;
      } else if (edgeChar > charCode) {
        high = mid - 1;
      } else {
        return data[edgeIndex + 1]; // Found the character, return target address
      }
    }
    return null;
  }

  bool isTerminal(int address) {
    // Check the highest bit
    return (data[address] & 0x80000000) != 0;
  }

  bool contains(String word) {
    // To verify a full word, we follow the path of its completely reversed
    // prefix (which is just the reversed word).
    DawgWalker? walker = getRootDawgWalker();
    List<String> letters = word.split('').reversed.toList();
    for (String letter in letters) {
      walker = walker?.getChild(letter);
      if (walker == null) {
        return false;
      }
    }
    return walker?.isTerminal() ?? false;
  }
}

class HotDawgWalker implements DawgWalker {
  final HotDawg dawg;
  int currentAddress;

  HotDawgWalker(this.dawg, this.currentAddress);
  
  @override
  HotDawgWalker? getChild(String letter) {
    int letterCode = letter.codeUnitAt(0);
    int? childAddress = dawg.getChild(currentAddress, letterCode);
    return childAddress != null ? HotDawgWalker(dawg, childAddress) : null;
  }

  @override
  bool isTerminal() {
    return dawg.isTerminal(currentAddress);
  }
}