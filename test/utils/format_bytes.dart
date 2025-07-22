import 'package:didcomm/src/common/helpers.dart';
import 'package:parameterized_test/parameterized_test.dart';
import 'package:test/test.dart';

void main() {
  parameterizedTest(
    'formatBytes',
    [
      [1, '1B'],
      [20, '20B'],
      [300, '300B'],
      [4000, '3.91KB'],
      [4096, '4KB'],
      [500500, '488.77KB'],
      [60000345, '57.22MB'],
      [700876578634, '652.74GB'],
      [80000000455555, '72.76TB'],
      [90087643753463646, '80.01PB'],
      [1000000000000000000, '888.18PB'],
    ],
    (int bytes, String formatted) {
      final result = formatBytes(bytes);
      expect(result, formatted);
    },
  );
}
