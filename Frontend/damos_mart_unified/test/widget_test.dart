import 'package:flutter_test/flutter_test.dart';
import 'package:disc_core/disc_variant.dart';

void main() {
  test('DiscVariant fromStored resolves known values', () {
    expect(DiscVariant.fromStored('influence'), DiscVariant.influence);
    expect(DiscVariant.fromStored('dominance'), DiscVariant.dominance);
    expect(DiscVariant.fromStored(null), isNull);
  });
}
