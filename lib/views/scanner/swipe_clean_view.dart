import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:provider/provider.dart';
import '../../services/photo_scanner_service.dart';
import '../../services/subscription_manager.dart';
import '../../utils/app_theme.dart';
import '../paywall/paywall_view.dart';
import 'asset_thumbnail.dart';
import 'asset_preview.dart';
import 'photo_asset_labels.dart';

/// Tinder-style swipe to delete/keep photos
class SwipeCleanView extends StatefulWidget {
  final List<PhotoAsset> assets;
  final String title;
  final String? categoryId;

  const SwipeCleanView({
    super.key,
    required this.assets,
    required this.title,
    this.categoryId,
  });

  @override
  State<SwipeCleanView> createState() => _SwipeCleanViewState();
}

class _SwipeCleanViewState extends State<SwipeCleanView>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
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
  int _deletedCount = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _dragX = 0;
          _dragY = 0;
          _isAnimating = false;
          _currentIndex++;
        });
        _animController.reset();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool get _isDone => _currentIndex >= widget.assets.length;
  PhotoAsset? get _currentAsset =>
      _isDone ? null : widget.assets[_currentIndex];
  double get _progress =>
      widget.assets.isEmpty ? 1.0 : _currentIndex / widget.assets.length;

  // Swipe direction indicator
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
        backgroundColor: const Color(0xFFF6F8FC),
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
              tooltip: context.l10n.swipeGestureHelp,
              icon: const Icon(Icons.help_outline_rounded),
              onPressed: _showGestureHelp,
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
          child: _isDone ? _buildDoneView() : _buildSwipeView(),
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
                        widget.assets.length,
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
                      Icons.favorite_rounded,
                      context.l10n.swipeKeepCount(_toKeep.length),
                      AppTheme.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card stack
              SizedBox(
                height: 360,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Next card (background)
                    if (_currentIndex + 1 < widget.assets.length)
                      ExcludeSemantics(
                        child: IgnorePointer(
                          child: _buildCard(
                            widget.assets[_currentIndex + 1],
                            isBackground: true,
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
                      onHorizontalDragEnd: (_) => _onDragEnd(),
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
                                _buildCard(asset, isBackground: false),
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

              // Bottom buttons
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 24),
                child: Row(
                  textDirection: TextDirection.ltr,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Delete button
                    _actionButton(
                      icon: Icons.close_rounded,
                      label: context.l10n.swipeDelete,
                      color: AppTheme.danger,
                      size: 64,
                      onTap:
                          _isAnimating || !_previewReadyIds.contains(asset.id)
                          ? null
                          : () => _swipeAway(-1),
                    ),
                    // Undo button
                    _actionButton(
                      icon: Icons.undo_rounded,
                      label: context.l10n.swipeUndoChoice,
                      color: AppTheme.warning,
                      size: 48,
                      onTap: _isAnimating || _reviewHistory.isEmpty
                          ? null
                          : _undo,
                    ),
                    // Keep button
                    _actionButton(
                      icon: Icons.favorite_rounded,
                      label: context.l10n.swipeKeep,
                      color: AppTheme.success,
                      size: 64,
                      onTap: _isAnimating ? null : () => _swipeAway(1),
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
      ],
    ),
  );

  void _showGestureHelp() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _gestureGuide(expanded: true),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.swipeContinueReview),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(PhotoAsset asset, {required bool isBackground}) {
    return Container(
      width: (MediaQuery.of(context).size.width - 48).clamp(200, 600),
      height: 360,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              assetSizeLabel(asset, context: context),
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

  void _onDragEnd() {
    if (_dragX.abs() > 100) {
      _swipeAway(_dragX > 0 ? 1 : -1);
    } else {
      // Snap back
      setState(() {
        _dragX = 0;
        _dragY = 0;
      });
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
      final asset = widget.assets[_currentIndex];
      _toDelete.remove(asset);
      _toKeep.remove(asset);
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
              onPressed:
                  _isDeleting || _deletedCount > 0 || _reviewHistory.isEmpty
                  ? null
                  : _undo,
              icon: const Icon(Icons.undo_rounded),
              label: Text(context.l10n.swipeUndoChoice),
            ),
            // Delete button
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
                      context.l10n.swipeDeletePhotos(_toDelete.length),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.swipeConfirmDeleteTitle),
        content: Text(
          context.l10n.swipeConfirmDeleteDescription(_toDelete.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.swipeCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.swipeConfirmDelete),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    if (!sub.isPro || _isDeleting || scanner.isScanning || scanner.isDeleting) {
      return;
    }
    setState(() => _isDeleting = true);
    final requested = _toDelete.length;
    final deletedIds = await scanner.deleteAssetsWithResult(_toDelete);
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

  void _leave() {
    if (_isDeleting) return;
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
    final remaining = widget.assets.length - _currentIndex;
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
              setState(() => _currentIndex = widget.assets.length);
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
