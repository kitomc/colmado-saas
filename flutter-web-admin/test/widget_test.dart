import 'package:flutter_test/flutter_test.dart';

import 'package:colmaria_web_admin/shared/utils/formatters.dart';

void main() {
  test('formatRD formats correctly', () {
    expect(formatRD(1000), 'RD\$ 1,000.00');
    expect(formatRD(0), 'RD\$ 0.00');
    expect(formatRD(99.99), 'RD\$ 99.99');
    expect(formatRD(1234567.89), 'RD\$ 1,234,567.89');
  });
}
