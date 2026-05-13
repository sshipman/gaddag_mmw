import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:args/args.dart';

import '../gaddag_mmw.dart';

void main(List<String> args) async {
  ArgParser parser = ArgParser();
  parser.addOption('in', abbr: 'i');
  parser.addOption('out', abbr: 'o', defaultsTo: 'dictionary.hotdawg');
  ArgResults results = parser.parse(args);

  // get wordlist from file
  String? inFileName = results.option('in');
  if (inFileName == null) {
    print("provide an input wordlist file with --in");
    return;
  }
  File inFile = File(inFileName);
  // construct a minimized gaddag with it.
  List<String> words = await inFile.readAsString().then((allwords) => allwords.split('\n'));
  Gaddag gaddag = Gaddag();
  for (String word in words){
    gaddag.addWord(word);
  }
  gaddag.minimize();
  // bake it to output file.
  Int32List bakedData = bake(gaddag);
  String outFileName = results.option('out')!;
  File outFile = File(outFileName);
  Uint8List bytes = bakedData.buffer.asUint8List();
  ZLibEncoder encoder = ZLibEncoder();
  Uint8List outBytes = encoder.encodeBytes(bytes);
  await outFile.writeAsBytes(outBytes);
}

// bake the completed, minimized GADDAG to a flat list of ints.
Int32List bake(Gaddag gaddag) {
  List<GaddagNode> allNodes = _getAllNodesInPostOrder(gaddag.root); // Use your DFS
  Map<GaddagNode, int> nodeToAddress = {};
  List<int> flatData = [0];

  for (var node in allNodes) {
    nodeToAddress[node] = flatData.length;

    // 1. Encode Header: isTerminal (1 bit) + edge count (31 bits)
    int edgeCount = node.edges?.length ?? 0;
    int header = (node.terminal ? 1 << 31 : 0) | edgeCount;
    flatData.add(header);

    // 2. Encode Edges
    final edges = node.edges;
    if (edges != null && edges.isNotEmpty) {
      final sortedChars = edges.keys.toList()..sort();
      for (final char in sortedChars) {
        final child = edges[char]!;
        flatData.add(char);               // The edge character
        flatData.add(nodeToAddress[child]!); // The pre-calculated child address
      }
    }
  }
  //write root address in first int
  flatData[0] = nodeToAddress[gaddag.root]!;
  return Int32List.fromList(flatData);
}

List<GaddagNode> _getAllNodesInPostOrder(GaddagNode root) {
  final List<GaddagNode> postOrderList = [];
  final Set<GaddagNode> visited = Set<GaddagNode>.identity();
  final List<GaddagNode> stack = [root];

  // We use a secondary set to track nodes whose children are currently being visited
  final Set<GaddagNode> childrenProcessed = Set<GaddagNode>.identity();

  while (stack.isNotEmpty) {
    final node = stack.last;

    // If we've already added this node to our final list, pop and move on
    if (visited.contains(node)) {
      stack.removeLast();
      continue;
    }

    final edges = node.edges;
    if (edges == null || edges.isEmpty || childrenProcessed.contains(node)) {
      // If no children exist, or we've already pushed all children to the stack,
      // this is the "Post" part of the order.
      postOrderList.add(node);
      visited.add(node);
      stack.removeLast();
    } else {
      // Mark that we are now processing this node's children
      childrenProcessed.add(node);

      // Push children onto the stack.
      // Note: The order of edges doesn't technically matter for post-order,
      // but keeping them consistent helps with debugging.
      for (final child in edges.values) {
        if (!visited.contains(child)) {
          stack.add(child);
        }
      }
    }
  }

  return postOrderList;
}
