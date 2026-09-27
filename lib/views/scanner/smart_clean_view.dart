import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../../services/photo_scanner_service.dart';
import '../../services/subscription_manager.dart';
import '../../utils/app_theme.dart';
import '../paywall/paywall_view.dart';
import '../components/video_compression_view.dart';
import 'swipe_clean_view.dart';
import 'asset_thumbnail.dart';
import 'asset_preview.dart';
import 'photo_asset_labels.dart';
import 'scan_progress_panel.dart';

class SmartCleanView extends StatefulWidget {
  final String initialCategory;
  const SmartCleanView({super.key, this.initialCategory = 'photos'});

  @override
  State<SmartCleanView> createState() => _SmartCleanViewState();
}

class _SmartCleanViewState extends State<SmartCleanView> {
  int _selectedCategory = 0;
  int _videoSort = 0;
  final _categoryKeys = List.generate(6, (_) => GlobalKey());
  final Set<String> _selectedIds = {};
  final Set<String> _dismissedSuggestions = {};
  final Set<int> _autoVerificationAttempted = {};
  final Set<int> _autoVerificationScheduled = {};
  bool _isDeleting = false;
  String? _focusedAssetId;
  Set<String>? _selectionUndo;
  ScanResult? _cachedResult;
  ScanResult? _selectionSource;
  final Map<int, List<PhotoAsset>> _cachedAssets = {};

  List<String> get _categories => [
    context.l10n.scanCategoryPhotos,
    context.l10n.scanCategoryExact,
    context.l10n.scanCategorySimilar,
    context.l10n.scanCategoryScreenshots,
    context.l10n.scanCategoryVideos,
    context.l10n.scanCategoryLarge,
  ];
  static const _categoryIds = [
    'photos',
    'duplicates',
    'similar',
    'screenshots',
    'videos',
    'largeFiles',
  ];

  @override
  void initState() {
    super.initState();
    final category = switch (widget.initialCategory) {
      'review' => 'similar',
      'highResolution' => 'largeFiles',
      _ => widget.initialCategory,
    };
    final index = _categoryIds.indexOf(category);
    _selectedCategory = index < 0 ? 0 : index;
    _revealSelectedCategory();
  }

  void _updateSnapshot(PhotoScannerService scanner) {
    final result = scanner.scanResult;
    if (!identical(_cachedResult, result)) {
      _cachedResult = result;
      _cachedAssets.clear();
    }
    if (!scanner.isScanning && !identical(_selectionSource, result)) {
      _selectionSource = result;
      if (_selectedIds.isEmpty) return;
      _selectedIds.retainAll(result.allAssets.map((asset) => asset.id).toSet());
    }
  }

  OriginalVerificationTarget get _verificationTarget => _selectedCategory == 1
      ? OriginalVerificationTarget.exactPhotos
      : _selectedCategory == 5
      ? OriginalVerificationTarget.fileSizes
      : OriginalVerificationTarget.all;

  bool _shouldAutoVerify(PhotoScannerService scanner) {
    if (!_isResourceCategory ||
        _autoVerificationAttempted.contains(_selectedCategory) ||
        !scanner.nativeOriginalAnalysisAvailable ||
        scanner.isScanning ||
        scanner.isDeleting ||
        _isDeleting) {
      return false;
    }
    // Preserve existing comparisons/selections. Continuing a partial category
    // with results is an explicit action because verification re-indexes access.
    if (_selectedCategory == 1 &&
            scanner.scanResult.duplicateGroups.isNotEmpty ||
        _selectedCategory == 5 && scanner.scanResult.largeFiles.isNotEmpty) {
      return false;
    }
    final indexComplete =
        scanner.availableAssetCount != null &&
        scanner.scannedAssetCount >= scanner.availableAssetCount!;
    if (indexComplete && _pendingChecks(scanner) == 0) {
      return false;
    }
    return !(scanner.hasCompletedScan && scanner.availableAssetCount == 0);
  }

  void _scheduleCategoryVerification(PhotoScannerService scanner) {
    if (_isResourceCategory &&
        (_selectedCategory == 1 &&
                scanner.scanResult.duplicateGroups.isNotEmpty ||
            _selectedCategory == 5 &&
                scanner.scanResult.largeFiles.isNotEmpty)) {
      // This entry already offers results. Later deletion or another scan must
      // not turn a passive rebuild into an unexpected automatic re-index.
      _autoVerificationAttempted.add(_selectedCategory);
      return;
    }
    if (!_shouldAutoVerify(scanner)) return;
    final category = _selectedCategory;
    if (!_autoVerificationScheduled.add(category)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoVerificationScheduled.remove(category);
      if (!mounted ||
          category != _selectedCategory ||
          !identical(scanner, context.read<PhotoScannerService>()) ||
          !_shouldAutoVerify(scanner)) {
        return;
      }
      // Record before starting: timeout/cancel/unavailable completion cannot
      // automatically retry the same category and erase partial results.
      _autoVerificationAttempted.add(category);
      unawaited(scanner.verifyOriginals(target: _verificationTarget));
    });
  }

  @override
  Widget build(BuildContext context) {
    context.select<PhotoScannerService, Object>(
      (scanner) => (scanner.scanResult, scanner.isScanning, scanner.isDeleting),
    );
    final scanner = context.read<PhotoScannerService>();
    _updateSnapshot(scanner);
    _scheduleCategoryVerification(scanner);
    final sub = context.watch<SubscriptionManager>();

    return PopScope(
      canPop: !_isDeleting,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.scanSmartTitle),
          actions: [
            if (scanner.isScanning)
              IconButton(
                tooltip: context.l10n.scanCancelKeepProgress,
                icon: const Icon(Icons.stop_circle_outlined),
                onPressed: scanner.cancelScan,
              ),
          ],
        ),
        body: Column(
          children: [
            _categoryBar(scanner),
            if (_selectedCategory == 4 && scanner.scanResult.videos.isNotEmpty)
              _videoSortBar(),
            const Divider(height: 16),
            Expanded(
              child: scanner.scanResult.allAssets.isEmpty
                  ? scanner.isScanning
                        ? _scanningState(scanner)
                        : _emptyState(scanner)
                  : _content(scanner),
            ),
            if (scanner.scanResult.allAssets.isNotEmpty &&
                _selectedIds.isNotEmpty &&
                !scanner.isScanning)
              _bottomBar(scanner, sub),
          ],
        ),
      ),
    );
  }

  Widget _categoryBar(PhotoScannerService scanner) {
    return SizedBox(
      height: 44 + (MediaQuery.textScalerOf(context).scale(12) - 12) * 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(_categories.length, (index) {
            final selected = _selectedCategory == index;
            final count = _countFor(index, scanner);
            final pending = index == 1
                ? scanner.pendingHashAssetCount
                : index == 5
                ? scanner.pendingSizeAssetCount
                : 0;

            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: Semantics(
                selected: selected,
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () {
                    if (_selectedCategory == index) return;
                    setState(() {
                      _selectedCategory = index;
                      _selectedIds.clear();
                      _selectionUndo = null;
                    });
                    _revealSelectedCategory();
                  },
                  child: Container(
                    key: _categoryKeys[index],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      border: selected
                          ? null
                          : Border.all(
                              color: Colors.grey.withValues(alpha: 0.15),
                            ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _categories[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                        ),
                        if (count == 0 && pending > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.scanNotChecked,
                            style: TextStyle(
                              fontSize: 10,
                              color: selected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                        if (count > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Colors.white
                                    : AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _revealSelectedCategory() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chipContext = _categoryKeys[_selectedCategory].currentContext;
      if (chipContext != null) {
        Scrollable.ensureVisible(chipContext, alignment: 0.5);
      }
    });
  }

  Widget _videoSortBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _sortChip(context.l10n.scanSortFileSize, 0),
          const SizedBox(width: 6),
          _sortChip(context.l10n.scanSortNewest, 1),
        ],
      ),
    );
  }

  Widget _sortChip(String label, int index) {
    final selected = _videoSort == index;
    return GestureDetector(
      onTap: () => setState(() {
        _videoSort = index;
        _cachedAssets.remove(4);
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? AppTheme.primary : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _emptyState(PhotoScannerService scanner) {
    final error = scanner.lastError;
    final completedEmpty = scanner.hasCompletedScan && error == null;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                error == null ? Icons.search_rounded : Icons.error_outline,
                size: 36,
                color: error == null ? AppTheme.primary : AppTheme.warning,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              completedEmpty
                  ? context.l10n.homeDoneStatus
                  : error == null
                  ? context.l10n.scanStartAlbumTitle
                  : context.l10n.scanIncompleteTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              completedEmpty
                  ? context.l10n.homeIndexedCountWithTotal(
                      0,
                      scanner.availableAssetCount ?? 0,
                    )
                  : error == null
                  ? context.l10n.scanStartAlbumDescription
                  : context.localizeServiceMessage(error),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: scanner.isDeleting
                      ? null
                      : scanner.wasCancelled
                      ? scanner.resumeScan
                      : scanner.startFullScan,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),
                    child: Text(
                      scanner.wasCancelled
                          ? context.l10n.scanContinue
                          : context.l10n.scanStart,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scanningState(PhotoScannerService scanner) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: ScanProgressPanel(scanner: scanner),
  );

  Widget _content(PhotoScannerService scanner) {
    final groups = _groupsFor(_selectedCategory, scanner);
    final assets = _assetsFor(_selectedCategory, scanner);
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            (constraints.maxWidth / (120 * textScale.clamp(1.0, 1.6)))
                .floor()
                .clamp(2, 8);
        final tileWidth =
            (constraints.maxWidth - 24 - 6 * (columns - 1)) / columns;
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isSwipeCategory && assets.isNotEmpty)
                      _swipeCard(scanner),
                    if (_isResourceCategory && _pendingChecks(scanner) > 0) ...[
                      const SizedBox(height: 12),
                      _verificationCard(
                        scanner,
                        compact: groups.isNotEmpty || assets.isNotEmpty,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _scanDetails(scanner),
                    if (!scanner.isScanning &&
                        (scanner.wasCancelled ||
                            scanner.pendingAnalysisCount > 0))
                      TextButton.icon(
                        onPressed: scanner.isDeleting || _isDeleting
                            ? null
                            : scanner.resumeScan,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(context.l10n.scanResumePending),
                      ),
                    if (!_isResourceCategory &&
                        !scanner.isScanning &&
                        scanner.pendingResourceCount > 0)
                      TextButton.icon(
                        onPressed: scanner.isDeleting || _isDeleting
                            ? null
                            : scanner.verifyOriginals,
                        icon: const Icon(Icons.verified_outlined),
                        label: Text(context.l10n.scanVerifyNow),
                      ),
                    if (assets.isNotEmpty || _selectedIds.isNotEmpty)
                      _selectionActions(scanner, assets),
                  ],
                ),
              ),
            ),
            if (groups.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _groupRow(groups[index]),
                  childCount: groups.length,
                ),
              )
            else if (assets.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 10,
                    mainAxisExtent: tileWidth + 45 * textScale,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _thumbnail(assets[index], semanticIndex: index + 1),
                    childCount: assets.length,
                  ),
                ),
              )
            else if (!_isResourceCategory || _pendingChecks(scanner) == 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    _emptyCategoryMessage(scanner),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  bool get _isResourceCategory =>
      _selectedCategory == 1 || _selectedCategory == 5;
  bool get _isManualCategory => const [0, 3, 4, 5].contains(_selectedCategory);

  bool get _isSwipeCategory => _selectedCategory == 0 || _selectedCategory == 3;

  int _pendingChecks(PhotoScannerService scanner) => _selectedCategory == 1
      ? scanner.pendingHashAssetCount
      : scanner.pendingSizeAssetCount;

  int _verifiedChecks(PhotoScannerService scanner) => _selectedCategory == 1
      ? scanner.verifiedHashAssetCount
      : scanner.knownSizeAssetCount;

  int _checkTotal(PhotoScannerService scanner) => _selectedCategory == 1
      ? scanner.totalPhotoCount
      : scanner.scannedAssetCount;

  Widget _swipeCard(PhotoScannerService scanner) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.primaryLight,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.swipe_rounded, color: AppTheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.l10n.scanSwipeCleanup,
                style: AppTheme.heading3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(context.l10n.scanSwipeIntro, style: AppTheme.caption),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('start-category-swipe'),
          onPressed: scanner.isScanning || scanner.isDeleting || _isDeleting
              ? null
              : () => _openSwipeMode(scanner),
          icon: const Icon(Icons.swipe_rounded),
          label: Text(context.l10n.scanSwipeStart),
        ),
      ],
    ),
  );

  Widget _scanDetails(PhotoScannerService scanner) => AnimatedBuilder(
    animation: scanner,
    builder: (context, _) => ExpansionTile(
      key: ValueKey('scan-details-$_selectedCategory'),
      tilePadding: EdgeInsets.zero,
      title: Text(context.l10n.scanDetails),
      subtitle: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          Text(
            context.l10n.scanVisualSuccessCount(scanner.analyzedAssetCount),
            style: AppTheme.caption,
          ),
          Text(
            context.l10n.scanOriginalVerifiedCount(
              scanner.verifiedOriginalCount,
            ),
            style: AppTheme.caption,
          ),
        ],
      ),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (scanner.isScanning) ...[
          ScanProgressPanel(scanner: scanner, compact: true),
          const SizedBox(height: 8),
          Text(context.l10n.scanPreviewWhileRunning, style: AppTheme.caption),
        ],
        if (scanner.scanNotice != null)
          Text(
            context.localizeServiceMessage(scanner.scanNotice!),
            style: AppTheme.caption,
          ),
        Text(
          _selectedCategory == 1
              ? context.l10n.scanExactDescription
              : _selectedCategory == 2
              ? context.l10n.scanSimilarDescription
              : _selectedCategory == 5
              ? context.l10n.scanLargeDescription
              : context.l10n.scanManualDeleteDescription,
          style: AppTheme.caption,
        ),
      ],
    ),
  );

  Widget _verificationCard(
    PhotoScannerService scanner, {
    required bool compact,
  }) => AnimatedBuilder(
    animation: scanner,
    builder: (context, _) {
      final checking = scanner.isScanning && scanner.isVerifyingOriginals;
      return Container(
        key: const ValueKey('original-verification-card'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (checking)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(
                    Icons.fact_check_outlined,
                    color: AppTheme.primary,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    checking
                        ? context.l10n.scanCountConfirming
                        : _verifiedChecks(scanner) == 0
                        ? context.l10n.scanVerificationNeeded
                        : _categories[_selectedCategory],
                    style: AppTheme.heading3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.scanVerificationProgress(
                _verifiedChecks(scanner),
                _checkTotal(scanner),
              ),
            ),
            Text(
              context.l10n.scanPendingCheckCount(_pendingChecks(scanner)),
              style: AppTheme.caption,
            ),
            if (!compact) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.scanVerificationExplanation,
                style: AppTheme.caption,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const ValueKey('verify-originals-cta'),
                  onPressed:
                      scanner.isScanning || scanner.isDeleting || _isDeleting
                      ? null
                      : () => scanner.verifyOriginals(
                          target: _verificationTarget,
                        ),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(
                    _verificationTarget ==
                            OriginalVerificationTarget.exactPhotos
                        ? context.l10n.scanCheckExactPhotos
                        : _verificationTarget ==
                              OriginalVerificationTarget.fileSizes
                        ? context.l10n.scanCheckFileSizes
                        : context.l10n.scanVerifyNow,
                  ),
                ),
                TextButton(
                  onPressed: scanner.isDeleting || _isDeleting
                      ? null
                      : () {
                          setState(() {
                            _selectedCategory = 0;
                            _selectedIds.clear();
                            _selectionUndo = null;
                          });
                          _revealSelectedCategory();
                        },
                  child: Text(context.l10n.scanBrowsePhotos),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );

  Widget _selectionActions(
    PhotoScannerService scanner,
    List<PhotoAsset> assets,
  ) {
    final enabled = !scanner.isScanning && !scanner.isDeleting && !_isDeleting;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (_isManualCategory && assets.isNotEmpty)
          TextButton.icon(
            key: const ValueKey('select-current-category'),
            onPressed: enabled
                ? () => _changeSelection(
                    () => _selectedIds.addAll(assets.map((asset) => asset.id)),
                  )
                : null,
            icon: const Icon(Icons.select_all_rounded),
            label: Text(context.l10n.scanSelectAll),
          ),
        if (_selectedIds.isNotEmpty)
          TextButton.icon(
            onPressed: enabled
                ? () => _changeSelection(_selectedIds.clear)
                : null,
            icon: const Icon(Icons.deselect_rounded),
            label: Text(context.l10n.scanClearSelection),
          ),
        if (_selectionUndo != null)
          TextButton.icon(
            onPressed: enabled
                ? () => setState(() {
                    _selectedIds.clear();
                    _selectedIds.addAll(
                      _selectionUndo!.intersection(
                        scanner.scanResult.allAssets
                            .map((asset) => asset.id)
                            .toSet(),
                      ),
                    );
                    _selectionUndo = null;
                  })
                : null,
            icon: const Icon(Icons.undo_rounded),
            label: Text(context.l10n.swipeUndoChoice),
          ),
      ],
    );
  }

  void _changeSelection(VoidCallback change) {
    final scanner = context.read<PhotoScannerService>();
    if (scanner.isScanning || scanner.isDeleting || _isDeleting) return;
    setState(() {
      _selectionUndo = Set<String>.from(_selectedIds);
      change();
    });
  }

  void _selectGroupOthers(_ReviewGroup group, String keepId) {
    if (!group.assets.any((asset) => asset.id == keepId)) return;
    _changeSelection(() {
      _selectedIds.removeAll(group.assets.map((asset) => asset.id));
      _selectedIds.addAll(
        group.assets
            .where((asset) => asset.id != keepId)
            .map((asset) => asset.id),
      );
    });
  }

  String _keeperActionLabel(PhotoAsset asset, int index) => [
    context.l10n.scanCategoryPhotos,
    index.toString(),
    if (asset.title?.trim().isNotEmpty == true) asset.title!.trim(),
    context.l10n.scanKeepOneSelectOthers,
  ].join(' · ');

  Widget _groupRow(_ReviewGroup group) {
    final suggested =
        !_dismissedSuggestions.contains(group.key) &&
            group.assets.any((asset) => asset.id == group.bestAssetId)
        ? group.bestAssetId
        : null;
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final tileWidth = 112 * textScale.clamp(1.0, 1.5);
    final actionText = TextPainter(
      text: TextSpan(
        text: context.l10n.scanKeepOneSelectOthers,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
    )..layout(maxWidth: tileWidth - 32);
    final tileHeight = tileWidth + 60 * textScale + actionText.height + 32;
    actionText.dispose();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedCategory == 1
                ? context.l10n.scanExactGroupCount(group.assets.length)
                : context.l10n.scanSimilarGroupCount(group.assets.length),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (group.bestAssetId != null) ...[
            if (suggested != null)
              Text(
                context.l10n.scanRecommendedKeep(
                  group.bestReason == null
                      ? context.l10n.scanKeepReasonDefault
                      : context.localizeServiceMessage(group.bestReason!),
                ),
                style: AppTheme.caption,
              ),
            TextButton(
              onPressed: () => setState(() {
                suggested == null
                    ? _dismissedSuggestions.remove(group.key)
                    : _dismissedSuggestions.add(group.key);
              }),
              child: Text(
                suggested == null
                    ? context.l10n.scanRestoreKeepSuggestion
                    : context.l10n.scanDismissKeepSuggestion,
              ),
            ),
          ],
          Text(context.l10n.scanSelectOthersHint, style: AppTheme.caption),
          if (suggested != null)
            FilledButton.icon(
              key: ValueKey('keep-suggested-${group.key}'),
              onPressed:
                  context.read<PhotoScannerService>().isScanning ||
                      context.read<PhotoScannerService>().isDeleting ||
                      _isDeleting
                  ? null
                  : () => _selectGroupOthers(group, suggested),
              icon: const Icon(Icons.bookmark_rounded),
              label: Text(
                context.l10n.scanKeepOneSelectOthers,
                semanticsLabel: _keeperActionLabel(
                  group.assets.firstWhere((asset) => asset.id == suggested),
                  group.assets.indexWhere((asset) => asset.id == suggested) + 1,
                ),
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            height: tileHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: group.assets.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) => SizedBox(
                width: tileWidth,
                child: Column(
                  children: [
                    Expanded(
                      child: _thumbnail(
                        group.assets[index],
                        recommended: suggested == group.assets[index].id,
                        semanticIndex: index + 1,
                      ),
                    ),
                    TextButton(
                      key: ValueKey('keep-group-${group.assets[index].id}'),
                      onPressed:
                          context.read<PhotoScannerService>().isScanning ||
                              context.read<PhotoScannerService>().isDeleting ||
                              _isDeleting
                          ? null
                          : () => _selectGroupOthers(
                              group,
                              group.assets[index].id,
                            ),
                      child: Text(
                        context.l10n.scanKeepOneSelectOthers,
                        semanticsLabel: _keeperActionLabel(
                          group.assets[index],
                          index + 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _emptyCategoryMessage(PhotoScannerService scanner) {
    if ((_selectedCategory == 1 || _selectedCategory == 5) &&
        _pendingChecks(scanner) > 0) {
      return context.l10n.scanEmptyUnverified;
    }
    if (_selectedCategory == 2 && scanner.pendingAnalysisCount > 0) {
      return context.l10n.scanEmptyVisualPending;
    }
    if (scanner.isScanning &&
        scanner.currentPhase == ScanPhase.fetchingAssets) {
      return context.l10n.scanEmptyIndexing;
    }
    return context.l10n.scanEmptyCategory;
  }

  Widget _thumbnail(
    PhotoAsset asset, {
    bool recommended = false,
    int semanticIndex = 1,
  }) {
    final scanner = context.read<PhotoScannerService>();
    final selected = _selectedIds.contains(asset.id);
    final enabled = !scanner.isScanning && !scanner.isDeleting && !_isDeleting;
    void toggleSelection() {
      if (scanner.isScanning || scanner.isDeleting || _isDeleting) return;
      setState(() {
        _selectionUndo = null;
        selected ? _selectedIds.remove(asset.id) : _selectedIds.add(asset.id);
      });
    }

    final label = [
      asset.type == AssetType.video
          ? context.l10n.scanCategoryVideos
          : context.l10n.scanCategoryPhotos,
      semanticIndex.toString(),
      if (asset.title?.trim().isNotEmpty == true) asset.title!.trim(),
      MaterialLocalizations.of(context).formatFullDate(asset.createDate),
      context.l10n.assetPreviewDetails(
        asset.width,
        asset.height,
        assetSizeLabel(asset, context: context),
      ),
      if (recommended) context.l10n.scanKeepBadge,
    ].join(' · ');
    return Semantics(
      container: true,
      label: label,
      checked: selected,
      selected: selected,
      enabled: enabled,
      onTap: enabled ? toggleSelection : null,
      child: FocusableActionDetector(
        enabled: enabled,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              toggleSelection();
              return null;
            },
          ),
        },
        onShowFocusHighlight: (focused) => setState(() {
          if (focused) {
            _focusedAssetId = asset.id;
          } else if (_focusedAssetId == asset.id) {
            _focusedAssetId = null;
          }
        }),
        child: GestureDetector(
          key: ValueKey('select-${asset.id}'),
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: enabled ? toggleSelection : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: selected
                        ? Border.all(color: AppTheme.danger, width: 2.5)
                        : _focusedAssetId == asset.id
                        ? Border.all(color: AppTheme.primary, width: 2.5)
                        : null,
                    color: Colors.grey[100],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: AssetThumbnail(asset: asset),
                      ),
                      if (recommended)
                        PositionedDirectional(
                          top: 4,
                          start: 4,
                          end: 4,
                          child: _badge(
                            context.l10n.scanKeepBadge,
                            AppTheme.success,
                          ),
                        ),
                      if (!scanner.isScanning)
                        PositionedDirectional(
                          bottom: 4,
                          end: 4,
                          child: Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: selected ? AppTheme.danger : Colors.white,
                            size: 24,
                          ),
                        ),
                      PositionedDirectional(
                        bottom: 0,
                        start: 0,
                        child: IconButton(
                          tooltip: context.l10n.scanZoomPreview,
                          icon: const Icon(
                            Icons.zoom_in_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => _previewAsset(asset),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      assetSizeLabel(asset, context: context),
                      style: const TextStyle(fontSize: 11),
                      maxLines: 2,
                    ),
                  ),
                  if (asset.type == AssetType.video)
                    IconButton(
                      tooltip: context.l10n.scanCompressVideo,
                      icon: const Icon(Icons.compress_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      onPressed: scanner.isScanning || scanner.isDeleting
                          ? null
                          : () => _openCompression(asset),
                    ),
                ],
              ),
              if (asset.analysisPending)
                Text(
                  context.l10n.scanContentPending,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _previewAsset(PhotoAsset asset) => showAssetPreview(context, asset);

  Widget _bottomBar(PhotoScannerService scanner, SubscriptionManager sub) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.scanSelectedCount(_selectedIds.length),
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 48),
              decoration: BoxDecoration(
                gradient: AppTheme.dangerGradient,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: _isDeleting || scanner.isScanning || scanner.isDeleting
                      ? null
                      : () => _previewDelete(scanner, sub),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isDeleting)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Icon(
                            Icons.visibility_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _isDeleting
                                ? context.l10n.homeDeleting
                                : context.l10n.scanPreviewDeleteCount(
                                    _selectedIds.length,
                                  ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _countFor(int category, PhotoScannerService scanner) {
    final result = scanner.scanResult;
    return switch (category) {
      0 => _assetsFor(0, scanner).length,
      1 => result.duplicateGroups.fold<int>(
        0,
        (sum, group) => sum + group.assets.length,
      ),
      2 => result.similarGroups.fold<int>(
        0,
        (sum, group) => sum + group.assets.length,
      ),
      3 => result.screenshots.length,
      4 => result.videos.length,
      5 => result.largeFiles.length,
      _ => 0,
    };
  }

  List<_ReviewGroup> _groupsFor(int category, PhotoScannerService scanner) {
    if (category == 1) {
      return scanner.scanResult.duplicateGroups
          .map(
            (group) => _ReviewGroup(
              key: 'duplicate:${group.hash}',
              assets: group.assets,
              bestAssetId: group.bestAssetId,
              bestReason: group.bestReason,
            ),
          )
          .toList();
    }
    if (category == 2) {
      return scanner.scanResult.similarGroups
          .map(
            (group) => _ReviewGroup(
              key: 'similar:${group.assets.map((asset) => asset.id).join(',')}',
              assets: group.assets,
              bestAssetId: group.bestAssetId,
              bestReason: group.bestReason,
            ),
          )
          .toList();
    }
    return [];
  }

  List<PhotoAsset> _assetsFor(int category, PhotoScannerService scanner) {
    final result = scanner.scanResult;
    return _cachedAssets.putIfAbsent(
      category,
      () => switch (category) {
        0 =>
          result.allAssets
              .where((asset) => asset.type == AssetType.image)
              .toList(),
        1 => result.duplicateGroups.expand((group) => group.assets).toList(),
        2 => result.similarGroups.expand((group) => group.assets).toList(),
        3 => result.screenshots,
        4 => _sortedVideos(result.videos),
        5 => result.largeFiles,
        _ => [],
      },
    );
  }

  List<PhotoAsset> _sortedVideos(List<PhotoAsset> videos) {
    final sorted = List<PhotoAsset>.from(videos);
    switch (_videoSort) {
      case 1:
        sorted.sort((a, b) => b.createDate.compareTo(a.createDate));
      case 0:
      case 2:
      default:
        sorted.sort((a, b) => b.size.compareTo(a.size));
    }
    return sorted;
  }

  void _openSwipeMode(PhotoScannerService scanner) {
    if (!_isSwipeCategory ||
        scanner.isScanning ||
        scanner.isDeleting ||
        _isDeleting) {
      return;
    }
    final assets = _assetsFor(_selectedCategory, scanner);
    if (assets.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SwipeCleanView(
          assets: assets,
          title: _categories[_selectedCategory],
          categoryId: _categoryIds[_selectedCategory],
        ),
      ),
    );
  }

  void _openCompression(PhotoAsset asset) {
    final scanner = context.read<PhotoScannerService>();
    final subscription = context.read<SubscriptionManager>();
    if (_isDeleting || scanner.isScanning || scanner.isDeleting) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => subscription.isPro
            ? VideoCompressionView(asset: asset)
            : const PaywallView(),
      ),
    );
  }

  void _previewDelete(PhotoScannerService scanner, SubscriptionManager sub) {
    if (_isDeleting || scanner.isScanning || scanner.isDeleting) return;
    if (!sub.isPro) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PaywallView()),
      );
      return;
    }

    final toDelete = scanner.scanResult.allAssets
        .where((asset) => _selectedIds.contains(asset.id))
        .toList();
    if (toDelete.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.l10n.scanConfirmDeleteTitle),
        content: SingleChildScrollView(
          child: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.scanConfirmDeleteDescription(toDelete.length),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: GridView.builder(
                    itemCount: toDelete.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                    itemBuilder: (context, index) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AssetThumbnail(asset: toDelete[index]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.scanCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (scanner.isScanning || scanner.isDeleting || !sub.isPro) {
                return;
              }
              setState(() => _isDeleting = true);
              final deletedIds = await scanner.deleteAssetsWithResult(toDelete);
              if (!mounted) return;
              setState(() {
                _isDeleting = false;
                _selectedIds.removeAll(deletedIds);
              });
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(
                    deletedIds.isEmpty
                        ? this.context.l10n.scanNoItemsDeleted
                        : this.context.l10n.scanItemsDeleted(deletedIds.length),
                  ),
                ),
              );
            },
            child: Text(
              context.l10n.scanConfirmDelete,
              style: const TextStyle(
                color: AppTheme.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewGroup {
  final String key;
  final List<PhotoAsset> assets;
  final String? bestAssetId;
  final String? bestReason;
  const _ReviewGroup({
    required this.key,
    required this.assets,
    this.bestAssetId,
    this.bestReason,
  });
}
