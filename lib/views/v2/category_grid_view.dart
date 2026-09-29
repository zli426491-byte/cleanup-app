import 'dart:async' show unawaited;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:photo_manager/photo_manager.dart'
    show
        AssetEntity,
        AssetType,
        ThumbnailFormat,
        ThumbnailOption,
        ThumbnailSize;
import 'package:provider/provider.dart';

import '../../models/photo_asset.dart' show formatBytes;
import '../../services/photo_scanner_service.dart';
import '../../utils/app_theme.dart';
import '../scanner/asset_thumbnail.dart';
import '../scanner/swipe_clean_view.dart';
import 'cleanup_category.dart';
import 'delete_flow.dart';
import 'optimize_view.dart';
import 'ui_kit.dart';

enum GridSort { largest, newest }

/// Flat category: large title, 2-column grid with size badges, Select mode
/// and a pinned "Delete N" action. Tapping a photo starts swipe review there.
class CategoryGridView extends StatefulWidget {
  const CategoryGridView({super.key, required this.category});
  final CleanupCategory category;

  @override
  State<CategoryGridView> createState() => _CategoryGridViewState();
}

class _CategoryGridViewState extends State<CategoryGridView> {
  final Set<String> _selected = {};

  /// Selection may include pending offscreen items, but only items whose
  /// preview decoded for this exact version are sent to deletion.
  final Map<String, PhotoAsset> _ready = {};
  bool _selecting = false;
  bool _preparingAll = false;
  bool _validatingAll = false;
  int _validationRun = 0;
  int _validatedCount = 0;

  bool _isReady(PhotoAsset asset) => identical(_ready[asset.id], asset);

  void _onPreview(PhotoAsset asset, bool ok) {
    if (!mounted || ok == _isReady(asset)) return;
    setState(() {
      if (ok) {
        _ready[asset.id] = asset;
      } else {
        _ready.remove(asset.id);
        if (!_validatingAll) _selected.remove(asset.id);
      }
    });
  }

  /// Verify offscreen previews in a bounded queue before a bulk deletion can
  /// proceed. A select-all action must cover the category, not just its first
  /// rendered screen, while still rejecting undecodable photos.
  Future<bool> _verifyPreview(PhotoAsset asset) async {
    try {
      var bytes = asset.thumbnail;
      if (bytes == null) {
        final entity = await AssetEntity.fromId(
          asset.id,
        ).timeout(const Duration(seconds: 30));
        if (entity == null) return false;
        bytes = await entity
            .thumbnailDataWithOption(
              ThumbnailOption.ios(
                size: const ThumbnailSize(320, 320),
                format: ThumbnailFormat.jpeg,
              ),
            )
            .timeout(const Duration(seconds: 30));
      }
      if (bytes == null) return false;
      final codec = await ui
          .instantiateImageCodec(bytes)
          .timeout(const Duration(seconds: 30));
      try {
        final frame = await codec.getNextFrame().timeout(
          const Duration(seconds: 30),
        );
        frame.image.dispose();
        return true;
      } finally {
        codec.dispose();
      }
    } catch (_) {
      return false;
    }
  }

  Future<void> _toggleAll(List<PhotoAsset> assets) async {
    if (_preparingAll) return;
    final ids = {for (final asset in assets) asset.id};
    final run = ++_validationRun;
    if (_selected.containsAll(ids)) {
      setState(() {
        _selected.clear();
        _validatingAll = false;
        _validatedCount = 0;
      });
      return;
    }
    setState(() => _preparingAll = true);
    final scanner = context.read<PhotoScannerService>();
    try {
      if (scanner.isContinuousScanning) {
        await scanner.pauseContinuousScan();
      } else if (scanner.isScanning) {
        scanner.cancelScan();
      }
    } catch (_) {
      if (mounted && run == _validationRun) {
        setState(() => _preparingAll = false);
      }
      return;
    }
    if (!mounted || run != _validationRun) return;
    if (scanner.isScanning) {
      setState(() => _preparingAll = false);
      return;
    }
    // Pausing can publish a newer scan result, so use the resulting snapshot.
    final current = _assets(scanner.scanResult);
    setState(() {
      _preparingAll = false;
      _selected.addAll(current.map((a) => a.id));
      _validatingAll = true;
      _validatedCount = 0;
    });
    unawaited(_verifyAll(current, run));
  }

  Future<void> _verifyAll(List<PhotoAsset> assets, int run) async {
    var next = 0;
    var completed = 0;
    Future<void> worker() async {
      while (mounted && run == _validationRun) {
        final index = next++;
        if (index >= assets.length) return;
        final asset = assets[index];
        final ready = _isReady(asset) || await _verifyPreview(asset);
        if (!mounted || run != _validationRun) return;
        if (ready) _ready[asset.id] = asset;
        completed++;
        if (completed % 32 == 0 || completed == assets.length) {
          setState(() => _validatedCount = completed);
        }
      }
    }

    await Future.wait(List.generate(4, (_) => worker()));
    if (!mounted || run != _validationRun) return;
    final versions = {for (final asset in assets) asset.id: asset};
    setState(() {
      _validatingAll = false;
      _validatedCount = completed;
      _selected.removeWhere((id) => !identical(_ready[id], versions[id]));
    });
  }

  @override
  void dispose() {
    _validationRun++;
    super.dispose();
  }

  late GridSort _sort = widget.category == CleanupCategory.other
      ? GridSort.newest
      : GridSort.largest;
  ScanResult? _sortedFor;
  GridSort? _sortedBy;
  List<PhotoAsset> _sorted = const [];

  List<PhotoAsset> _assets(ScanResult result) {
    if (identical(_sortedFor, result) && _sortedBy == _sort) return _sorted;
    final changedSnapshot = !identical(_sortedFor, result);
    final list = List.of(CategoryIndex.of(result)[widget.category].assets);
    switch (_sort) {
      case GridSort.largest:
        list.sort((a, b) => b.size.compareTo(a.size));
      case GridSort.newest:
        list.sort((a, b) => b.createDate.compareTo(a.createDate));
    }
    _sortedFor = result;
    _sortedBy = _sort;
    // Selection only refers to items that still exist in this snapshot.
    final ids = {for (final a in list) a.id};
    _selected.retainAll(ids);
    if (changedSnapshot) {
      if (_validatingAll) {
        // The original batch has not finished validation. Its progress and
        // selection cannot authorize deletion from a newer scan snapshot.
        _validationRun++;
        _validatingAll = false;
        _validatedCount = 0;
        _selected.clear();
      } else {
        final versions = {for (final asset in list) asset.id: asset};
        _selected.removeWhere((id) => !identical(_ready[id], versions[id]));
      }
    }
    return _sorted = list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = context.select<PhotoScannerService, ScanResult>(
      (s) => s.scanResult,
    );
    final deleting = context.select<PhotoScannerService, bool>(
      (s) => s.isDeleting,
    );
    final assets = _assets(result);
    final total = sumBytes(assets);
    final selectedAssets = [
      for (final a in assets)
        if (_selected.contains(a.id) && _isReady(a)) a,
    ];
    final allSelected =
        assets.isNotEmpty && assets.every((a) => _selected.contains(a.id));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageTopBar(
              leading: _selecting
                  ? HeaderPill(
                      key: const ValueKey('grid-select-all'),
                      icon: Icons.check_circle_outline_rounded,
                      label: allSelected
                          ? l10n.v2DeselectAll
                          : l10n.v2SelectAll,
                      onPressed: () => unawaited(_toggleAll(assets)),
                    )
                  : null,
              trailing: [
                if (assets.isNotEmpty)
                  HeaderPill(
                    key: const ValueKey('grid-select-toggle'),
                    label: _selecting ? l10n.v2Cancel : l10n.v2Select,
                    onPressed: () => setState(() {
                      _selecting = !_selecting;
                      if (!_selecting) {
                        _validationRun++;
                        _preparingAll = false;
                        _validatingAll = false;
                        _selected.clear();
                      }
                    }),
                  ),
              ],
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.category.title(context),
                                  style: AppTheme.largeTitle,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  total > 0
                                      ? formatBytes(total)
                                      : widget.category.countLabel(
                                          context,
                                          assets.length,
                                        ),
                                  style: AppTheme.caption,
                                ),
                              ],
                            ),
                          ),
                          if (assets.length > 1)
                            Flexible(
                              child: Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: HeaderPill(
                                  key: const ValueKey('grid-sort'),
                                  icon: Icons.sort_rounded,
                                  label: _sort == GridSort.largest
                                      ? l10n.v2SortLargest
                                      : l10n.v2SortNewest,
                                  onPressed: () => setState(
                                    () => _sort = _sort == GridSort.largest
                                        ? GridSort.newest
                                        : GridSort.largest,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.category.isVideo && assets.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverToBoxAdapter(
                        child: TintCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VideoCompressListView(),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.video_settings_rounded,
                                color: AppTheme.textTitle,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.v2VideoCompress,
                                      style: AppTheme.heading3,
                                    ),
                                    Text(
                                      l10n.v2VideoCompressSubtitle,
                                      style: AppTheme.small,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (assets.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyCategory(category: widget.category),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      sliver: SliverGrid(
                        // Two columns on phones, more on iPad so thumbnails
                        // stay a comparable size.
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.82,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _tile(assets, index, deleting: deleting),
                          childCount: assets.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _preparingAll || _validatingAll
          ? BottomAction(
              child: BigButton(
                label: _preparingAll
                    ? l10n.v2SelectAll
                    : '${l10n.v2SelectAll} • '
                          '${widget.category.countLabel(context, _validatedCount)} / '
                          '${widget.category.countLabel(context, assets.length)}',
                loading: true,
                onPressed: null,
              ),
            )
          : selectedAssets.isEmpty
          ? null
          : BottomAction(
              child: BigButton(
                key: const ValueKey('grid-delete'),
                icon: Icons.delete_outline_rounded,
                loading: deleting,
                label: widget.category.isVideo
                    ? l10n.v2DeleteVideos(selectedAssets.length)
                    : l10n.v2DeleteCount(selectedAssets.length),
                onPressed: () => _delete(selectedAssets),
              ),
            ),
    );
  }

  Widget _tile(List<PhotoAsset> assets, int index, {required bool deleting}) {
    final asset = assets[index];
    final ready = _isReady(asset);
    final selected = ready && _selected.contains(asset.id);
    return Semantics(
      key: ValueKey('grid-tile-${asset.id}'),
      button: true,
      selected: _selecting ? selected : null,
      label: [
        widget.category.countLabel(context, index + 1),
        widget.category.countLabel(context, assets.length),
        MaterialLocalizations.of(context).formatMediumDate(asset.createDate),
        if (asset.sizeKnown) formatBytes(asset.size),
      ].join(', '),
      child: GestureDetector(
        onTap: deleting
            ? null
            : _selecting
            ? (ready
                  ? () => setState(() {
                      if (!_selected.remove(asset.id)) _selected.add(asset.id);
                    })
                  : null)
            : () => _openSwipe(assets, index),
        onLongPress: deleting || _selecting || !ready
            ? null
            : () => setState(() {
                _selecting = true;
                _selected.add(asset.id);
              }),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.r16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: AppTheme.primaryLight,
                child: AssetThumbnail(
                  asset: asset,
                  previewSize: 320,
                  onPreviewReady: (ok) => _onPreview(asset, ok),
                ),
              ),
              if (asset.type == AssetType.video)
                const Positioned(
                  top: 10,
                  right: 10,
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 26,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black38)],
                  ),
                ),
              if (asset.sizeKnown)
                PositionedDirectional(
                  start: 10,
                  bottom: 10,
                  child: InfoPill(text: formatBytes(asset.size)),
                ),
              if (_selecting && ready)
                PositionedDirectional(
                  end: 10,
                  bottom: 12,
                  child: DeleteMark(selected: selected),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSwipe(List<PhotoAsset> assets, int index) async {
    // Start at the tapped photo, then continue through the rest.
    final ordered = [...assets.sublist(index), ...assets.sublist(0, index)];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SwipeCleanView(
          assets: ordered,
          title: widget.category.title(context),
          categoryId: widget.category.id,
        ),
      ),
    );
  }

  bool _deleteInProgress = false;

  Future<void> _delete(List<PhotoAsset> assets) async {
    if (_deleteInProgress) return;
    _deleteInProgress = true;
    try {
      final deleted = await DeleteFlow.run(
        context,
        assets,
        source: 'category_${widget.category.id}',
      );
      if (!mounted || deleted.isEmpty) return;
      setState(() {
        _selected.removeAll(deleted);
        if (_selected.isEmpty) _selecting = false;
      });
    } finally {
      _deleteInProgress = false;
    }
  }
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory({required this.category});
  final CleanupCategory category;

  @override
  Widget build(BuildContext context) {
    // Never call a category clean while the scan can still add to it.
    final checking = context.select<PhotoScannerService, bool>(
      resultsStillComing,
    );
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(28),
            ),
            child: checking
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Icon(category.icon, size: 56, color: AppTheme.primaryMuted),
          ),
          const SizedBox(height: 20),
          Text(
            checking
                ? context.l10n.v2StillChecking
                : context.l10n.v2EmptyCategory,
            textAlign: TextAlign.center,
            style: AppTheme.heading2,
          ),
          const SizedBox(height: 6),
          Text(
            checking
                ? context.l10n.v2StillCheckingBody
                : context.l10n.v2EmptyCategoryBody,
            textAlign: TextAlign.center,
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }
}
