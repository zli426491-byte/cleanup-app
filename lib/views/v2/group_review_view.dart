import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';
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
    final present = <String>{};
    for (final section in widget.sections) {
      for (final group in index[section].groups) {
        present.addAll(group.assets.map((a) => a.id));
        if (_knownGroups.add(group.key)) {
          _selected.addAll(group.others.map((a) => a.id));
        }
      }
    }
    _selected.retainAll(present);
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
                    onPressed: () => setState(() {
                      if (allSelected) {
                        _selected.removeAll(allOthers);
                      } else {
                        _selected.addAll(allOthers);
                      }
                    }),
                  ),
              ],
            ),
            Expanded(
              child: all.isEmpty
                  ? _EmptyGroups(sections: widget.sections)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                      children: [
                        if (!multi) ...[
                          Text(widget.title, style: AppTheme.largeTitle),
                          const SizedBox(height: 4),
                          Text(
                            [
                              l10n.v2PhotoCount(all.length),
                              if (sumBytes(all) > 0) formatBytes(sumBytes(all)),
                            ].join(' • '),
                            style: AppTheme.caption,
                          ),
                          const SizedBox(height: 16),
                        ],
                        for (final section in widget.sections)
                          ..._section(index[section], multi: multi),
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

  List<Widget> _section(CategoryContent content, {required bool multi}) {
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
        InkWell(
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
                      onPressed: () => setState(() {
                        if (sectionSelected) {
                          _selected.removeAll(others);
                        } else {
                          _selected.addAll(others);
                        }
                      }),
                      child: Text(
                        sectionSelected ? l10n.v2DeselectAll : l10n.v2SelectAll,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: Text(l10n.v2PhotoCount(0), style: AppTheme.small),
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
      if (multi) const Divider(),
      if (!collapsed)
        for (final group in groups) ...[
          const SizedBox(height: 12),
          _groupCard(group),
        ],
      if (multi) const SizedBox(height: 8),
    ];
  }

  Widget _groupCard(ReviewGroup group) {
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
                  onPressed: () => setState(() {
                    if (groupSelected) {
                      _selected.removeAll(others);
                    } else {
                      _selected.addAll(others);
                    }
                  }),
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
              for (final asset in group.assets)
                _groupTile(asset, isBest: asset.id == group.bestId),
            ],
          ),
        ],
      ),
    );
  }

  Widget _groupTile(PhotoAsset asset, {required bool isBest}) {
    final ready = _isReady(asset);
    final selected = ready && _selected.contains(asset.id);
    return Semantics(
      key: ValueKey('group-tile-${asset.id}'),
      button: true,
      selected: selected,
      label: [
        if (isBest) context.l10n.v2Best,
        if (asset.sizeKnown) formatBytes(asset.size),
      ].join(', '),
      child: GestureDetector(
        onTap: ready
            ? () => setState(() {
                if (!_selected.remove(asset.id)) _selected.add(asset.id);
              })
            : null,
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
      final deleted = await DeleteFlow.run(
        context,
        assets,
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
