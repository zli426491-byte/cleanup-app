import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'photo_scanner_service.dart';

/// Local review decisions only. Restoring a decision never deletes an asset.
///
/// Version 2 keeps small, independently updated shards in app-support storage
/// instead of rewriting an ever-growing SharedPreferences value. Each shard
/// alternates two checked snapshots so an interrupted write leaves the
/// previous complete snapshot available.
class ReviewCheckpointService {
  ReviewCheckpointService({
    Future<SharedPreferences> Function()? preferences,
    Future<Directory> Function()? storageDirectory,
    this.maxEntries = 100000,
  }) : _preferences = preferences ?? SharedPreferences.getInstance,
       _storageDirectory = storageDirectory ?? getApplicationSupportDirectory;

  final Future<SharedPreferences> Function() _preferences;
  final Future<Directory> Function() _storageDirectory;
  final int maxEntries;

  static const _shardCount = 64;
  static String version(PhotoAsset asset) =>
      '${(asset.modifiedDate ?? asset.createDate).microsecondsSinceEpoch}:${asset.width}:${asset.height}:${asset.type.index}';

  final Map<String, Map<String, List<String>>> _entries = {};
  final Map<String, Map<int, Map<String, List<String>>>> _shardEntries = {};
  final Map<String, Map<String, List<String>?>> _pending = {};
  final Map<String, Set<int>> _dirty = {};
  final Map<String, Map<int, int>> _mutations = {};
  final Map<String, Map<int, int>> _revisions = {};
  final Map<String, Future<void>> _initializing = {};
  final Set<String> _recovered = {};
  Future<void> _writes = Future.value();

  /// A damaged snapshot was skipped; no deletion choice is restored from it.
  bool recoveredFromCorruption(String category) =>
      _recovered.contains(category);

  String _legacyKey(String category) => 'cleanup.review.v1.$category';

  int _shard(String id) {
    // FNV-1a distributes photo-manager IDs without a digest per selection.
    var hash = 0x811c9dc5;
    for (final unit in id.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return hash & (_shardCount - 1);
  }

  Future<Directory> _categoryDirectory(String category) async {
    final base = await _storageDirectory();
    final name = sha256.convert(utf8.encode(category)).toString();
    return Directory(
      '${base.path}${Platform.pathSeparator}cleanup-review-v2'
      '${Platform.pathSeparator}$name',
    );
  }

  File _shardFile(Directory directory, int shard, int slot) =>
      File('${directory.path}${Platform.pathSeparator}shard-$shard-$slot.json');

  Map<String, List<String>> _parseRows(Object? raw) {
    final result = <String, List<String>>{};
    if (raw is! List) return result;
    for (final row in raw) {
      if (row is List &&
          row.length == 3 &&
          row.every((value) => value is String) &&
          (row[2] == 'keep' || row[2] == 'delete')) {
        result[row[0] as String] = [row[1] as String, row[2] as String];
      }
    }
    return result;
  }

  Future<_ShardSnapshot?> _readSlot(File file) async {
    if (!await file.exists()) return null;
    try {
      final data = jsonDecode(await file.readAsString());
      if (data is! Map ||
          data['version'] != 2 ||
          data['revision'] is! int ||
          (data['revision'] as int) < 1 ||
          data['rows'] is! List) {
        return null;
      }
      final rows = data['rows'] as List;
      if (data['checksum'] !=
          sha256.convert(utf8.encode(jsonEncode(rows))).toString()) {
        return null;
      }
      final parsed = _parseRows(rows);
      if (parsed.length != rows.length) return null;
      return _ShardSnapshot(data['revision'] as int, parsed);
    } on FormatException {
      return null;
    }
  }

  Future<_ShardSnapshot?> _readShard(Directory directory, int shard) async {
    final first = _shardFile(directory, shard, 0);
    final second = _shardFile(directory, shard, 1);
    final firstExists = await first.exists();
    final secondExists = await second.exists();
    final snapshots = await Future.wait([_readSlot(first), _readSlot(second)]);
    final valid = snapshots.whereType<_ShardSnapshot>().toList();
    if (valid.isEmpty) {
      return firstExists || secondExists
          ? const _ShardSnapshot(0, {}, recovered: true)
          : null;
    }
    valid.sort((a, b) => b.revision.compareTo(a.revision));
    return _ShardSnapshot(
      valid.first.revision,
      valid.first.entries,
      recovered:
          (firstExists && snapshots[0] == null) ||
          (secondExists && snapshots[1] == null),
    );
  }

  Future<void> _initialize(String category) => _initializing.putIfAbsent(
    category,
    () => _initializeCategory(category).catchError((Object error) {
      _initializing.remove(category);
      throw error;
    }),
  );

  Future<void> _initializeCategory(String category) async {
    final directory = await _categoryDirectory(category);
    await directory.create(recursive: true);
    final ready = File('${directory.path}${Platform.pathSeparator}ready.v2');
    final isReady = await ready.exists();
    final preferences = isReady ? null : await _preferences();
    final legacy = preferences?.getString(_legacyKey(category));
    final migrate = !isReady && legacy != null;
    final revisions = <int, int>{};
    final fromDisk = <String, List<String>>{};
    final recoveredShards = <int>{};
    final shards = <int>{};
    await for (final entity in directory.list()) {
      if (entity is! File) continue;
      final filename = entity.uri.pathSegments.last;
      final match = RegExp(r'^shard-(\d+)-[01]\.json$').firstMatch(filename);
      final shard = match == null ? null : int.tryParse(match.group(1)!);
      if (shard != null && shard >= 0 && shard < _shardCount) {
        shards.add(shard);
      }
    }
    final snapshots = await Future.wait([
      for (final shard in shards) _readShard(directory, shard),
    ]);
    final shardList = shards.toList();
    for (var index = 0; index < shardList.length; index++) {
      final shard = shardList[index];
      final snapshot = snapshots[index];
      if (snapshot == null) continue;
      revisions[shard] = snapshot.revision;
      fromDisk.addAll(snapshot.entries);
      if (snapshot.recovered) recoveredShards.add(shard);
    }

    // The marker is written only after every legacy shard is durable. Until
    // then the old preference remains the sole migration authority.
    Map<String, List<String>> entries;
    if (migrate) {
      try {
        entries = _parseRows(jsonDecode(legacy));
      } catch (_) {
        entries = {};
      }
    } else {
      entries = fromDisk;
    }
    _entries[category] = entries;
    final indexed = <int, Map<String, List<String>>>{};
    for (final entry in entries.entries) {
      indexed.putIfAbsent(_shard(entry.key), () => {})[entry.key] = entry.value;
    }
    _shardEntries[category] = indexed;
    _revisions[category] = revisions;
    _dirty[category] = {};
    _mutations[category] = {};
    if (recoveredShards.isNotEmpty && !migrate) _recovered.add(category);

    if (migrate) {
      // Empty shards matter after an interrupted earlier migration: a stale
      // v2 decision cannot reappear after the old preference is removed.
      for (var shard = 0; shard < _shardCount; shard++) {
        _markDirty(category, shard);
      }
      await _writeDirty(category, directory);
      // If a crashed migration left both old slots corrupt, replace the
      // second slot too before declaring the legacy migration complete.
      if (recoveredShards.isNotEmpty) {
        for (final shard in recoveredShards) {
          _markDirty(category, shard);
        }
        await _writeDirty(category, directory);
      }
    } else if (recoveredShards.isNotEmpty) {
      for (final shard in recoveredShards) {
        _markDirty(category, shard);
      }
      await _writeDirty(category, directory);
      // A wholly unreadable shard had no trustworthy previous revision.
      // Write its second slot as well, so the next launch does not mistake
      // the remaining damaged file for a new recovery event.
      for (final shard in recoveredShards) {
        _markDirty(category, shard);
      }
      await _writeDirty(category, directory);
    }
    if (!isReady) {
      final temporary = File('${ready.path}.tmp');
      await temporary.writeAsString('2', flush: true);
      await temporary.rename(ready.path);
    }
    if (migrate) {
      // If cleanup fails, ready.v2 still prevents the stale preference from
      // resurrecting decisions after later undo or reset.
      try {
        await preferences!.remove(_legacyKey(category));
      } catch (_) {}
    }

    final pending = _pending.remove(category);
    if (pending != null) {
      for (final entry in pending.entries) {
        _recordLoaded(category, entry.key, entry.value);
      }
    }
  }

  void _markDirty(String category, int shard) {
    _dirty.putIfAbsent(category, () => {}).add(shard);
    final versions = _mutations.putIfAbsent(category, () => {});
    versions[shard] = (versions[shard] ?? 0) + 1;
  }

  void _recordLoaded(String category, String id, List<String>? value) {
    final entries = _entries[category]!;
    final shard = _shard(id);
    entries.remove(id);
    _shardEntries[category]?[shard]?.remove(id);
    if (value != null) {
      entries[id] = value;
      _shardEntries[category]!.putIfAbsent(shard, () => {})[id] = value;
    }
    _markDirty(category, shard);
    while (entries.length > maxEntries) {
      final oldest = entries.keys.first;
      entries.remove(oldest);
      final oldestShard = _shard(oldest);
      _shardEntries[category]?[oldestShard]?.remove(oldest);
      _markDirty(category, oldestShard);
    }
  }

  Future<Map<String, String>> load(
    String category,
    List<PhotoAsset> assets,
  ) async {
    await _initialize(category);
    final entries = _entries[category]!;
    final versions = {for (final asset in assets) asset.id: version(asset)};
    for (final entry in entries.entries.toList()) {
      // A batch, a limited-library permission change, or a partial scan can
      // temporarily omit an asset. Keep its choice on disk, but never return
      // it to a review until the asset is present with the same version.
      if (versions.containsKey(entry.key) &&
          versions[entry.key] != entry.value[0]) {
        entries.remove(entry.key);
        final shard = _shard(entry.key);
        _shardEntries[category]?[shard]?.remove(entry.key);
        _markDirty(category, shard);
      }
    }
    while (entries.length > maxEntries) {
      final oldest = entries.keys.first;
      entries.remove(oldest);
      final shard = _shard(oldest);
      _shardEntries[category]?[shard]?.remove(oldest);
      _markDirty(category, shard);
    }
    return {
      for (final entry in entries.entries)
        if (versions[entry.key] == entry.value[0]) entry.key: entry.value[1],
    };
  }

  void record(String category, PhotoAsset asset, String? decision) {
    if (decision != null && decision != 'keep' && decision != 'delete') {
      throw ArgumentError.value(decision, 'decision');
    }
    final value = decision == null ? null : [version(asset), decision];
    if (!_entries.containsKey(category)) {
      _pending.putIfAbsent(category, () => {})[asset.id] = value;
      return;
    }
    _recordLoaded(category, asset.id, value);
  }

  Future<void> clear(String category) async {
    await _initialize(category);
    final entries = _entries[category]!;
    for (final shard in _shardEntries[category]!.entries) {
      if (shard.value.isNotEmpty) _markDirty(category, shard.key);
    }
    entries.clear();
    for (final shard in _shardEntries[category]!.values) {
      shard.clear();
    }
    await flush(category);
    _recovered.remove(category);
  }

  Future<void> _writeDirty(String category, Directory directory) async {
    final dirty = _dirty[category]!;
    for (final shard in dirty.toList()) {
      final mutation = _mutations[category]![shard];
      final rows = <List<String>>[
        for (final entry
            in _shardEntries[category]?[shard]?.entries ??
                <MapEntry<String, List<String>>>[])
          [entry.key, ...entry.value],
      ];
      final revision = (_revisions[category]![shard] ?? 0) + 1;
      final target = _shardFile(directory, shard, revision & 1);
      final temporary = File('${target.path}.tmp');
      final content = jsonEncode({
        'version': 2,
        'revision': revision,
        'rows': rows,
        'checksum': sha256.convert(utf8.encode(jsonEncode(rows))).toString(),
      });
      await temporary.writeAsString(content, flush: true);
      // The target is always the older slot. Its counterpart remains intact
      // while it is replaced, including on Windows.
      if (await target.exists()) await target.delete();
      await temporary.rename(target.path);
      _revisions[category]![shard] = revision;
      if (_mutations[category]![shard] == mutation) dirty.remove(shard);
    }
  }

  Future<void> flush(String category) {
    // Leaving during async loading must not replace an unread checkpoint.
    if (!_entries.containsKey(category) && !_pending.containsKey(category)) {
      return Future.value();
    }
    final next = _writes.catchError((Object _) {}).then((_) async {
      await _initialize(category);
      if (_dirty[category]!.isEmpty) return;
      await _writeDirty(category, await _categoryDirectory(category));
    });
    _writes = next;
    return next;
  }
}

class _ShardSnapshot {
  const _ShardSnapshot(this.revision, this.entries, {this.recovered = false});
  final int revision;
  final Map<String, List<String>> entries;
  final bool recovered;
}
