import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../../services/photo_scanner_service.dart';
import '../../services/subscription_manager.dart';
import '../../utils/app_theme.dart';
import '../paywall/paywall_view.dart';
import '../components/video_compression_view.dart';
import 'swipe_clean_view.dart';
import 'asset_thumbnail.dart';
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
  final Set<String> _selectedIds = {};
  final Set<String> _dismissedSuggestions = {};
  bool _isDeleting = false;
  ScanResult? _cachedResult;
  ScanResult? _selectionSource;
  final Map<int, List<PhotoAsset>> _cachedAssets = {};

  static const _categories = ['照片', '真重複', '視覺相似', '截圖', '影片', '大檔'];
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

  @override
  Widget build(BuildContext context) {
    context.select<PhotoScannerService, Object>(
      (scanner) => (scanner.scanResult, scanner.isScanning, scanner.isDeleting),
    );
    final scanner = context.read<PhotoScannerService>();
    _updateSnapshot(scanner);
    final sub = context.watch<SubscriptionManager>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('智慧清理'),
        actions: [
          if (scanner.isScanning)
            IconButton(
              tooltip: '取消掃描並保留進度',
              icon: const Icon(Icons.stop_circle_outlined),
              onPressed: scanner.cancelScan,
            ),
          if (scanner.scanResult.allAssets.isNotEmpty)
            IconButton(
              tooltip: '滑動清理',
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.swipe_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              onPressed: scanner.isScanning || scanner.isDeleting || _isDeleting
                  ? null
                  : () => _openSwipeMode(scanner),
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
    );
  }

  Widget _categoryBar(PhotoScannerService scanner) {
    return SizedBox(
      height: 44 + (MediaQuery.textScalerOf(context).scale(12) - 12) * 2,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final selected = _selectedCategory == index;
          final count = _countFor(index, scanner);

          return GestureDetector(
            onTap: () => setState(() {
              _selectedCategory = index;
              _selectedIds.clear();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: selected
                    ? null
                    : Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _categories[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
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
                          color: selected ? Colors.white : AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _videoSortBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _sortChip('檔案容量', 0),
          const SizedBox(width: 6),
          _sortChip('最新', 1),
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
              error == null ? '開始掃描相簿' : '掃描未完成',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error ?? '掃描全部可存取的照片與影片，以檔案內容確認真重複，再找出視覺相似照片。請逐張確認後決定。',
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
                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    child: Text(
                      scanner.wasCancelled ? '繼續掃描' : '開始掃描',
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (scanner.isScanning) ...[
                      ScanProgressPanel(scanner: scanner, compact: true),
                      const SizedBox(height: 12),
                      const Text(
                        '照片與截圖可先預覽；掃描期間暫停選取、刪除及影片壓縮。',
                        style: AppTheme.caption,
                      ),
                    ],
                    if (scanner.scanNotice != null)
                      Text(scanner.scanNotice!, style: AppTheme.caption),
                    Text(
                      _selectedCategory == 1
                          ? '真重複僅包括已完成原始素材驗證的項目，其餘不會推定重複。保留建議可撤回。'
                          : _selectedCategory == 2
                          ? '視覺相似依已完成的本機畫面分析逐步整理，內容可能不同。保留建議僅供參考。'
                          : _selectedCategory == 5
                          ? '依已取得的原始檔案容量排序。這是檔案大小，實際回收空間以系統為準。'
                          : '只會刪除你手動勾選並再次確認的項目。',
                      style: AppTheme.caption,
                    ),
                    if (!scanner.isScanning && scanner.pendingResourceCount > 0)
                      TextButton.icon(
                        onPressed: scanner.isDeleting
                            ? null
                            : scanner.verifyOriginals,
                        icon: const Icon(Icons.verified_outlined),
                        label: const Text('驗證本機原始素材：確認真重複與容量'),
                      ),
                    if (!scanner.isScanning &&
                        (scanner.wasCancelled ||
                            scanner.pendingAnalysisCount > 0))
                      TextButton.icon(
                        onPressed: scanner.isDeleting
                            ? null
                            : scanner.resumeScan,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('繼續掃描／重試待處理項目'),
                      ),
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
                    (context, index) => _thumbnail(assets[index]),
                    childCount: assets.length,
                  ),
                ),
              )
            else
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

  Widget _groupRow(_ReviewGroup group) {
    final suggested = !_dismissedSuggestions.contains(group.key)
        ? group.bestAssetId
        : null;
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final tileWidth = 112 * textScale.clamp(1.0, 1.5);
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
            '${group.assets.length} 張${_selectedCategory == 1 ? '真重複' : '視覺相似'}照片',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (group.bestAssetId != null) ...[
            if (suggested != null)
              Text(
                '建議保留：${group.bestReason ?? '此張照片在這組中較適合保留。'}',
                style: AppTheme.caption,
              ),
            TextButton(
              onPressed: () => setState(() {
                suggested == null
                    ? _dismissedSuggestions.remove(group.key)
                    : _dismissedSuggestions.add(group.key);
              }),
              child: Text(suggested == null ? '重新顯示保留建議' : '撤回保留建議'),
            ),
          ],
          const Text('保留建議不會自動勾選；點選縮圖標記刪除。', style: AppTheme.caption),
          const SizedBox(height: 10),
          SizedBox(
            height: tileWidth + 52 * textScale,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: group.assets.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) => SizedBox(
                width: tileWidth,
                child: _thumbnail(
                  group.assets[index],
                  recommended: suggested == group.assets[index].id,
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
        scanner.pendingResourceCount > 0) {
      return '尚有原始素材待驗證，目前不能判定是否有真重複或大型檔案。照片與截圖可先預覽。';
    }
    if (_selectedCategory == 2 && scanner.pendingAnalysisCount > 0) {
      return '照片畫面仍有待處理項目，視覺相似結果會逐步整理。照片與截圖可先預覽。';
    }
    if (scanner.isScanning &&
        scanner.currentPhase == ScanPhase.fetchingAssets) {
      return '相簿目錄仍在讀取，此分類將隨讀取進度更新。';
    }
    return '目前已完成分析或驗證的項目中沒有這個分類。';
  }

  Widget _thumbnail(PhotoAsset asset, {bool recommended = false}) {
    final scanner = context.read<PhotoScannerService>();
    final selected = _selectedIds.contains(asset.id);
    return GestureDetector(
      key: ValueKey('select-${asset.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: scanner.isScanning || scanner.isDeleting
          ? null
          : () => setState(() {
              selected
                  ? _selectedIds.remove(asset.id)
                  : _selectedIds.add(asset.id);
            }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: selected
                    ? Border.all(color: AppTheme.danger, width: 2.5)
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
                    Positioned(
                      top: 4,
                      left: 4,
                      right: 4,
                      child: _badge('建議保留', AppTheme.success),
                    ),
                  if (!scanner.isScanning)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: selected ? AppTheme.danger : Colors.white,
                        size: 24,
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: IconButton(
                      tooltip: '放大預覽',
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
                  assetSizeLabel(asset),
                  style: const TextStyle(fontSize: 11),
                  maxLines: 2,
                ),
              ),
              if (asset.type == AssetType.video)
                IconButton(
                  tooltip: '壓縮此影片',
                  icon: const Icon(Icons.compress_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: scanner.isScanning || scanner.isDeleting
                      ? null
                      : () => _openCompression(asset),
                ),
            ],
          ),
          if (asset.analysisPending)
            const Text(
              '內容待分析',
              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            ),
        ],
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

  void _previewAsset(PhotoAsset asset) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 720,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: InteractiveViewer(
                    child: AssetThumbnail(asset: asset, previewSize: 1200),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '${asset.width} × ${asset.height} · ${assetSizeLabel(asset)}',
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('返回繼續比較'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(PhotoScannerService scanner, SubscriptionManager sub) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
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
              '已選擇 ${_selectedIds.length} 個項目',
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
                        const Icon(
                          Icons.visibility_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '預覽並刪除 ${_selectedIds.length} 個項目',
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
    if (scanner.isScanning || scanner.isDeleting || _isDeleting) return;
    final assets = _assetsFor(_selectedCategory, scanner);
    if (assets.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SwipeCleanView(
          assets: assets,
          title: _categories[_selectedCategory],
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
        title: const Text('確認要刪除這些項目嗎？'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '共 ${toDelete.length} 個項目。請確認選取內容與保留建議後再刪除；實際回收空間以系統為準。',
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
            child: const Text('取消'),
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
                        ? '未刪除任何項目，可能已取消或刪除未成功。'
                        : '已刪除 ${deletedIds.length} 個項目。',
                  ),
                ),
              );
            },
            child: const Text(
              '確認刪除',
              style: TextStyle(
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
