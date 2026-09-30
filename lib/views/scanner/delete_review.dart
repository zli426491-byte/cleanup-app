import 'package:cleanup_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import '../../services/photo_scanner_service.dart';
import 'asset_preview.dart';
import 'asset_thumbnail.dart';
import 'photo_asset_labels.dart';

Future<List<PhotoAsset>?> showDeleteReview(
  BuildContext context, {
  required List<PhotoAsset> assets,
  List<Set<String>> reviewGroups = const [],
  Set<String> previewReadyIds = const {},
}) => showDialog<List<PhotoAsset>>(
  context: context,
  barrierDismissible: false,
  builder: (_) => DeleteReview(
    assets: assets,
    reviewGroups: reviewGroups,
    previewedIds: previewReadyIds,
  ),
);

class DeleteReview extends StatefulWidget {
  const DeleteReview({
    super.key,
    required this.assets,
    this.reviewGroups = const [],
    this.previewedIds = const {},
  });
  final List<PhotoAsset> assets;
  final List<Set<String>> reviewGroups;
  final Set<String> previewedIds;
  @override
  State<DeleteReview> createState() => _DeleteReviewState();
}

class _DeleteReviewState extends State<DeleteReview> {
  late final List<PhotoAsset> _selected = List.of(widget.assets);
  late final Set<String> _ready = Set.of(widget.previewedIds);
  bool _confirming = false;
  Future<void> _confirm() async {
    if (_confirming) return;
    setState(() => _confirming = true);
    try {
      final assets = _selected.where((a) => _ready.contains(a.id)).toList();
      if (assets.isEmpty) return;
      final ids = assets.map((a) => a.id).toSet();
      if (widget.reviewGroups.any((g) => g.length > 1 && ids.containsAll(g))) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            scrollable: true,
            content: Text(context.l10n.reviewAllVersions),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.scanCancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.l10n.reviewDeleteAllVersions),
              ),
            ],
          ),
        );
        if (!mounted || confirmed != true) return;
      }
      if (!mounted ||
          assets.any(
            (asset) => !_ready.contains(asset.id) || !_selected.contains(asset),
          )) {
        return;
      }
      Navigator.pop(context, assets);
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _selected.where((a) => _ready.contains(a.id)).length;
    return AlertDialog(
      scrollable: true,
      title: Text(context.l10n.reviewDeleteTitle),
      content: SizedBox(
        width: 720,
        height: MediaQuery.sizeOf(context).height * 0.55,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Text(
                context.l10n.scanConfirmDeleteDescription(_selected.length),
              ),
            ),
            if (ready < _selected.length)
              SliverToBoxAdapter(
                child: Text(
                  context.l10n.reviewUnseenCount(_selected.length - ready),
                ),
              ),
            SliverList.builder(
              itemCount: _selected.length,
              itemBuilder: (context, index) {
                final asset = _selected[index];
                return ListTile(
                  key: ValueKey('review-${asset.id}'),
                  leading: SizedBox(
                    width: 48,
                    height: 48,
                    child: AssetThumbnail(
                      asset: asset,
                      onPreviewReady: (ready) {
                        if (!mounted) return;
                        final changed = ready
                            ? _ready.add(asset.id)
                            : _ready.remove(asset.id);
                        if (changed) setState(() {});
                      },
                    ),
                  ),
                  title: Text(
                    '${MaterialLocalizations.of(context).formatShortDate(asset.createDate)} · ${assetSizeLabel(asset, context: context)}',
                  ),
                  subtitle: !_ready.contains(asset.id)
                      ? Text(
                          context.l10n.reviewUnavailable,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  onTap: () => showAssetPreview(context, asset),
                  trailing: IconButton(
                    tooltip: context.l10n.reviewRemove,
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => setState(() => _selected.removeAt(index)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.scanCancel),
        ),
        FilledButton(
          onPressed: ready == 0 || _confirming ? null : _confirm,
          child: Text(context.l10n.reviewConfirmCount(ready)),
        ),
      ],
    );
  }
}
