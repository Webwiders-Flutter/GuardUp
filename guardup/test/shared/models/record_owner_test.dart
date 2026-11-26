import 'package:flutter_test/flutter_test.dart';
import 'package:guardup/core/constants/api/json_keys.dart';
import 'package:guardup/shared/models/record_owner.model.dart';

void main() {
  test('AccountOwner keys rows by user_id', () {
    expect(const AccountOwner('a').column, JsonKeys.userId);
  });

  test('ManagedBodyguardOwner keys rows by bodyguard_id', () {
    expect(const ManagedBodyguardOwner('b').column, JsonKeys.bodyguardId);
  });

  test('owners of different kinds with the same id are not equal', () {
    expect(const AccountOwner('x') == const ManagedBodyguardOwner('x'), isFalse);
    expect(const AccountOwner('x'), const AccountOwner('x'));
  });
}
