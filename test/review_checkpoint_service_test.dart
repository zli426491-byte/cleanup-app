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
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('restores decisions only for accessible unchanged assets', () async {
    final store = ReviewCheckpointService();
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
    final restored = await ReviewCheckpointService().load('photos', [
      photo('keep'),
      photo('pending'),
      photo('edited', modified: 2),
    ]);
    expect(restored, {'keep': 'keep', 'pending': 'delete'});
  });
  test(
    'undo and clearing persist without retaining deletion decisions',
    () async {
      final store = ReviewCheckpointService();
      await store.load('photos', [photo('a')]);
      store.record('photos', photo('a'), 'delete');
      await store.flush('photos');
      store.record('photos', photo('a'), null);
      await store.flush('photos');
      expect(
        await ReviewCheckpointService().load('photos', [photo('a')]),
        isEmpty,
      );
      store.record('photos', photo('a'), 'keep');
      await store.clear('photos');
      expect(
        await ReviewCheckpointService().load('photos', [photo('a')]),
        isEmpty,
      );
    },
  );
  test(
    'bounded checkpoint keeps newest decisions and filters malformed data',
    () async {
      final store = ReviewCheckpointService(maxEntries: 2);
      final assets = [photo('a'), photo('b'), photo('c')];
      await store.load('photos', assets);
      for (final asset in assets) {
        store.record('photos', asset, 'keep');
      }
      await store.flush('photos');
      expect(await ReviewCheckpointService().load('photos', assets), {
        'b': 'keep',
        'c': 'keep',
      });
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        'cleanup.review.v1.photos',
        '["invalid",["a",1,"delete"],["a","bad-version","delete"]]',
      );
      expect(await ReviewCheckpointService().load('photos', assets), isEmpty);
    },
  );
  test(
    'storage failure is propagated for visible UI feedback and later retry',
    () async {
      var failed = true;
      final store = ReviewCheckpointService(
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
    final original = ReviewCheckpointService();
    await original.load('photos', [photo('a')]);
    original.record('photos', photo('a'), 'delete');
    await original.flush('photos');
    await ReviewCheckpointService().flush('photos');
    expect(await ReviewCheckpointService().load('photos', [photo('a')]), {
      'a': 'delete',
    });
  });
}
