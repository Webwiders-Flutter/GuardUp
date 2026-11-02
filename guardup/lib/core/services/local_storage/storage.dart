abstract class LocalStorage {
  Future<T?> read<T>(String key);
  Future<void> write<T>({required String key, required T value});
  Future<void> delete(String key);
  Future<void> deleteAll();
}
