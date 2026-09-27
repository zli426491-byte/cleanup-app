import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'photo_scanner_service.dart';

/// Local review decisions only. Restoring a decision never deletes an asset.
class ReviewCheckpointService {
  ReviewCheckpointService({
    Future<SharedPreferences> Function()? preferences,
    this.maxEntries = 20000,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;
  final Future<SharedPreferences> Function() _preferences;
  final int maxEntries;
  static String version(PhotoAsset asset) =>
      '${(asset.modifiedDate ?? asset.createDate).microsecondsSinceEpoch}:${asset.width}:${asset.height}:${asset.type.index}';
  final Map<String, Map<String, List<String>>> _entries = {};
  Future<void> _writes = Future.value();
  String _key(String category) => 'cleanup.review.v1.$category';

  Future<Map<String, String>> load(
    String category,
    List<PhotoAsset> assets,
  ) async {
    final preferences = await _preferences();
    final stored = preferences.getString(_key(category));
    final entries = <String, List<String>>{};
    if (stored != null) {
      try {
        final data = jsonDecode(stored);
        if (data is List) {
          for (final row in data) {
            if (row is List &&
                row.length == 3 &&
                row.every((v) => v is String) &&
                (row[2] == 'keep' || row[2] == 'delete')) {
              entries[row[0] as String] = [row[1] as String, row[2] as String];
            }
          }
        }
      } catch (_) {
        /* Corrupt local state cannot become a deletion request. */
      }
    }
    final versions = {for (final asset in assets) asset.id: version(asset)};
    entries.removeWhere((id, value) => versions[id] != value[0]);
    while (entries.length > maxEntries) {
      entries.remove(entries.keys.first);
    }
    _entries[category] = entries;
    return {for (final entry in entries.entries) entry.key: entry.value[1]};
  }

  void record(String category, PhotoAsset asset, String? decision) {
    final entries = _entries.putIfAbsent(category, () => {});
    entries.remove(asset.id);
    if (decision != null) entries[asset.id] = [version(asset), decision];
    while (entries.length > maxEntries) {
      entries.remove(entries.keys.first);
    }
  }

  Future<void> clear(String category) async {
    _entries[category] = {};
    await flush(category);
  }

  Future<void> flush(String category) {
    // Leaving during async loading must not replace an unread checkpoint.
    if (!_entries.containsKey(category)) return Future.value();
    final data = jsonEncode([
      for (final entry in (_entries[category] ?? {}).entries)
        [entry.key, ...entry.value],
    ]);
    final next = _writes.catchError((Object _) {}).then((_) async {
      final preferences = await _preferences();
      if (!await preferences.setString(_key(category), data)) {
        throw StateError('review_checkpoint_write_failed');
      }
    });
    _writes = next;
    return next;
  }
}
