import '/features/body_guard/data/enum/bodyguard_availability_status.enum.dart';
import '/features/body_guard/data/model/user_availability.model.dart';

/// Helper and extension methods for evaluating bodyguard availability schedules
/// and dynamic operational statuses.
abstract final class BodyguardAvailabilityHelper {
  /// Converts a formatted time string (e.g. "09:00 AM", "05:00 PM") into minutes from midnight.
  static int? parseTimeToMinutes(String timeStr) {
    final clean = timeStr.trim().toUpperCase();
    if (clean.isEmpty) return null;

    final isPm = clean.endsWith('PM');
    final isAm = clean.endsWith('AM');
    final rawTime = clean.replaceAll('AM', '').replaceAll('PM', '').trim();
    final parts = rawTime.split(':');
    if (parts.isEmpty) return null;

    int? hours = int.tryParse(parts[0]);
    final minutes = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    if (hours == null) return null;

    if (isPm && hours < 12) {
      hours += 12;
    } else if (isAm && hours == 12) {
      hours = 0;
    }

    return hours * 60 + minutes;
  }
}

/// Domain extensions on [UserAvailabilityModel] for schedule evaluation.
extension UserAvailabilityModelX on UserAvailabilityModel {
  /// Checks whether this availability window covers the specified [dateTime].
  bool isAvailableAt(DateTime dateTime) {
    if (!isAvailable || dayOfWeek == null) return false;
    if (dateTime.weekday != dayOfWeek!.weekdayNumber) return false;

    final fromMinutes = BodyguardAvailabilityHelper.parseTimeToMinutes(fromTime);
    final toMinutes = BodyguardAvailabilityHelper.parseTimeToMinutes(toTime);
    if (fromMinutes == null || toMinutes == null) return false;

    final currentMinutes = dateTime.hour * 60 + dateTime.minute;
    if (fromMinutes <= toMinutes) {
      return currentMinutes >= fromMinutes && currentMinutes <= toMinutes;
    } else {
      // Overnight working shift spanning midnight
      return currentMinutes >= fromMinutes || currentMinutes <= toMinutes;
    }
  }

  /// Dynamic operational status for this specific day slot.
  BodyguardAvailabilityStatus get currentStatus {
    if (dayOfWeek == null) return BodyguardAvailabilityStatus.notSet;
    if (!isAvailable) return BodyguardAvailabilityStatus.notAvailable;
    return isAvailableAt(DateTime.now())
        ? BodyguardAvailabilityStatus.available
        : BodyguardAvailabilityStatus.notAvailable;
  }
}

/// Domain extensions on availability collections.
extension UserAvailabilityListX on Iterable<UserAvailabilityModel>? {
  /// Evaluates the dynamic operational availability status across all slots.
  BodyguardAvailabilityStatus evaluateAvailabilityStatus({DateTime? at}) {
    final slots = this;
    if (slots == null || slots.isEmpty) {
      return BodyguardAvailabilityStatus.notSet;
    }

    final target = at ?? DateTime.now();
    final currentDayNumber = target.weekday;

    final todaySlot = slots.cast<UserAvailabilityModel?>().firstWhere(
      (slot) => slot?.dayOfWeek?.weekdayNumber == currentDayNumber,
      orElse: () => null,
    );

    if (todaySlot == null) {
      return BodyguardAvailabilityStatus.notSet;
    }

    if (!todaySlot.isAvailable) {
      return BodyguardAvailabilityStatus.notAvailable;
    }

    return todaySlot.isAvailableAt(target)
        ? BodyguardAvailabilityStatus.available
        : BodyguardAvailabilityStatus.notAvailable;
  }
}
