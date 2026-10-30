import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';

import '../app_router.dart';

extension DateTimeExtensions on DateTime {
  // Common formatters
  String get ddmmyyyy => DateFormat('dd/MM/yyyy').format(toLocal());
  String get ddMmmyyyy => DateFormat(
    'dd MMM yyyy',
    AppRouter.rootNavigatorKey.currentContext!.isArabic ? 'ar' : 'en',
  ).format(toLocal());

  String get yyyymmdd => DateFormat('yyyy-MM-dd').format(toLocal());
  String get verboseDate => DateFormat('MMM dd, yyyy').format(toLocal());
  String get verboseDateTime12h =>
      DateFormat('MMM dd, hh:mm a').format(toLocal());
  String verboseDateLocalized(BuildContext context) {
    if (context.isArabic) {
      return DateFormat('dd MMMM yyyy', 'ar').format(toLocal());
    }
    return DateFormat('MMM dd, yyyy').format(toLocal());
  }

  String get time12h => DateFormat('hh:mm a').format(toLocal());
  String get time24h => DateFormat('HH:mm').format(toLocal());
  String get memberSince => DateFormat(
    'MMM yyyy',
    AppRouter.rootNavigatorKey.currentContext!.isArabic ? 'ar' : 'en',
  ).format(toLocal());

  // Checks
  bool get isToday {
    final now = DateTime.now();
    final local = toLocal();
    return now.day == local.day &&
        now.month == local.month &&
        now.year == local.year;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return yesterday.day == day &&
        yesterday.month == month &&
        yesterday.year == year;
  }

  // Relative time (basic)
  // Relative time (basic)
  String timeAgo(BuildContext context) {
    final localSelf = toLocal();
    final diff = DateTime.now().difference(localSelf);
    if (diff.isNegative || diff.inSeconds < 30) {
      return context.l10n.timeAgoJustNow;
    }
    if (diff.inDays > 7) return verboseDateLocalized(context);
    if (diff.inDays > 0) return context.l10n.timeAgoDays(diff.inDays);
    if (diff.inHours > 0) return context.l10n.timeAgoHours(diff.inHours);
    if (diff.inMinutes > 0) return context.l10n.timeAgoMinutes(diff.inMinutes);
    return context.l10n.timeAgoJustNow;
  }

  /// Converts DateTime to UTC and serializes to ISO 8601 string for server upload
  String toUtcIsoString() => toUtc().toIso8601String();
}

extension NullableDateTimeExtensions on DateTime? {
  /// Converts nullable DateTime to UTC and serializes to ISO 8601 string, or null
  String? toNullableUtcIsoString() => this?.toUtc().toIso8601String();
}

DateTime _parseIsoAsUtcToLocal(String raw) {
  String str = raw.trim();
  if (str.isEmpty) return DateTime.now();
  if (str.contains(' ') && !str.contains('T')) {
    str = str.replaceFirst(' ', 'T');
  }
  if (!str.endsWith('Z') && !RegExp(r'[+-]\d{2}(:?\d{2})?$').hasMatch(str)) {
    str = '${str}Z';
  }
  final parsed = DateTime.tryParse(str) ?? DateTime.tryParse(raw);
  return (parsed ?? DateTime.now()).toLocal();
}

DateTime? _tryParseIsoAsUtcToLocal(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  String str = raw.trim();
  if (str.contains(' ') && !str.contains('T')) {
    str = str.replaceFirst(' ', 'T');
  }
  if (!str.endsWith('Z') && !RegExp(r'[+-]\d{2}(:?\d{2})?$').hasMatch(str)) {
    str = '${str}Z';
  }
  final parsed = DateTime.tryParse(str) ?? DateTime.tryParse(raw);
  return parsed?.toLocal();
}

extension StringDateTimeExtensions on String {
  /// Parses String as ISO 8601 DateTime and converts it to local time
  DateTime parseLocal() => _parseIsoAsUtcToLocal(this);

  /// Tries to parse String as ISO 8601 DateTime and converts to local time, or returns fallback
  DateTime? tryParseLocal() => _tryParseIsoAsUtcToLocal(this);
}

extension NullableStringDateTimeExtensions on String? {
  /// Parses nullable String as ISO 8601 DateTime and converts to local time
  DateTime? parseNullableLocal() => _tryParseIsoAsUtcToLocal(this);
}
