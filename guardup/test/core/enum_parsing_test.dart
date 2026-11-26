import 'package:flutter_test/flutter_test.dart';
import 'package:guardup/core/utils/json_converters/enum.jsonconverter.dart';
import 'package:guardup/features/auth/data/enum/user_status.enum.dart';
import 'package:guardup/features/body_guard/data/enum/week_day.enum.dart';
import 'package:guardup/features/body_guard/data/model/user_availability.model.dart';

void main() {
  group('WeekDay', () {
    test('parses the lowercase DB value and legacy uppercase', () {
      expect(WeekDay.values.fromValue('monday'), WeekDay.monday);
      expect(WeekDay.values.fromValue('MONDAY'), WeekDay.monday);
      expect(WeekDay.values.fromValue('Sunday'), WeekDay.sunday);
      expect(WeekDay.values.fromValue('funday'), isNull);
    });

    test('apiValue is lowercase', () {
      for (final day in WeekDay.values) {
        expect(day.apiValue, day.apiValue.toLowerCase());
      }
    });

    test('availability row round-trips day_of_week in lowercase', () {
      final model = UserAvailabilityModel.fromJson({
        'id': '1',
        'day_of_week': 'TUESDAY',
        'is_available': true,
      });
      expect(model.dayOfWeek, WeekDay.tuesday);
      expect(model.toJson()['day_of_week'], 'tuesday');
    });

    test('fromDateTime maps ISO weekday', () {
      expect(WeekDay.fromDateTime(DateTime(2026, 11, 23)), WeekDay.monday);
      expect(WeekDay.fromDateTime(DateTime(2026, 11, 29)), WeekDay.sunday);
    });
  });

  group('UserStatus', () {
    test('unknown or missing values fall back to the stated default', () {
      expect(
        UserStatus.values.parse(null, defaultValue: UserStatus.incomplete),
        UserStatus.incomplete,
      );
      expect(
        UserStatus.values.parse('NOPE', defaultValue: UserStatus.incomplete),
        UserStatus.incomplete,
      );
      expect(UserStatus.values.fromValue(null), isNull);
    });

    test('parses every DB value', () {
      for (final s in UserStatus.values) {
        expect(UserStatus.values.fromValue(s.apiValue), s);
      }
      expect(UserStatus.values.fromValue('pending_approval'), UserStatus.pendingApproval);
    });
  });
}
