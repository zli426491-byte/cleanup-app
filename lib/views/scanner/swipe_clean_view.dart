import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/photo_scanner_service.dart';
import '../../services/subscription_manager.dart';
import '../../utils/app_theme.dart';
import '../paywall/paywall_view.dart';
import 'asset_thumbnail.dart';
import 'asset_preview.dart';
import 'photo_asset_labels.dart';
import 'delete_review.dart';
import '../../services/review_checkpoint_service.dart';

/// Tinder-style swipe to delete/keep photos
class SwipeCleanView extends StatefulWidget {
  final List<PhotoAsset> assets;
  final String title;
  final String? categoryId;
  final ReviewCheckpointService? checkpointService;

  const SwipeCleanView({
    super.key,
    required this.assets,
    required this.title,
    this.categoryId,
    this.checkpointService,
  });

  @override
  State<SwipeCleanView> createState() => _SwipeCleanViewState();
}

class _SwipeCleanViewState extends State<SwipeCleanView>
    with TickerProviderStateMixin {
  static const _firstUseGuideKey = 'cleanup.swipe.first_use_guide.v1';
  int _currentIndex = 0;
  late List<PhotoAsset> _sessionAssets;
  late final ReviewCheckpointService _checkpoint;
  Timer? _checkpointTimer;
  bool _checkpointFailed = false;
  bool _loadingCheckpoint = true;
  bool _snappingBack = false;
  bool _guideOpen = false;
  String get _checkpointCategory => widget.categoryId ?? 'photos';
  bool get _canBulkSelect =>
      _checkpointCategory != 'duplicates' && _checkpointCategory != 'similar';
  final List<PhotoAsset> _toDelete = [];
  final List<PhotoAsset> _toKeep = [];
  final List<int> _reviewHistory = [];
  final Set<String> _previewReadyIds = {};
  bool _allowPop = false;

  // Drag state
  double _dragX = 0;
  double _dragY = 0;
  late AnimationController _animController;
  late Animation<double> _animX;
  late Animation<double> _animY;
  bool _isAnimating = false;
  bool _isDeleting = false;
  bool _reviewInProgress = false;
  int _deletedCount = 0;

  @override
  void initState() {
    super.initState();
    _sessionAssets = List.of(widget.assets);
    _checkpoint = widget.checkpointService ?? ReviewCheckpointService();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _dragX = 0;
          _dragY = 0;
          _isAnimating = false;
          if (!_snappingBack) _currentIndex++;
          _snappingBack = false;
        });
        _animController.reset();
      }
    });
    unawaited(_initializeReview());
  }

  @override
  void dispose() {
    _checkpointTimer?.cancel();
    unawaited(_checkpoint.flush(_checkpointCategory).catchError((Object _) {}));
    _animController.dispose();
    super.dispose();
  }

  bool get _isDone => _currentIndex >= _sessionAssets.length;
  PhotoAsset? get _currentAsset =>
      _isDone ? null : _sessionAssets[_currentIndex];
  double get _progress =>
      widget.assets.isEmpty ? 1.0 : _currentIndex / _sessionAssets.length;

  Future<void> _initializeReview() async {
    await _restoreCheckpoint();
    if (!mounted || _isDone) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted || preferences.getBool(_firstUseGuideKey) == true) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            !_isDone &&
            !_guideOpen &&
            ModalRoute.of(context)?.isCurrent == true) {
          unawaited(_showGestureHelp());
        }
      });
    } catch (_) {
      // A failed hint preference must never stop photo review.
    }
  }

  // Swipe direction indicator
  Future<void> _restoreCheckpoint() async {
    try {
      final decisions = await _checkpoint.load(
        _checkpointCategory,
        widget.assets,
      );
      if (!mounted) return;
      setState(() => _loadingCheckpoint = false);
      if (decisions.isEmpty) return;
      final resume = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.swipeReviewBatch),
          content: Text(context.l10n.swipeResumeReview(decisions.length)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.swipeResetReview),
            ),
            FilledButton(
              key: const ValueKey('resume-review-checkpoint'),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.scanContinue),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (resume != false) {
        setState(() {
          final byId = {for (final asset in widget.assets) asset.id: asset};
          final reviewed = [for (final id in decisions.keys) byId[id]!];
          _sessionAssets = [
            ...reviewed,
            ...widget.assets.where((a) => !decisions.containsKey(a.id)),
          ];
          _currentIndex = reviewed.length;
          _reviewHistory.addAll(
            List.generate(reviewed.length, (index) => index),
          );
          _toKeep.addAll(widget.assets.where((a) => decisions[a.id] == 'keep'));
          _toDelete.addAll(
            widget.assets.where((a) => decisions[a.id] == 'delete'),
          );
        });
      } else if (resume == false) {
        await _checkpoint.clear(_checkpointCategory);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingCheckpoint = false;
          _checkpointFailed = true;
        });
      }
    }
  }

  void _persistChoice(PhotoAsset asset, String? choice) {
    _checkpoint.record(_checkpointCategory, asset, choice);
    _checkpointTimer?.cancel();
    _checkpointTimer = Timer(
      const Duration(milliseconds: 500),
      _flushCheckpoint,
    );
  }

  Future<void> _flushCheckpoint() async {
    try {
      await _checkpoint.flush(_checkpointCategory);
    } catch (_) {
      if (mounted) setState(() => _checkpointFailed = true);
    }
  }

  Future<void> _chooseBatch() async {
    if (_isAnimating || _isDeleting || _loadingCheckpoint) return;
    final months =
        widget.assets
            .map((a) => DateTime(a.createDate.year, a.createDate.month))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    DateTime? month;
    var batch = 100;
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.swipeReviewBatch, style: AppTheme.heading3),
                DropdownButton<DateTime?>(
                  isExpanded: true,
                  value: month,
                  items: [
                    DropdownMenuItem<DateTime?>(
                      value: null,
                      child: Text(context.l10n.swipeAllMonths),
                    ),
                    for (final date in months)
                      DropdownMenuItem(
                        value: date,
                        child: Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatMonthYear(date),
                        ),
                      ),
                  ],
                  onChanged: (value) => update(() => month = value),
                ),
                DropdownButton<int>(
                  isExpanded: true,
                  value: batch,
                  items: [
                    for (final count in [100, 300, 1000])
                      DropdownMenuItem(
                        value: count,
                        child: Text(context.l10n.swipeBatchSize(count)),
                      ),
                  ],
                  onChanged: (value) => update(() => batch = value ?? 100),
                ),
                Text(
                  context.l10n.swipeCheckpointLimit(_checkpoint.maxEntries),
                  style: AppTheme.caption,
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(context.l10n.scanContinue),
                ),
                TextButton(
                  key: const ValueKey('reset-review-checkpoint'),
                  onPressed: () async {
                    try {
                      await _checkpoint.clear(_checkpointCategory);
                      if (!mounted || !context.mounted) return;
                      setState(() {
                        _sessionAssets = List.of(widget.assets);
                        _currentIndex = 0;
                        _reviewHistory.clear();
                        _toKeep.clear();
                        _toDelete.clear();
                      });
                      Navigator.pop(context, false);
                    } catch (_) {
                      if (mounted) setState(() => _checkpointFailed = true);
                    }
                  },
                  child: Text(context.l10n.swipeResetReview),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || accepted != true) return;
    final reviewed = {
      ..._toKeep.map((a) => a.id),
      ..._toDelete.map((a) => a.id),
    };
    setState(() {
      _sessionAssets = widget.assets
          .where(
            (a) =>
                !reviewed.contains(a.id) &&
                (month == null ||
                    a.createDate.year == month!.year &&
                        a.createDate.month == month!.month),
          )
          .take(batch)
          .toList();
      _currentIndex = 0;
      _reviewHistory.clear();
    });
  }

  Future<void> _selectMany() async {
    if (_isAnimating ||
        _isDeleting ||
        _loadingCheckpoint ||
        _isDone ||
        !_canBulkSelect) {
      return;
    }
    final remaining = _sessionAssets.skip(_currentIndex).toList();
    final picked = await showModalBottomSheet<List<PhotoAsset>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _MultiSelectSheet(assets: remaining),
    );
    if (!mounted || picked == null || picked.isEmpty || _isDone) return;

    // The sheet can only return decoded previews from the current review.
    final pickedIds = picked.map((asset) => asset.id).toSet();
    final selected = remaining.where((asset) => pickedIds.contains(asset.id));
    final selectedAssets = selected.toList();
    if (selectedAssets.isEmpty) return;
    final unselected = remaining.where(
      (asset) => !pickedIds.contains(asset.id),
    );
    final reviewedCount = _currentIndex;
    setState(() {
      _sessionAssets = [
        ..._sessionAssets.take(reviewedCount),
        ...selectedAssets,
        ...unselected,
      ];
      for (var i = 0; i < selectedAssets.length; i++) {
        final asset = selectedAssets[i];
        _toDelete.add(asset);
        _reviewHistory.add(reviewedCount + i);
        _persistChoice(asset, 'delete');
      }
      _currentIndex += selectedAssets.length;
    });
    _checkpointTimer?.cancel();
    unawaited(_flushCheckpoint());
  }

  String get _swipeLabel {
    if (_dragX > 40) return context.l10n.swipeKeep;
    if (_dragX < -40) return context.l10n.swipeDelete;
    return '';
  }

  Color get _swipeColor {
    if (_dragX > 40) return AppTheme.success;
    if (_dragX < -40) return AppTheme.danger;
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_isDeleting) _requestExit();
      },
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: AppBar(
          title: Text(switch (widget.categoryId) {
            'photos' => context.l10n.scanCategoryPhotos,
            'duplicates' => context.l10n.scanCategoryExact,
            'similar' => context.l10n.scanCategorySimilar,
            'screenshots' => context.l10n.scanCategoryScreenshots,
            'videos' => context.l10n.scanCategoryVideos,
            'largeFiles' => context.l10n.scanCategoryLarge,
            _ => widget.title,
          }),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: context.l10n.swipeLeave,
            onPressed: _isDeleting ? null : _requestExit,
          ),
          actions: [
            IconButton(
              tooltip: context.l10n.swipeReviewBatch,
              icon: const Icon(Icons.calendar_month_outlined),
              onPressed: _isDeleting ? null : _chooseBatch,
            ),
            IconButton(
              tooltip: context.l10n.swipeGestureHelp,
              icon: const Icon(Icons.help_outline_rounded),
              onPressed: _isDeleting ? null : () => _showGestureHelp(),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.5,
              ),
              child: TextButton(
                onPressed: _isDone || _isAnimating
                    ? null
                    : () => _showResultDialog(),
                child: Text(
                  context.l10n.swipeDoneCount(_toDelete.length),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: _loadingCheckpoint
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    if (_checkpointFailed)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(context.l10n.swipeCheckpointSaveError),
                      ),
                    Expanded(
                      child: _isDone ? _buildDoneView() : _buildSwipeView(),
                    ),
                    if (!_isDone) _buildActions(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSwipeView() {
    final asset = _currentAsset!;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            children: [
              _gestureGuide(),
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      context.l10n.swipeProgressCount(
                        _currentIndex + 1,
                        _sessionAssets.length,
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 4,
                          backgroundColor: Colors.grey.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation(
                            AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Stats bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _statChip(
                      Icons.delete_rounded,
                      context.l10n.swipeDeleteCount(_toDelete.length),
                      AppTheme.danger,
                    ),
                    _statChip(
                      Icons.bookmark_rounded,
                      context.l10n.swipeKeepCount(_toKeep.length),
                      AppTheme.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card stack
              SizedBox(
                height: (constraints.maxHeight * 0.65).clamp(260.0, 620.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Next card (background)
                    if (_currentIndex + 1 < _sessionAssets.length)
                      ExcludeSemantics(
                        child: IgnorePointer(
                          child: _buildCard(
                            _sessionAssets[_currentIndex + 1],
                            isBackground: true,
                            height: (constraints.maxHeight * 0.65).clamp(
                              260.0,
                              620.0,
                            ),
                          ),
                        ),
                      ),

                    // Current card (draggable)
                    GestureDetector(
                      onHorizontalDragUpdate: (d) => setState(() {
                        if (_isAnimating) return;
                        _dragX += d.delta.dx;
                        _dragY += d.delta.dy * 0.3;
                      }),
                      onHorizontalDragEnd: (details) =>
                          _onDragEnd(details.primaryVelocity ?? 0),
                      child: AnimatedBuilder(
                        animation: _animController,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(
                            _isAnimating ? _animX.value : _dragX,
                            _isAnimating ? _animY.value : _dragY,
                          ),
                          child: Transform.rotate(
                            angle: (_isAnimating ? _animX.value : _dragX) / 800,
                            child: Stack(
                              children: [
                                _buildCard(
                                  asset,
                                  isBackground: false,
                                  height: (constraints.maxHeight * 0.65).clamp(
                                    260.0,
                                    620.0,
                                  ),
                                ),
                                // Swipe label overlay
                                if (_swipeLabel.isNotEmpty)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(28),
                                        border: Border.all(
                                          color: _swipeColor,
                                          width: 4,
                                        ),
                                      ),
                                      child: Center(
                                        child: Transform.rotate(
                                          angle: _dragX > 0 ? -0.3 : 0.3,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: _swipeColor,
                                                width: 3,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _swipeLabel,
                                              style: TextStyle(
                                                color: _swipeColor,
                                                fontSize: 32,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    final asset = _currentAsset!;
    return Container(
      key: const ValueKey('swipe-fixed-actions'),
      decoration: const BoxDecoration(
        color: AppTheme.bg,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
      child: Row(
        // Gesture directions remain physical even in an RTL interface.
        textDirection: TextDirection.ltr,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionButton(
            icon: Icons.close_rounded,
            label: context.l10n.swipeDelete,
            color: AppTheme.danger,
            size: 64,
            onTap: _isAnimating || !_previewReadyIds.contains(asset.id)
                ? null
                : () => _swipeAway(-1),
          ),
          _actionButton(
            icon: Icons.undo_rounded,
            label: context.l10n.swipeUndoChoice,
            color: AppTheme.warning,
            size: 48,
            onTap: _isAnimating || _reviewHistory.isEmpty ? null : _undo,
          ),
          _actionButton(
            icon: Icons.bookmark_rounded,
            label: context.l10n.swipeKeep,
            color: AppTheme.success,
            size: 64,
            onTap: _isAnimating ? null : () => _swipeAway(1),
          ),
        ],
      ),
    );
  }

  Widget _gestureGuide({bool expanded = false}) => Container(
    key: expanded ? null : const ValueKey('swipe-gesture-guide'),
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (expanded) ...[
          Text(context.l10n.swipeGestureTitle, style: AppTheme.heading3),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      textDirection: TextDirection.ltr,
                      color: AppTheme.danger,
                      size: 18,
                    ),
                  ),
                  TextSpan(text: ' ${context.l10n.swipeGestureDelete}'),
                ],
              ),
              style: AppTheme.body.copyWith(
                color: AppTheme.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${context.l10n.swipeGestureKeep} '),
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      textDirection: TextDirection.ltr,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                  ),
                ],
              ),
              style: AppTheme.body.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(context.l10n.swipeGestureSafety, style: AppTheme.caption),
        if (!expanded && _canBulkSelect) ...[
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              key: const ValueKey('swipe-select-many'),
              onPressed: _isAnimating || _isDeleting ? null : _selectMany,
              icon: const Icon(Icons.grid_view_rounded),
              label: Text(context.l10n.swipeMultiSelectTitle),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _firstUseDirectionCard({
    required IconData icon,
    required String label,
    required Color color,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withValues(alpha: 0.22)),
    ),
    child: Row(
      textDirection: TextDirection.ltr,
      children: [
        Icon(icon, textDirection: TextDirection.ltr, color: color, size: 32),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: AppTheme.body.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _showGestureHelp() async {
    if (_guideOpen || !mounted) return;
    _guideOpen = true;
    bool? openMultiSelect;
    try {
      openMultiSelect = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.swipeGestureTitle, style: AppTheme.heading3),
                const SizedBox(height: 16),
                _firstUseDirectionCard(
                  icon: Icons.arrow_back_rounded,
                  label: context.l10n.swipeGestureDelete,
                  color: AppTheme.danger,
                ),
                const SizedBox(height: 10),
                _firstUseDirectionCard(
                  icon: Icons.arrow_forward_rounded,
                  label: context.l10n.swipeGestureKeep,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 12),
                Text(context.l10n.swipeGestureSafety, style: AppTheme.caption),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    child: Text(context.l10n.swipeContinueReview),
                  ),
                ),
                if (_canBulkSelect)
                  TextButton.icon(
                    key: const ValueKey('swipe-help-select-many'),
                    onPressed: () => Navigator.pop(sheetContext, true),
                    icon: const Icon(Icons.grid_view_rounded),
                    label: Text(context.l10n.swipeMultiSelectTitle),
                  ),
              ],
            ),
          ),
        ),
      );
    } finally {
      _guideOpen = false;
      try {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setBool(_firstUseGuideKey, true);
      } catch (_) {
        // The hint remains replayable even when persistence is unavailable.
      }
    }
    if (mounted && openMultiSelect == true) await _selectMany();
  }

  Widget _buildCard(
    PhotoAsset asset, {
    required bool isBackground,
    required double height,
  }) {
    return Container(
      width: (MediaQuery.of(context).size.width - 48).clamp(200, 600),
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isBackground ? 0.04 : 0.1),
            blurRadius: isBackground ? 10 : 24,
            offset: Offset(0, isBackground ? 4 : 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            // Photo
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.grey[100],
                child: AssetThumbnail(
                  key: ValueKey(asset.id),
                  asset: asset,
                  previewSize: 800,
                  fullImage: !isBackground,
                  onPreviewReady: (ready) {
                    if (!mounted) return;
                    final changed = ready
                        ? _previewReadyIds.add(asset.id)
                        : _previewReadyIds.remove(asset.id);
                    if (changed) setState(() {});
                  },
                ),
              ),
            ),
            // Info bar
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.assetDimensions(
                                asset.width,
                                asset.height,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              assetSizeLabel(asset, context: context),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isBackground) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: context.l10n.scanZoomPreview,
                          icon: const Icon(Icons.zoom_in_rounded),
                          onPressed: () => showAssetPreview(context, asset),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      MaterialLocalizations.of(
                        context,
                      ).formatShortDate(asset.createDate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required double size,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: Tooltip(
        message: label,
        child: Semantics(
          label: label,
          button: true,
          enabled: onTap != null,
          excludeSemantics: true,
          onTap: onTap,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Column(
                children: [
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: onTap == null ? Colors.grey : color,
                      size: size * 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.small.copyWith(
                      color: onTap == null ? AppTheme.textMuted : color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Actions ---

  void _onDragEnd(double velocity) {
    if (_dragX.abs() > 100 ||
        velocity.abs() > 700 &&
            _dragX.abs() > 20 &&
            velocity.sign == _dragX.sign) {
      _swipeAway(_dragX > 0 ? 1 : -1);
    } else {
      if (MediaQuery.disableAnimationsOf(context)) {
        setState(() {
          _dragX = 0;
          _dragY = 0;
        });
        return;
      }
      _snappingBack = true;
      _animX = Tween<double>(begin: _dragX, end: 0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
      );
      _animY = Tween<double>(begin: _dragY, end: 0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
      );
      setState(() => _isAnimating = true);
      _animController.forward();
    }
  }

  void _swipeAway(int direction) {
    if (_isDone || _isAnimating) return;

    final asset = _currentAsset!;
    if (direction < 0 && !_previewReadyIds.contains(asset.id)) {
      setState(() {
        _dragX = 0;
        _dragY = 0;
      });
      return;
    }
    _reviewHistory.add(_currentIndex);
    _persistChoice(asset, direction > 0 ? 'keep' : 'delete');
    if (direction > 0) {
      _toKeep.add(asset);
    } else {
      _toDelete.add(asset);
    }

    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() {
        _dragX = 0;
        _dragY = 0;
        _currentIndex++;
      });
      return;
    }

    _animX = Tween<double>(
      begin: _dragX,
      end: direction * 500.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animY = Tween<double>(
      begin: _dragY,
      end: _dragY - 50,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _isAnimating = true;
    _animController.forward();
  }

  void _undo() {
    if (_reviewHistory.isEmpty ||
        _isAnimating ||
        _isDeleting ||
        _deletedCount > 0) {
      return;
    }
    setState(() {
      _currentIndex = _reviewHistory.removeLast();
      final asset = _sessionAssets[_currentIndex];
      _toDelete.remove(asset);
      _toKeep.remove(asset);
      _persistChoice(asset, null);
    });
  }

  // --- Done ---

  Widget _buildDoneView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [AppTheme.colorShadow(AppTheme.primary)],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.swipeReviewComplete,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.swipeReviewSummary(_toDelete.length, _toKeep.length),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.swipeRecoveredSpaceHint,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 32),
            TextButton.icon(
              onPressed: _isDeleting ? null : _chooseBatch,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(context.l10n.swipeReviewBatch),
            ),
            TextButton.icon(
              onPressed:
                  _isDeleting || _deletedCount > 0 || _reviewHistory.isEmpty
                  ? null
                  : _undo,
              icon: const Icon(Icons.undo_rounded),
              label: Text(context.l10n.swipeUndoChoice),
            ),
            // Delete button
            if (_isDeleting)
              const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              ),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 52),
              decoration: BoxDecoration(
                gradient: AppTheme.dangerGradient,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [AppTheme.colorShadow(AppTheme.danger)],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: _isDeleting || _toDelete.isEmpty
                      ? null
                      : _confirmDelete,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _isDeleting
                          ? context.l10n.homeDeleting
                          : context.l10n.swipeDeletePhotos(_toDelete.length),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isDeleting ? null : _requestExit,
              child: Text(
                context.l10n.swipeBack,
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    if (_reviewInProgress) return;
    _reviewInProgress = true;
    try {
      await _reviewAndDelete();
    } finally {
      _reviewInProgress = false;
    }
  }

  void _reviewChanged() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.scanReviewChanged)));
  }

  Future<void> _reviewAndDelete() async {
    final scanner = context.read<PhotoScannerService>();
    if (_isDeleting ||
        scanner.isScanning ||
        scanner.isDeleting ||
        _toDelete.isEmpty) {
      return;
    }
    final sub = context.read<SubscriptionManager>();
    if (!sub.isPro) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallView()),
      );
      return;
    }
    final result = scanner.scanResult;
    final currentVersions = {
      for (final asset in result.allAssets)
        asset.id: ReviewCheckpointService.version(asset),
    };
    if (_toDelete.any(
      (asset) =>
          currentVersions[asset.id] != ReviewCheckpointService.version(asset),
    )) {
      _reviewChanged();
      return;
    }
    final confirmed = await showDeleteReview(
      context,
      assets: List.of(_toDelete),
      previewReadyIds: _previewReadyIds,
      reviewGroups: [
        for (final group in result.duplicateGroups)
          group.assets.map((a) => a.id).toSet(),
        for (final group in result.similarGroups)
          group.assets.map((a) => a.id).toSet(),
      ],
    );
    if (!mounted || confirmed == null || confirmed.isEmpty) {
      return;
    }
    if (!identical(result, scanner.scanResult)) {
      _reviewChanged();
      return;
    }
    final confirmedIds = confirmed.map((a) => a.id).toSet();
    for (final excluded in _toDelete.where(
      (a) => !confirmedIds.contains(a.id),
    )) {
      _persistChoice(excluded, null);
    }
    _toDelete.removeWhere((a) => !confirmedIds.contains(a.id));
    if (!sub.isPro || _isDeleting || scanner.isScanning || scanner.isDeleting) {
      return;
    }
    setState(() => _isDeleting = true);
    final requested = _toDelete.length;
    final deletedIds = await scanner.deleteAssetsWithResult(confirmed);
    for (final asset in confirmed.where((a) => deletedIds.contains(a.id))) {
      _persistChoice(asset, null);
    }
    if (!mounted) return;
    setState(() {
      _isDeleting = false;
      _deletedCount += deletedIds.length;
      _toDelete.removeWhere((asset) => deletedIds.contains(asset.id));
    });
    if (deletedIds.length == requested) {
      _leave();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deletedIds.isEmpty
              ? context.l10n.swipeNoPhotosDeleted
              : context.l10n.swipePartialDeleted(deletedIds.length),
        ),
      ),
    );
  }

  Future<void> _leave() async {
    if (_isDeleting) return;
    _checkpointTimer?.cancel();
    await _flushCheckpoint();
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, _deletedCount);
    });
  }

  void _showExitDialog() {
    if (_isDeleting) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.swipeExitTitle),
        content: Text(context.l10n.swipeExitDescription(_toDelete.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.swipeContinueReview),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _leave();
            },
            child: Text(
              context.l10n.swipeLeave,
              style: const TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
  }

  void _requestExit() {
    if (_isDeleting) return;
    if (_toDelete.isEmpty) {
      _leave();
    } else {
      _showExitDialog();
    }
  }

  void _showResultDialog() {
    final remaining = _sessionAssets.length - _currentIndex;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.swipeSkipRemainingTitle),
        content: Text(
          context.l10n.swipeSkipRemainingDescription(
            remaining,
            _toDelete.length,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.swipeContinueReview),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _currentIndex = _sessionAssets.length);
            },
            child: Text(
              context.l10n.swipeDone,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid decisions stay local until the user reviews the deletion list.
/// A thumbnail must decode before its item can enter that list.
class _MultiSelectSheet extends StatefulWidget {
  const _MultiSelectSheet({required this.assets});

  final List<PhotoAsset> assets;

  @override
  State<_MultiSelectSheet> createState() => _MultiSelectSheetState();
}

class _MultiSelectSheetState extends State<_MultiSelectSheet> {
  final Set<String> _readyIds = {};
  final Set<String> _selectedIds = {};

  void _setReady(String id, bool ready) {
    if (!mounted || !ready) return;
    // Virtualized tiles briefly report a pending frame when rebuilt. A photo
    // already decoded in this sheet must not lose its selection on scroll.
    if (_readyIds.add(id)) setState(() {});
  }

  void _toggle(String id) {
    if (!_readyIds.contains(id)) return;
    setState(() {
      if (!_selectedIds.add(id)) _selectedIds.remove(id);
    });
  }

  Widget _tile(BuildContext context, PhotoAsset asset) {
    final ready = _readyIds.contains(asset.id);
    final selected = _selectedIds.contains(asset.id);
    return Material(
      color: AppTheme.cardBg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('swipe-batch-${asset.id}'),
        onTap: ready ? () => _toggle(asset.id) : null,
        child: Stack(
          children: [
            Positioned.fill(
              child: AssetThumbnail(
                key: ValueKey('swipe-batch-preview-${asset.id}'),
                asset: asset,
                previewSize: 300,
                onPreviewReady: (value) => _setReady(asset.id, value),
              ),
            ),
            Positioned.directional(
              textDirection: Directionality.of(context),
              top: 4,
              start: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Checkbox(
                  value: selected,
                  onChanged: ready ? (_) => _toggle(asset.id) : null,
                ),
              ),
            ),
            Positioned.directional(
              textDirection: Directionality.of(context),
              bottom: 4,
              end: 4,
              child: IconButton.filledTonal(
                tooltip: context.l10n.scanZoomPreview,
                icon: const Icon(Icons.zoom_in_rounded),
                onPressed: () => showAssetPreview(context, asset),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    strings.swipeMultiSelectTitle,
                                    style: AppTheme.heading3,
                                  ),
                                ),
                                IconButton(
                                  tooltip: strings.swipeCancel,
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              strings.swipeGestureSafety,
                              style: AppTheme.caption,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: [
                                Text(
                                  strings.scanSelectedCount(
                                    _selectedIds.length,
                                  ),
                                ),
                                TextButton.icon(
                                  key: const ValueKey('swipe-select-loaded'),
                                  onPressed: _readyIds.isEmpty
                                      ? null
                                      : () => setState(
                                          () => _selectedIds.addAll(_readyIds),
                                        ),
                                  icon: const Icon(Icons.select_all_rounded),
                                  label: Text(strings.scanSelectLoaded),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: constraints.maxWidth >= 600 ? 5 : 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.8,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _tile(context, widget.assets[index]),
                          childCount: widget.assets.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('swipe-mark-selected'),
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () => Navigator.pop(
                          context,
                          widget.assets
                              .where(
                                (asset) =>
                                    _readyIds.contains(asset.id) &&
                                    _selectedIds.contains(asset.id),
                              )
                              .toList(),
                        ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(
                    strings.swipeMarkSelectedForDeletion(_selectedIds.length),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
