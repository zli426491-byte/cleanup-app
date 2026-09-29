import 'dart:async' show unawaited;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:photo_manager/photo_manager.dart'
    show AssetEntity, ThumbnailFormat, ThumbnailOption, ThumbnailSize;
import 'package:provider/provider.dart';

import '../../models/photo_asset.dart' show formatBytes;
import '../../services/photo_scanner_service.dart';
import '../../utils/app_theme.dart';
import '../scanner/asset_preview.dart';
import '../scanner/asset_thumbnail.dart';
import 'cleanup_category.dart';
import 'delete_flow.dart';
import 'ui_kit.dart';

/// Side-by-side comparison of duplicate or similar shots. Every group keeps
/// its best shot; all other members start selected, like the reference app.
class GroupReviewView extends StatefulWidget {
  const GroupReviewView({
    super.key,
    required this.title,
    required this.sections,
  });

  final String title;
  final List<CleanupCategory> sections;

  @override
  State<GroupReviewView> createState() => _GroupReviewViewState();
}

class _GroupReviewViewState extends State<GroupReviewView> {
  final Set<String> _selected = {};

  /// Suggestions start selected, but only photos whose preview decoded for
  /// this exact version can be deleted or toggled.
  final Map<String, PhotoAsset> _ready = {};
  bool _validatingSuggestions = false;
  int _validationRun = 0;
  int _validatedCount = 0;
  int _validationTotal = 0;

  bool _isReady(PhotoAsset asset) => identical(_ready[asset.id], asset);

  void _onPreview(PhotoAsset asset, bool ok) {
    if (!mounted || ok == _isReady(asset)) return;
    setState(() {
      if (ok) {
        _ready[asset.id] = asset;
      } else {
        _ready.remove(asset.id);
      }
    });
  }

  /// Groups already seen, so a later snapshot only preselects new groups and
  /// never re-adds a photo the user chose to keep.
  final Set<String> _knownGroups = {};
  final Set<CleanupCategory> _collapsed = {};
  ScanResult? _syncedWith;

  void _sync(CategoryIndex index) {
    if (identical(_syncedWith, index.result)) return;
    _syncedWith = index.result;
    final run = ++_validationRun;
    final present = <String>{};
    for (final section in widget.sections) {
      for (final group in index[section].groups) {
        present.addAll(group.assets.map((a) => a.id));
        if (_knownGroups.add(group.key)) {
          _selected.addAll(group.others.map((a) => a.id));
        }
        // A changed scan may choose a different best photo. Never carry a
        // prior selection forward into an entire group marked for deletion.
        if (group.assets.every((a) => _selected.contains(a.id))) {
          _selected.remove(group.bestId);
        }
      }
    }
    _selected.retainAll(present);
    final pending = [
      for (final section in widget.sections)
        for (final group in index[section].groups)
          for (final asset in group.assets)
            if (_selected.contains(asset.id) && !_isReady(asset)) asset,
    ];
    _validatingSuggestions = pending.isNotEmpty;
    _validatedCount = 0;
    _validationTotal = pending.length;
    if (pending.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && run == _validationRun) {
          unawaited(_prepareSuggestions(pending, run));
        }
      });
    }
  }

  Future<void> _prepareSuggestions(List<PhotoAsset> assets, int run) async {
    final scanner = context.read<PhotoScannerService>();
    try {
      if (scanner.isContinuousScanning) {
        await scanner.pauseContinuousScan();
      } else if (scanner.isScanning) {
        scanner.cancelScan();
      }
    } catch (_) {
      if (mounted && run == _validationRun) {
        setState(() => _validatingSuggestions = false);
      }
      return;
    }
    if (!mounted || run != _validationRun) return;
    if (scanner.isScanning || !identical(_syncedWith, scanner.scanResult)) {
      // A pause may publish a different version. _sync will queue that
      // version on the next build rather than certifying these old assets.
      if (scanner.isScanning) {
        setState(() => _validatingSuggestions = false);
      }
      return;
    }
    await _verifySuggestions(assets, run);
  }

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

  void _retrySelected(Iterable<ReviewGroup> groups) {
    if (_validatingSuggestions) return;
    final pending = [
      for (final group in groups)
        for (final asset in group.others)
          if (_selected.contains(asset.id) && !_isReady(asset)) asset,
    ];
    if (pending.isEmpty) return;
    final run = ++_validationRun;
    setState(() {
      _validatingSuggestions = true;
      _validatedCount = 0;
      _validationTotal = pending.length;
    });
    unawaited(_prepareSuggestions(pending, run));
  }

  Future<void> _verifySuggestions(List<PhotoAsset> assets, int run) async {
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
      _validatingSuggestions = false;
      _validatedCount = completed;
      _selected.removeWhere(
        (id) =>
            versions.containsKey(id) && !identical(_ready[id], versions[id]),
      );
    });
  }

  @override
  void dispose() {
    _validationRun++;
    super.dispose();
  }

  void _setOthersSelected(Iterable<ReviewGroup> groups, bool selected) {
    for (final group in groups) {
      final others = group.others.map((a) => a.id);
      if (selected) {
        _selected.remove(group.bestId);
        _selected.addAll(others);
      } else {
        _selected.removeAll(others);
      }
    }
  }

  void _togglePhoto(ReviewGroup group, PhotoAsset asset) {
    if (_selected.contains(asset.id)) {
      setState(() => _selected.remove(asset.id));
      return;
    }
    // The user can choose a different keeper, but cannot select the final
    // unselected photo and accidentally delete the whole comparison group.
    if (group.assets.every(
      (member) => member.id == asset.id || _selected.contains(member.id),
    )) {
      return;
    }
    setState(() => _selected.add(asset.id));
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
    final index = CategoryIndex.of(result);
    _sync(index);

    final all = [
      for (final section in widget.sections) ...index[section].assets,
    ];
    final selectedAssets = [
      for (final a in all)
        if (_selected.contains(a.id) && _isReady(a)) a,
    ];
    final selectedBytes = sumBytes(selectedAssets);
    final multi = widget.sections.length > 1;
    final allOthers = {
      for (final section in widget.sections)
        for (final g in index[section].groups)
          for (final a in g.others) a.id,
    };
    final allSelected =
        allOthers.isNotEmpty && _selected.containsAll(allOthers);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageTopBar(
              title: multi
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: AppTheme.heading3),
                        Text(
                          '${l10n.v2PhotoCount(all.length)} • '
                          '${l10n.v2SelectedCount(selectedAssets.length)}',
                          style: AppTheme.small,
                        ),
                      ],
                    )
                  : null,
              trailing: [
                if (allOthers.isNotEmpty)
                  HeaderPill(
                    key: const ValueKey('group-select-all'),
                    icon: Icons.check_circle_outline_rounded,
                    label: allSelected ? l10n.v2DeselectAll : l10n.v2SelectAll,
                    onPressed: () {
                      final groups = [
                        for (final section in widget.sections)
                          ...index[section].groups,
                      ];
                      setState(() => _setOthersSelected(groups, !allSelected));
                      if (!allSelected) _retrySelected(groups);
                    },
                  ),
              ],
            ),
            Expanded(
              child: all.isEmpty
                  ? _EmptyGroups(sections: widget.sections)
                  : CustomScrollView(
                      slivers: [
                        if (!multi)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: AppTheme.largeTitle,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      l10n.v2PhotoCount(all.length),
                                      if (sumBytes(all) > 0)
                                        formatBytes(sumBytes(all)),
                                    ].join(' • '),
                                    style: AppTheme.caption,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        for (final section in widget.sections)
                          ..._sectionSlivers(index[section], multi: multi),
                        const SliverToBoxAdapter(child: SizedBox(height: 120)),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _validatingSuggestions
          ? BottomAction(
              child: BigButton(
                label:
                    '${l10n.v2SelectAll} • '
                    '${l10n.v2PhotoCount(_validatedCount)} / '
                    '${l10n.v2PhotoCount(_validationTotal)}',
                loading: true,
                onPressed: null,
              ),
            )
          : selectedAssets.isEmpty
          ? null
          : BottomAction(
              child: BigButton(
                key: const ValueKey('group-delete'),
                icon: Icons.delete_outline_rounded,
                loading: deleting,
                label: selectedBytes > 0
                    ? l10n.v2DeleteSize(formatBytes(selectedBytes))
                    : l10n.v2DeleteCount(selectedAssets.length),
                onPressed: () => _delete(selectedAssets),
              ),
            ),
    );
  }

  List<Widget> _sectionSlivers(CategoryContent content, {required bool multi}) {
    final l10n = context.l10n;
    final groups = content.groups;
    final collapsed = _collapsed.contains(content.category);
    final others = {
      for (final g in groups)
        for (final a in g.others) a.id,
    };
    final sectionSelected = others.isNotEmpty && _selected.containsAll(others);
    return [
      if (multi)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          sliver: SliverToBoxAdapter(
            child: InkWell(
              key: ValueKey('group-section-${content.category.id}'),
              onTap: groups.isEmpty
                  ? null
                  : () => setState(() {
                      if (!_collapsed.remove(content.category)) {
                        _collapsed.add(content.category);
                      }
                    }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        content.category.title(context),
                        style: AppTheme.heading3.copyWith(
                          color: groups.isEmpty
                              ? AppTheme.textMuted
                              : AppTheme.textTitle,
                        ),
                      ),
                    ),
                    if (groups.isNotEmpty)
                      Flexible(
                        child: TextButton(
                          onPressed: () {
                            setState(
                              () =>
                                  _setOthersSelected(groups, !sectionSelected),
                            );
                            if (!sectionSelected) _retrySelected(groups);
                          },
                          child: Text(
                            sectionSelected
                                ? l10n.v2DeselectAll
                                : l10n.v2SelectAll,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: Text(
                          l10n.v2PhotoCount(0),
                          style: AppTheme.small,
                        ),
                      ),
                    Icon(
                      collapsed
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                      color: groups.isEmpty
                          ? AppTheme.textMuted
                          : AppTheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      if (!collapsed && groups.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverList.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _groupCard(
                groups[index],
                groupLabel:
                    '${content.category.title(context)} '
                    '${MaterialLocalizations.of(context).formatDecimal(index + 1)}',
              ),
            ),
          ),
        ),
    ];
  }

  Widget _groupCard(ReviewGroup group, {required String groupLabel}) {
    final l10n = context.l10n;
    final others = group.others.map((a) => a.id).toSet();
    final groupSelected = others.isNotEmpty && _selected.containsAll(others);
    return TintCard(
      key: ValueKey('group-card-${group.key}'),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.v2PhotoCount(group.assets.length),
                  style: AppTheme.heading3.copyWith(fontSize: 15),
                ),
              ),
              Flexible(
                child: TextButton(
                  onPressed: () {
                    setState(() => _setOthersSelected([group], !groupSelected));
                    if (!groupSelected) _retrySelected([group]);
                  },
                  child: Text(
                    groupSelected ? l10n.v2DeselectAll : l10n.v2SelectAll,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              ),
            ],
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.9,
            children: [
              for (var index = 0; index < group.assets.length; index++)
                _groupTile(
                  group,
                  group.assets[index],
                  index,
                  groupLabel: groupLabel,
                  isBest: group.assets[index].id == group.bestId,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _groupTile(
    ReviewGroup group,
    PhotoAsset asset,
    int index, {
    required String groupLabel,
    required bool isBest,
  }) {
    final ready = _isReady(asset);
    final selected = ready && _selected.contains(asset.id);
    return Semantics(
      key: ValueKey('group-tile-${asset.id}'),
      button: true,
      selected: selected,
      label: [
        groupLabel,
        context.l10n.v2PhotoCount(index + 1),
        context.l10n.v2PhotoCount(group.assets.length),
        if (isBest) context.l10n.v2Best,
        MaterialLocalizations.of(context).formatMediumDate(asset.createDate),
        if (asset.sizeKnown) formatBytes(asset.size),
      ].join(', '),
      child: GestureDetector(
        onTap: ready ? () => _togglePhoto(group, asset) : null,
        onLongPress: () => showAssetPreview(context, asset),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.r16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: Colors.white,
                child: AssetThumbnail(
                  asset: asset,
                  previewSize: 320,
                  onPreviewReady: (ok) => _onPreview(asset, ok),
                ),
              ),
              if (isBest)
                PositionedDirectional(
                  start: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.l10n.v2Best,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (asset.sizeKnown)
                PositionedDirectional(
                  start: 8,
                  bottom: 8,
                  child: InfoPill(text: formatBytes(asset.size)),
                ),
              if (ready)
                PositionedDirectional(
                  end: 8,
                  top: 8,
                  child: DeleteMark(selected: selected),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _deleteInProgress = false;

  Future<void> _delete(List<PhotoAsset> assets) async {
    if (_deleteInProgress) return;
    _deleteInProgress = true;
    try {
      final index = CategoryIndex.of(
        context.read<PhotoScannerService>().scanResult,
      );
      final requestedIds = assets.map((a) => a.id).toSet();
      for (final section in widget.sections) {
        for (final group in index[section].groups) {
          if (group.assets.every((a) => requestedIds.contains(a.id))) {
            requestedIds.remove(group.bestId);
          }
        }
      }
      final deleted = await DeleteFlow.run(
        context,
        [
          for (final asset in assets)
            if (requestedIds.contains(asset.id)) asset,
        ],
        source: widget.sections.length > 1
            ? 'optimize_storage'
            : 'category_${widget.sections.single.id}',
      );
      if (!mounted || deleted.isEmpty) return;
      setState(() => _selected.removeAll(deleted));
    } finally {
      _deleteInProgress = false;
    }
  }
}

class _EmptyGroups extends StatelessWidget {
  const _EmptyGroups({required this.sections});
  final List<CleanupCategory> sections;

  @override
  Widget build(BuildContext context) {
    final checking = context.select<PhotoScannerService, bool>(
      (s) => s.isScanning,
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
                : Icon(
                    sections.first.icon,
                    size: 56,
                    color: AppTheme.primaryMuted,
                  ),
          ),
          const SizedBox(height: 20),
          Text(
            checking
                ? context.l10n.v2CheckingDuplicates
                : context.l10n.v2EmptyCategory,
            textAlign: TextAlign.center,
            style: AppTheme.heading2,
          ),
          if (!checking) ...[
            const SizedBox(height: 6),
            Text(
              context.l10n.v2EmptyCategoryBody,
              textAlign: TextAlign.center,
              style: AppTheme.caption,
            ),
          ],
        ],
      ),
    );
  }
}
