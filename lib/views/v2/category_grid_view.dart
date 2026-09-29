import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:photo_manager/photo_manager.dart' show AssetType;
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

  /// Only items whose preview decoded (for this exact version) can be
  /// selected, so nothing unseen is ever sent to deletion.
  final Map<String, PhotoAsset> _ready = {};
  bool _selecting = false;

  bool _isReady(PhotoAsset asset) => identical(_ready[asset.id], asset);

  void _onPreview(PhotoAsset asset, bool ok) {
    if (!mounted || ok == _isReady(asset)) return;
    setState(() {
      if (ok) {
        _ready[asset.id] = asset;
      } else {
        _ready.remove(asset.id);
        _selected.remove(asset.id);
      }
    });
  }
  late GridSort _sort = widget.category == CleanupCategory.other
      ? GridSort.newest
      : GridSort.largest;
  ScanResult? _sortedFor;
  GridSort? _sortedBy;
  List<PhotoAsset> _sorted = const [];

  List<PhotoAsset> _assets(ScanResult result) {
    if (identical(_sortedFor, result) && _sortedBy == _sort) return _sorted;
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
    final readyIds = [
      for (final a in assets)
        if (_isReady(a)) a.id,
    ];
    final allSelected =
        readyIds.isNotEmpty && selectedAssets.length == readyIds.length;

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
                      onPressed: () => setState(() {
                        if (allSelected) {
                          _selected.clear();
                        } else {
                          _selected.addAll(readyIds);
                        }
                      }),
                    )
                  : null,
              trailing: [
                if (assets.isNotEmpty)
                  HeaderPill(
                    key: const ValueKey('grid-select-toggle'),
                    label: _selecting ? l10n.v2Cancel : l10n.v2Select,
                    onPressed: () => setState(() {
                      _selecting = !_selecting;
                      if (!_selecting) _selected.clear();
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
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
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
      bottomNavigationBar: selectedAssets.isEmpty
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
      label: asset.sizeKnown ? formatBytes(asset.size) : null,
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
  Widget build(BuildContext context) => Padding(
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
          child: Icon(category.icon, size: 56, color: AppTheme.primaryMuted),
        ),
        const SizedBox(height: 20),
        Text(context.l10n.v2EmptyCategory, style: AppTheme.heading2),
        const SizedBox(height: 6),
        Text(
          context.l10n.v2EmptyCategoryBody,
          textAlign: TextAlign.center,
          style: AppTheme.caption,
        ),
      ],
    ),
  );
}
