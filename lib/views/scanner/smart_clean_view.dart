import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../../services/photo_scanner_service.dart';
import '../../services/subscription_manager.dart';
import '../../utils/app_theme.dart';
import '../paywall/paywall_view.dart';
import 'swipe_clean_view.dart';
import 'asset_thumbnail.dart';

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
  bool _isDeleting = false;

  static const _categories = ['照片', '待比較照片', '截圖', '影片', '高解析度照片'];
  static const _categoryIds = [
    'photos',
    'review',
    'screenshots',
    'videos',
    'highResolution',
  ];

  @override
  void initState() {
    super.initState();
    final index = _categoryIds.indexOf(widget.initialCategory);
    _selectedCategory = index < 0 ? 0 : index;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scanner = context.watch<PhotoScannerService>();
    if (!scanner.isScanning) {
      _selectedIds.retainAll(
        scanner.scanResult.allAssets.map((asset) => asset.id).toSet(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<PhotoScannerService>();
    final sub = context.watch<SubscriptionManager>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('智慧清理'),
        actions: [
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
          if (_selectedCategory == 3 && scanner.scanResult.videos.isNotEmpty)
            _videoSortBar(),
          const Divider(height: 16),
          if (!scanner.isScanning && scanner.scanNotice != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                scanner.scanNotice!,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ),
          if (!scanner.isScanning && _selectedCategory == 1)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '依拍攝時間、尺寸或名稱整理的待比較項目，尚未比對照片內容。請逐張確認後再選擇刪除。',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ),
          Expanded(
            child: scanner.scanResult.allAssets.isEmpty && !scanner.isScanning
                ? _emptyState(scanner)
                : scanner.isScanning
                ? _scanningState(scanner)
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
      height: 44,
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
          _sortChip('解析度', 0),
          const SizedBox(width: 6),
          _sortChip('最新', 1),
        ],
      ),
    );
  }

  Widget _sortChip(String label, int index) {
    final selected = _videoSort == index;
    return GestureDetector(
      onTap: () => setState(() => _videoSort = index),
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

    return Center(
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
              error ?? '整理照片、截圖與影片，逐張確認保留或刪除。本次最多讀取 900 個可存取項目。',
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
                  onTap: scanner.startFullScan,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    child: Text(
                      '開始掃描',
                      style: TextStyle(
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

  Widget _scanningState(PhotoScannerService scanner) {
    final phaseName = switch (scanner.currentPhase) {
      ScanPhase.fetchingAssets => '讀取相簿',
      ScanPhase.computingHashes => '分析項目',
      ScanPhase.findingDuplicates => '尋找重複照片',
      ScanPhase.findingSimilar => '尋找相似照片',
      ScanPhase.collectingScreenshots => '整理截圖',
      ScanPhase.findingLargeFiles => '尋找大型檔案',
      ScanPhase.scanningVideos => '整理影片',
      ScanPhase.done => '完成',
      ScanPhase.idle => '準備掃描',
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            phaseName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            '${(scanner.scanProgress * 100).clamp(0, 100).toInt()}%',
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              '本次最多讀取 900 個可存取項目，完成後請確認照片再刪除。',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(PhotoScannerService scanner) {
    final groups = _groupsFor(_selectedCategory, scanner);
    final assets = _assetsFor(_selectedCategory, scanner);

    if (groups.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 12),
        itemCount: groups.length,
        itemBuilder: (context, index) => _groupRow(groups[index]),
      );
    }

    if (assets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, size: 50, color: AppTheme.success),
            SizedBox(height: 12),
            Text(
              '已讀取的項目中沒有這個分類',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: assets.length,
      itemBuilder: (context, index) => _thumbnail(assets[index]),
    );
  }

  Widget _groupRow(DuplicateGroup group) {
    final candidates = group.assets;
    final candidateIds = candidates.map((asset) => asset.id).toSet();
    final allSelected = candidateIds.every(_selectedIds.contains);

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
          Row(
            children: [
              Text(
                '${group.assets.length} 張待比較照片',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                '請逐張確認',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() {
                  allSelected
                      ? _selectedIds.removeAll(candidateIds)
                      : _selectedIds.addAll(candidateIds);
                }),
                child: Icon(
                  allSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: group.assets.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final asset = group.assets[index];
                return _thumbnail(asset, compact: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbnail(
    PhotoAsset asset, {
    bool compact = false,
    bool locked = false,
  }) {
    final selected = _selectedIds.contains(asset.id);

    return GestureDetector(
      onTap: locked
          ? null
          : () => setState(() {
              selected
                  ? _selectedIds.remove(asset.id)
                  : _selectedIds.add(asset.id);
            }),
      child: Container(
        width: compact ? 80 : null,
        height: compact ? 80 : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(color: AppTheme.primary, width: 2.5)
              : locked
              ? Border.all(color: AppTheme.success, width: 2)
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
            if (locked)
              Positioned(
                top: 4,
                left: 4,
                child: _badge('保留', AppTheme.success),
              ),
            if (_selectedCategory == 4)
              Positioned(
                top: 4,
                left: 4,
                child: _badge(
                  '${asset.width} × ${asset.height}',
                  Colors.black54,
                ),
              ),
            if (!locked)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary
                        : Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 13)
                      : null,
                ),
              ),
          ],
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
              height: 48,
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
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '預覽並刪除 ${_selectedIds.length} 個項目',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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
      0 =>
        result.allAssets.where((asset) => asset.type == AssetType.image).length,
      1 => result.similarGroups.fold<int>(
        0,
        (sum, group) => sum + group.assets.length,
      ),
      2 => result.screenshots.length,
      3 => result.videos.length,
      4 => result.largeFiles.length,
      _ => 0,
    };
  }

  List<DuplicateGroup> _groupsFor(int category, PhotoScannerService scanner) {
    return category == 1
        ? scanner.scanResult.similarGroups
              .map((group) => DuplicateGroup(hash: '', assets: group.assets))
              .toList()
        : [];
  }

  List<PhotoAsset> _assetsFor(int category, PhotoScannerService scanner) {
    final result = scanner.scanResult;
    return switch (category) {
      0 =>
        result.allAssets
            .where((asset) => asset.type == AssetType.image)
            .toList(),
      1 => result.similarGroups.expand((group) => group.assets).toList(),
      2 => result.screenshots,
      3 => _sortedVideos(result.videos),
      4 => result.largeFiles,
      _ => [],
    };
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
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '共 ${toDelete.length} 個項目。請先確認縮圖再刪除，照片內容不會自動判定為重複。刪除後的空間以系統為準。',
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
