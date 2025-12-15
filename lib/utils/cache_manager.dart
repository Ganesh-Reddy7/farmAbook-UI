import 'package:hive/hive.dart';

class AppCacheManager {
  static final Box _box = Hive.box("farmAbook_cache");

  static void deleteKey(String key) {
    if (_box.containsKey(key)) _box.delete(key);
  }

  static void clearTractorCache(int farmerId) {
    final keysToDelete = _box.keys
        .where((key) => key.toString().startsWith("tractor_${farmerId}_"))
        .toList();

    for (final key in keysToDelete) {
      _box.delete(key);
    }
  }
  static void clearAll() => _box.clear();
}
