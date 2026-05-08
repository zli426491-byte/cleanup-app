import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/photo_scanner_service.dart';
import '../../services/subscription_manager.dart';
import '../../utils/app_theme.dart';
import '../paywall/paywall_view.dart';
import 'swipe_clean_view.dart';

class SmartCleanView extends StatefulWidget {
  const SmartCleanView({super.key});

  @override
  State<SmartCleanView> createState() => _SmartCleanViewState();
}

class _SmartCleanViewState extends State<SmartCleanView> {
  int _selectedCategory = 0;
  final Set<String> _selectedIds = {};
  int _videoSort = 0; // 0=大小, 1=日期, 2=時長

  final _categories = ['重複照片', '相似照片', '螢幕截圖', '影片', '模糊照片', '大型檔案'];

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<PhotoScannerService>();
    final sub = context.watch<SubscriptionManager>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('智慧清理'),
        actions: [
          // Swipe mode button
          if (scanner.scanResult.allAssets.isNotEmpty)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.swipe_rounded, color: Colors.white, size: 16),
              ),
              onPressed: () => _openSwipeMode(scanner),
              tooltip: '滑動模式',
            ),
        ],
      ),
      body: Column(
        children: [
          // Category chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (ctx, i) {
                final count = _countFor(i, scanner);
                final selected = _selectedCategory == i;
                return GestureDetector(
                  onTap: () => setState(() { _selectedCategory = i; _selectedIds.clear(); }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      border: selected ? null : Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_categories[i],
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : AppTheme.textSecondary)),
                        if (count > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: selected ? Colors.white.withValues(alpha: 0.25) : AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(50)),
                            child: Text('$count',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                    color: selected ? Colors.white : AppTheme.primary)),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Video sort buttons (only for video category)
          if (_selectedCategory == 3 && scanner.scanResult.videos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _sortChip('最大', 0), const SizedBox(width: 6),
                  _sortChip('最新', 1), const SizedBox(width: 6),
                  _sortChip('最長', 2),
                ],
              ),
            ),

          const Divider(height: 16),

          // Content
          Expanded(
            child: scanner.scanResult.allAssets.isEmpty && !scanner.isScanning
                ? _emptyState(scanner)
                : scanner.isScanning
                    ? _scanningState(scanner)
                    : _content(scanner),
          ),

          // Bottom bar
          if (scanner.scanResult.allAssets.isNotEmpty && _selectedIds.isNotEmpty)
            _bottomBar(scanner, sub),
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
          color: selected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: selected ? AppTheme.primary : AppTheme.textMuted)),
      ),
    );
  }

  Widget _emptyState(PhotoScannerService scanner) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
        child: const Icon(Icons.search_rounded, size: 36, color: AppTheme.primary),
      ),
      const SizedBox(height: 20),
      const Text('尚無掃描結果', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      const SizedBox(height: 6),
      const Text('執行智慧掃描來找出可清理的項目', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
      const SizedBox(height: 24),
      Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(50)),
        child: Material(color: Colors.transparent, child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () => scanner.startFullScan(),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            child: Text('開始掃描', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        )),
      ),
    ]),
  );

  Widget _scanningState(PhotoScannerService scanner) {
    final names = {'fetchingAssets':'讀取照片','computingHashes':'分析照片','findingDuplicates':'尋找重複照片','findingSimilar':'尋找相似照片','collectingScreenshots':'偵測截圖','findingLargeFiles':'尋找大檔','scanningVideos':'掃描影片','done':'完成'};
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.primary)),
      const SizedBox(height: 20),
      Text(names[scanner.currentPhase.name] ?? '掃描中...', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      const SizedBox(height: 8),
      Text('${(scanner.scanProgress * 100).toInt()}%', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 18)),
    ]));
  }

  Widget _content(PhotoScannerService scanner) {
    final groups = _groupsFor(_selectedCategory, scanner);
    final assets = _assetsFor(_selectedCategory, scanner);

    if (groups.isNotEmpty && _selectedCategory == 0) {
      return ListView.builder(
        itemCount: groups.length,
        itemBuilder: (ctx, i) => _groupRow(groups[i]),
      );
    }

    if (assets.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.check_circle_rounded, size: 50, color: AppTheme.success.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        const Text('沒有找到相關項目', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
      ]));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
      itemCount: assets.length,
      itemBuilder: (ctx, i) => _thumbnail(assets[i]),
    );
  }

  Widget _groupRow(DuplicateGroup group) {
    final bestId = group.assets.first.id;
    final candidates = group.assets.sublist(1);
    final savable = candidates.fold<int>(0, (s, a) => s + a.size);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [AppTheme.softShadow]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${group.assets.length} 張照片', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(50)),
            child: Text(_fmt(savable), style: const TextStyle(fontSize: 10, color: AppTheme.danger, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() {
              final ids = candidates.map((a) => a.id).toSet();
              ids.every(_selectedIds.contains) ? _selectedIds.removeAll(ids) : _selectedIds.addAll(ids);
            }),
            child: Icon(
              candidates.every((a) => _selectedIds.contains(a.id)) ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: AppTheme.primary, size: 22),
          ),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: group.assets.length,
            separatorBuilder: (context, index) => const SizedBox(width: 6),
            itemBuilder: (ctx, i) {
              final asset = group.assets[i];
              final isBest = asset.id == bestId;
              final selected = _selectedIds.contains(asset.id);
              return GestureDetector(
                onTap: isBest ? null : () => setState(() {
                  selected ? _selectedIds.remove(asset.id) : _selectedIds.add(asset.id);
                }),
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: selected ? Border.all(color: AppTheme.primary, width: 2)
                        : isBest ? Border.all(color: AppTheme.success, width: 2) : null,
                    color: Colors.grey[100],
                  ),
                  child: Stack(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(13),
                      child: asset.thumbnail != null
                          ? Image.memory(asset.thumbnail!, fit: BoxFit.cover, width: 80, height: 80)
                          : const Center(child: Icon(Icons.image, color: Colors.grey))),
                    if (isBest)
                      Positioned(top: 4, left: 4, child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.success, borderRadius: BorderRadius.circular(6)),
                        child: const Text('最佳', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                      )),
                    if (!isBest)
                      Positioned(bottom: 4, right: 4, child: Icon(
                        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                        color: selected ? AppTheme.primary : Colors.white70, size: 18)),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _thumbnail(PhotoAsset asset) {
    final selected = _selectedIds.contains(asset.id);
    return GestureDetector(
      onTap: () => setState(() { selected ? _selectedIds.remove(asset.id) : _selectedIds.add(asset.id); }),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: selected ? Border.all(color: AppTheme.primary, width: 2.5) : null,
          color: Colors.grey[100],
        ),
        child: Stack(fit: StackFit.expand, children: [
          ClipRRect(borderRadius: BorderRadius.circular(13),
            child: asset.thumbnail != null
                ? Image.memory(asset.thumbnail!, fit: BoxFit.cover)
                : const Center(child: Icon(Icons.image, color: Colors.grey))),
          Positioned(bottom: 4, right: 4, child: Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: selected ? AppTheme.primary : Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle),
            child: selected ? const Icon(Icons.check, color: Colors.white, size: 13) : null,
          )),
          // Size label for videos/large files
          if (_selectedCategory == 3 || _selectedCategory == 5)
            Positioned(top: 4, left: 4, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
              child: Text(_fmt(asset.size), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w600)),
            )),
        ]),
      ),
    );
  }

  Widget _bottomBar(PhotoScannerService scanner, SubscriptionManager sub) => Container(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
    decoration: BoxDecoration(color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4))]),
    child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('已選擇 ${_selectedIds.length} 個項目',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Container(
        width: double.infinity, height: 48,
        decoration: BoxDecoration(gradient: AppTheme.dangerGradient, borderRadius: BorderRadius.circular(50)),
        child: Material(color: Colors.transparent, child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () => _handleDelete(scanner, sub),
          child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.delete_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text('刪除 ${_selectedIds.length} 個項目', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          ])),
        )),
      ),
    ])),
  );

  // --- Data helpers ---

  int _countFor(int cat, PhotoScannerService s) {
    final r = s.scanResult;
    switch (cat) {
      case 0: return r.duplicateGroups.fold<int>(0, (a, g) => a + g.assets.length);
      case 1: return r.similarGroups.fold<int>(0, (a, g) => a + g.assets.length);
      case 2: return r.screenshots.length;
      case 3: return r.videos.length;
      case 4: return r.blurryPhotos.length;
      case 5: return r.largeFiles.length;
      default: return 0;
    }
  }

  List<DuplicateGroup> _groupsFor(int cat, PhotoScannerService s) {
    if (cat == 0) return s.scanResult.duplicateGroups;
    return [];
  }

  List<PhotoAsset> _assetsFor(int cat, PhotoScannerService s) {
    final r = s.scanResult;
    switch (cat) {
      case 0: return r.duplicateGroups.expand((g) => g.assets.skip(1)).toList();
      case 1: return r.similarGroups.expand((g) => g.assets).toList();
      case 2: return r.screenshots;
      case 3: return _sortedVideos(r.videos);
      case 4: return r.blurryPhotos;
      case 5: return r.largeFiles;
      default: return [];
    }
  }

  List<PhotoAsset> _sortedVideos(List<PhotoAsset> videos) {
    final sorted = List<PhotoAsset>.from(videos);
    switch (_videoSort) {
      case 0: sorted.sort((a, b) => b.size.compareTo(a.size)); // Largest first
      case 1: sorted.sort((a, b) => b.createDate.compareTo(a.createDate)); // Newest
      case 2: sorted.sort((a, b) => b.size.compareTo(a.size)); // Duration (approx by size)
    }
    return sorted;
  }

  void _openSwipeMode(PhotoScannerService scanner) {
    final assets = _assetsFor(_selectedCategory, scanner);
    if (assets.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => SwipeCleanView(assets: assets, title: _categories[_selectedCategory]),
    ));
  }

  void _handleDelete(PhotoScannerService scanner, SubscriptionManager sub) {
    if (!sub.isPro) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PaywallView()),
      );
      return;
    }

    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('刪除照片'),
      content: Text('將 ${_selectedIds.length} 個項目移至「最近刪除」？\n你可以在 30 天內復原。'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        TextButton(onPressed: () async {
          Navigator.pop(ctx);
          final toDelete = scanner.scanResult.allAssets.where((a) => _selectedIds.contains(a.id)).toList();
          await scanner.deleteAssets(toDelete);
          if (!mounted) return;
          setState(() => _selectedIds.clear());
        }, child: const Text('刪除', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700))),
      ],
    ));
  }

  String _fmt(int b) {
    if (b < 1024) return '$b B';
    if (b < 1048576) return '${(b / 1024).toStringAsFixed(1)} KB';
    if (b < 1073741824) return '${(b / 1048576).toStringAsFixed(1)} MB';
    return '${(b / 1073741824).toStringAsFixed(1)} GB';
  }
}
