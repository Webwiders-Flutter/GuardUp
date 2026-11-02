import 'package:shared_preferences/shared_preferences.dart';

import '/core/error/api_exception.dart';
import '/core/services/local_storage/storage.dart';

final class PrefsStorageService implements LocalStorage {
  PrefsStorageService._();

  static final PrefsStorageService _instance = PrefsStorageService._();
  static PrefsStorageService get instance => _instance;

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  @override
  Future<void> write<T>({required String key, required T value}) async {
    try {
      final prefs = await _prefs;

      switch (T) {
        case String:
          await prefs.setString(key, value as String);
          break;

        case int:
          await prefs.setInt(key, value as int);
          break;

        case double:
          await prefs.setDouble(key, value as double);
          break;

        case bool:
          await prefs.setBool(key, value as bool);
          break;

        default:
          throw ApiException(
            'Unsupported type: $T',
            raw: Exception(),
            stackTrace: StackTrace.current,
            type: ApiErrorType.unknown,
          );
      }
    } catch (e) {
      throw ApiException(
        'Prefs write failed',
        raw: e,
        stackTrace: StackTrace.current,
        type: ApiErrorType.unknown,
      );
    }
  }

  @override
  Future<T?> read<T>(String key) async {
    try {
      final prefs = await _prefs;
      switch (T) {
        case String:
          return prefs.getString(key) as T?;
        case int:
          return prefs.getInt(key) as T?;
        case double:
          return prefs.getDouble(key) as T?;
        case bool:
          return prefs.getBool(key) as T?;
        default:
          throw ApiException(
            'Unsupported type',
            raw: Exception(),
            stackTrace: StackTrace.current,
            type: ApiErrorType.unknown,
          );
      }
    } catch (e) {
      throw ApiException(
        'Prefs read failed',
        raw: e,
        stackTrace: StackTrace.current,
        type: ApiErrorType.unknown,
      );
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      final prefs = await _prefs;
      await prefs.remove(key);
    } catch (e) {
      throw ApiException(
        'Prefs delete failed',
        raw: e,
        stackTrace: StackTrace.current,
        type: ApiErrorType.unknown,
      );
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      final prefs = await _prefs;
      await prefs.clear();
    } catch (e) {
      throw ApiException(
        'Prefs deleteAll failed',
        raw: e,
        stackTrace: StackTrace.current,
        type: ApiErrorType.unknown,
      );
    }
  }
}
