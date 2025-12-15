import 'package:gaddag_mmw/gaddag_mmw.dart';

void main() {
  GADDAG gaddag = GADDAG();
  gaddag.addWord('cat');
  print(gaddag.contains('cat'));
}
