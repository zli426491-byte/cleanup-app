import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:photo_manager/photo_manager.dart' show AssetType;

import '../../services/photo_scanner_service.dart';

/// Home categories, in the order they appear on the home screen.
enum CleanupCategory {
  similars,
  duplicates,
  videos,
  screenshots,
  blurred,
  largeFiles,
  other;

  /// Stable identifier kept compatible with the swipe checkpoint store.
  String get id => switch (this) {
    similars => 'similar',
    duplicates => 'duplicates',
    videos => 'videos',
    screenshots => 'screenshots',
    blurred => 'blurred',
    largeFiles => 'largeFiles',
    other => 'other',
  };

  /// Grouped categories compare photos side by side and keep a best shot.
  bool get isGrouped => this == similars || this == duplicates;

  bool get isVideo => this == videos;

  IconData get icon => switch (this) {
    similars => Icons.burst_mode_rounded,
    duplicates => Icons.copy_all_rounded,
    videos => Icons.play_circle_fill_rounded,
    screenshots => Icons.stay_current_portrait_rounded,
    blurred => Icons.blur_on_rounded,
    largeFiles => Icons.sd_card_rounded,
    other => Icons.photo_rounded,
  };

  String title(BuildContext context) => switch (this) {
    similars => context.l10n.v2CatSimilars,
    duplicates => context.l10n.v2CatDuplicates,
    videos => context.l10n.v2CatVideos,
    screenshots => context.l10n.v2CatScreenshots,
    blurred => context.l10n.v2CatBlurred,
    largeFiles => context.l10n.v2CatLarge,
    other => context.l10n.v2CatOther,
  };

  String introBody(BuildContext context) => switch (this) {
    similars => context.l10n.v2IntroSimilars,
    duplicates => context.l10n.v2IntroDuplicates,
    videos => context.l10n.v2IntroVideos,
    screenshots => context.l10n.v2IntroScreenshots,
    blurred => context.l10n.v2IntroBlurred,
    largeFiles => context.l10n.v2IntroLarge,
    other => context.l10n.v2IntroOther,
  };

  /// "3 Photos" / "3 Videos" for a count in this category.
  String countLabel(BuildContext context, int count) => isVideo
      ? context.l10n.v2VideoCount(count)
      : context.l10n.v2PhotoCount(count);
}

/// A comparison group: the best shot is kept, the rest are suggested.
class ReviewGroup {
  const ReviewGroup({
    required this.key,
    required this.assets,
    required this.bestId,
  });

  final String key;
  final List<PhotoAsset> assets;
  final String bestId;

  Iterable<PhotoAsset> get others => assets.where((a) => a.id != bestId);
}

/// What one category currently contains, derived from a scan snapshot.
class CategoryContent {
  const CategoryContent({
    required this.category,
    required this.assets,
    this.groups = const [],
  });

  final CleanupCategory category;

  /// Every asset in the category (group members flattened for grouped ones).
  final List<PhotoAsset> assets;
  final List<ReviewGroup> groups;

  int get count => assets.length;
  bool get isEmpty => assets.isEmpty;

  /// Bytes of assets whose size has been measured.
  int get bytes => sumBytes(assets);

  PhotoAsset? get cover => groups.isNotEmpty
      ? groups.first.assets.first
      : assets.isEmpty
      ? null
      : assets.first;
}

int sumBytes(Iterable<PhotoAsset> assets) => assets.fold<int>(
  0,
  (sum, asset) => asset.sizeKnown ? sum + asset.size : sum,
);

/// Derives category contents from one immutable [ScanResult]. Results are
/// memoized per snapshot so a rebuild does not re-walk a large library.
class CategoryIndex {
  CategoryIndex._(this.result);

  static CategoryIndex? _last;

  factory CategoryIndex.of(ScanResult result) {
    final last = _last;
    if (last != null && identical(last.result, result)) return last;
    return _last = CategoryIndex._(result);
  }

  final ScanResult result;
  final Map<CleanupCategory, CategoryContent> _cache = {};

  CategoryContent operator [](CleanupCategory category) =>
      _cache.putIfAbsent(category, () => _build(category));

  CategoryContent _build(CleanupCategory category) {
    switch (category) {
      case CleanupCategory.duplicates:
        final groups = [
          for (final group in result.duplicateGroups)
            if (group.assets.length > 1)
              ReviewGroup(
                key: 'duplicate:${group.hash}',
                assets: group.assets,
                bestId: group.bestAssetId ?? group.assets.first.id,
              ),
        ];
        return CategoryContent(
          category: category,
          groups: groups,
          assets: [for (final g in groups) ...g.assets],
        );
      case CleanupCategory.similars:
        // A photo already shown as an exact duplicate is not repeated here.
        final exact = {
          for (final g in result.duplicateGroups)
            for (final a in g.assets) a.id,
        };
        final groups = <ReviewGroup>[];
        for (final group in result.similarGroups) {
          final members = group.assets
              .where((a) => !exact.contains(a.id))
              .toList();
          if (members.length < 2) continue;
          final best = members.any((a) => a.id == group.bestAssetId)
              ? group.bestAssetId!
              : members.first.id;
          groups.add(
            ReviewGroup(
              key: 'similar:${members.map((a) => a.id).join(',')}',
              assets: members,
              bestId: best,
            ),
          );
        }
        return CategoryContent(
          category: category,
          groups: groups,
          assets: [for (final g in groups) ...g.assets],
        );
      case CleanupCategory.videos:
        return CategoryContent(category: category, assets: result.videos);
      case CleanupCategory.screenshots:
        return CategoryContent(category: category, assets: result.screenshots);
      case CleanupCategory.blurred:
        return CategoryContent(
          category: category,
          assets: [
            for (final a in result.blurryPhotos)
              if (!a.isScreenshot) a,
          ],
        );
      case CleanupCategory.largeFiles:
        return CategoryContent(category: category, assets: result.largeFiles);
      case CleanupCategory.other:
        final claimed = <String>{
          for (final c in const [
            CleanupCategory.duplicates,
            CleanupCategory.similars,
            CleanupCategory.screenshots,
            CleanupCategory.blurred,
          ])
            for (final a in this[c].assets) a.id,
        };
        return CategoryContent(
          category: category,
          assets: [
            for (final a in result.allAssets)
              if (a.type == AssetType.image &&
                  !a.isScreenshot &&
                  !claimed.contains(a.id))
                a,
          ],
        );
    }
  }

  /// Suggested cleanup: every non-best group member plus screenshots and
  /// blurred shots, counted once. This is what "Space to Clean" totals.
  List<PhotoAsset> get suggested {
    final seen = <String>{};
    final out = <PhotoAsset>[];
    void add(PhotoAsset a) {
      if (seen.add(a.id)) out.add(a);
    }

    for (final c in const [
      CleanupCategory.duplicates,
      CleanupCategory.similars,
    ]) {
      for (final g in this[c].groups) {
        g.others.forEach(add);
      }
    }
    this[CleanupCategory.screenshots].assets.forEach(add);
    this[CleanupCategory.blurred].assets.forEach(add);
    return out;
  }
}

enum PendingResults { none, running, paused }

/// Whether unfinished scan work can still add results to [category], and
/// whether that work is running now or waits for Continue on Home.
PendingResults pendingResults(
  PhotoScannerService s,
  CleanupCategory category,
) {
  if (s.scannedAssetCount == 0 && !s.isScanning) return PendingResults.none;
  final total = s.availableAssetCount;
  final indexing = total == null || s.scannedAssetCount < total;
  final previews =
      s.pendingAnalysisCount > 0 &&
      s.attemptedAnalysisCount < s.totalPhotoCount;
  final originals = s.nativeOriginalAnalysisAvailable;
  final coming = switch (category) {
    // Metadata only: complete once everything is indexed.
    CleanupCategory.screenshots || CleanupCategory.videos => indexing,
    // Preview analysis.
    CleanupCategory.similars ||
    CleanupCategory.blurred ||
    CleanupCategory.other => indexing || previews,
    // Originals: exact copies and verified sizes.
    CleanupCategory.duplicates =>
      indexing || previews || (originals && s.pendingHashAssetCount > 0),
    CleanupCategory.largeFiles =>
      indexing || (originals && s.pendingSizeAssetCount > 0),
  };
  if (!coming) return PendingResults.none;
  return s.isScanning ? PendingResults.running : PendingResults.paused;
}
