import 'dart:convert';
import 'dart:io';

import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/review_checkpoint_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

PhotoAsset photo(String id, {int modified = 1}) => PhotoAsset(
  id: id,
  width: 8,
  height: 12,
  size: 0,
  createDate: DateTime(2026),
  modifiedDate: DateTime(2026, 1, modified),
  type: AssetType.image,
);

void main() {
  late Directory storage;
  ReviewCheckpointService checkpoint({
    int maxEntries = 100000,
    Future<SharedPreferences> Function()? preferences,
  }) => ReviewCheckpointService(
    maxEntries: maxEntries,
    preferences: preferences,
    storageDirectory: () async => storage,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await Directory.systemTemp.createTemp('cleanup-review-test-');
  });
  tearDown(() async => storage.delete(recursive: true));
  test('restores decisions only for accessible unchanged assets', () async {
    final store = checkpoint();
    await store.load('photos', [
      photo('keep'),
      photo('pending'),
      photo('edited'),
      photo('revoked'),
    ]);
    for (final id in ['keep', 'edited', 'revoked']) {
      store.record('photos', photo(id), 'keep');
    }
    store.record('photos', photo('pending'), 'delete');
    await store.flush('photos');
    final restored = await checkpoint().load('photos', [
      photo('keep'),
      photo('pending'),
      photo('edited', modified: 2),
    ]);
    expect(restored, {'keep': 'keep', 'pending': 'delete'});
  });
  test(
    'undo and clearing persist without retaining deletion decisions',
    () async {
      final store = checkpoint();
      await store.load('photos', [photo('a')]);
      store.record('photos', photo('a'), 'delete');
      await store.flush('photos');
      store.record('photos', photo('a'), null);
      await store.flush('photos');
      expect(await checkpoint().load('photos', [photo('a')]), isEmpty);
      store.record('photos', photo('a'), 'keep');
      await store.clear('photos');
      expect(await checkpoint().load('photos', [photo('a')]), isEmpty);
    },
  );
  test(
    'bounded checkpoint keeps newest decisions and filters malformed data',
    () async {
      final store = checkpoint(maxEntries: 2);
      final assets = [photo('a'), photo('b'), photo('c')];
      await store.load('photos', assets);
      for (final asset in assets) {
        store.record('photos', asset, 'keep');
      }
      await store.flush('photos');
      expect(await checkpoint().load('photos', assets), {
        'b': 'keep',
        'c': 'keep',
      });
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        'cleanup.review.v1.unmigrated',
        '["invalid",["a",1,"delete"],["a","bad-version","delete"]]',
      );
      expect(await checkpoint().load('unmigrated', assets), isEmpty);
    },
  );
  test(
    'storage failure is propagated for visible UI feedback and later retry',
    () async {
      var failed = true;
      final store = checkpoint(
        preferences: () async {
          if (failed) throw StateError('unavailable');
          return SharedPreferences.getInstance();
        },
      );
      store.record('photos', photo('a'), 'keep');
      await expectLater(store.flush('photos'), throwsStateError);
      failed = false;
      await store.flush('photos');
      expect(await store.load('photos', [photo('a')]), {'a': 'keep'});
    },
  );

  test('exit before load does not overwrite unread saved decisions', () async {
    final original = checkpoint();
    await original.load('photos', [photo('a')]);
    original.record('photos', photo('a'), 'delete');
    await original.flush('photos');
    await checkpoint().flush('photos');
    expect(await checkpoint().load('photos', [photo('a')]), {'a': 'delete'});
  });

  test('migrates the old preference and never revives a later undo', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'cleanup.review.v1.photos',
      jsonEncode([
        ['a', ReviewCheckpointService.version(photo('a')), 'delete'],
      ]),
    );
    final store = checkpoint();
    expect(await store.load('photos', [photo('a')]), {'a': 'delete'});
    expect(preferences.getString('cleanup.review.v1.photos'), isNull);
    store.record('photos', photo('a'), null);
    await store.flush('photos');
    // A stale preference left behind by an interrupted cleanup must not
    // become authoritative again after the v2 ready marker is durable.
    await preferences.setString(
      'cleanup.review.v1.photos',
      jsonEncode([
        ['a', ReviewCheckpointService.version(photo('a')), 'delete'],
      ]),
    );
    expect(await checkpoint().load('photos', [photo('a')]), isEmpty);
  });

  test('falls back to the previous complete shard after corruption', () async {
    final store = checkpoint();
    await store.load('photos', [photo('a')]);
    store.record('photos', photo('a'), 'keep');
    await store.flush('photos');
    store.record('photos', photo('a'), 'delete');
    await store.flush('photos');
    final files = storage
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList();
    final latest = files.singleWhere((file) {
      final data = jsonDecode(file.readAsStringSync());
      return data['revision'] == 2;
    });
    latest.writeAsStringSync('{"incomplete":');
    final restored = checkpoint();
    expect(await restored.load('photos', [photo('a')]), {'a': 'keep'});
    expect(restored.recoveredFromCorruption('photos'), isTrue);
  });

  test(
    'both damaged shard slots reset safely and allow a fresh review',
    () async {
      final store = checkpoint();
      await store.load('photos', [photo('a')]);
      store.record('photos', photo('a'), 'delete');
      await store.flush('photos');
      store.record('photos', photo('a'), 'keep');
      await store.flush('photos');
      final files = storage
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();
      expect(files, hasLength(2));
      for (final file in files) {
        file.writeAsStringSync('{"incomplete":');
      }
      final recovered = checkpoint();
      expect(await recovered.load('photos', [photo('a')]), isEmpty);
      expect(recovered.recoveredFromCorruption('photos'), isTrue);
      await recovered.clear('photos');
      recovered.record('photos', photo('a'), 'keep');
      await recovered.flush('photos');
      expect(await checkpoint().load('photos', [photo('a')]), {'a': 'keep'});
    },
  );

  test(
    'A to B to A batches retain absent choices without returning them',
    () async {
      final first = checkpoint();
      await first.load('photos', [photo('a'), photo('b')]);
      first.record('photos', photo('a'), 'delete');
      first.record('photos', photo('b'), 'keep');
      await first.flush('photos');
      final second = checkpoint();
      expect(await second.load('photos', [photo('b')]), {'b': 'keep'});
      await second.flush('photos');
      expect(await checkpoint().load('photos', [photo('a')]), {'a': 'delete'});
    },
  );

  test(
    'persists a 42,638-photo review without a giant preference value',
    () async {
      final assets = List.generate(42638, (index) => photo('asset-$index'));
      final store = checkpoint();
      await store.load('photos', assets);
      for (final asset in assets) {
        store.record(
          'photos',
          asset,
          asset.id.endsWith('0') ? 'delete' : 'keep',
        );
      }
      await store.flush('photos');
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('cleanup.review.v1.photos'), isNull);
      final restored = await checkpoint().load('photos', assets);
      expect(restored.length, assets.length);
      expect(restored['asset-42000'], 'delete');
      expect(restored['asset-42637'], 'keep');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
