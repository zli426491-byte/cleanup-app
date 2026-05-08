import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/photo_scanner_service.dart';
import '../../utils/app_theme.dart';

/// Tinder-style swipe to delete/keep photos
class SwipeCleanView extends StatefulWidget {
  final List<PhotoAsset> assets;
  final String title;

  const SwipeCleanView({super.key, required this.assets, required this.title});

  @override
  State<SwipeCleanView> createState() => _SwipeCleanViewState();
}

class _SwipeCleanViewState extends State<SwipeCleanView> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final List<PhotoAsset> _toDelete = [];
  final List<PhotoAsset> _toKeep = [];

  // Drag state
  double _dragX = 0;
  double _dragY = 0;
  late AnimationController _animController;
  late Animation<double> _animX;
  late Animation<double> _animY;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
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
  PhotoAsset? get _currentAsset => _isDone ? null : widget.assets[_currentIndex];
  double get _progress => widget.assets.isEmpty ? 1.0 : _currentIndex / widget.assets.length;

  // Swipe direction indicator
  String get _swipeLabel {
    if (_dragX > 40) return '保留';
    if (_dragX < -40) return '刪除';
    return '';
  }

  Color get _swipeColor {
    if (_dragX > 40) return AppTheme.success;
    if (_dragX < -40) return AppTheme.danger;
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _showExitDialog(),
        ),
        actions: [
          TextButton(
            onPressed: _isDone ? null : () => _showResultDialog(),
            child: Text('完成 (${_toDelete.length})', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: _isDone ? _buildDoneView() : _buildSwipeView(),
    );
  }

  Widget _buildSwipeView() {
    final asset = _currentAsset!;
    final x = _isAnimating ? _animX.value : _dragX;
    final y = _isAnimating ? _animY.value : _dragY;
    final angle = x / 800;

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text('${_currentIndex + 1}/${widget.assets.length}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 4,
                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statChip(Icons.delete_rounded, '${_toDelete.length} 刪除', AppTheme.danger),
              const SizedBox(width: 12),
              _statChip(Icons.favorite_rounded, '${_toKeep.length} 保留', AppTheme.success),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Card stack
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Next card (background)
              if (_currentIndex + 1 < widget.assets.length)
                _buildCard(widget.assets[_currentIndex + 1], isBackground: true),

              // Current card (draggable)
              GestureDetector(
                onPanStart: (_) => setState(() => _isAnimating = false),
                onPanUpdate: (d) => setState(() {
                  _dragX += d.delta.dx;
                  _dragY += d.delta.dy * 0.3;
                }),
                onPanEnd: (_) => _onDragEnd(),
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(x, y),
                    child: Transform.rotate(
                      angle: angle,
                      child: Stack(
                        children: [
                          _buildCard(asset, isBackground: false),
                          // Swipe label overlay
                          if (_swipeLabel.isNotEmpty)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(color: _swipeColor, width: 4),
                                ),
                                child: Center(
                                  child: Transform.rotate(
                                    angle: _dragX > 0 ? -0.3 : 0.3,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: _swipeColor, width: 3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(_swipeLabel,
                                          style: TextStyle(color: _swipeColor,
                                              fontSize: 32, fontWeight: FontWeight.w900)),
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
          padding: const EdgeInsets.fromLTRB(40, 12, 40, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Delete button
              _actionButton(
                icon: Icons.close_rounded,
                color: AppTheme.danger,
                size: 64,
                onTap: () => _swipeAway(-1),
              ),
              // Undo button
              _actionButton(
                icon: Icons.undo_rounded,
                color: AppTheme.warning,
                size: 48,
                onTap: _undo,
              ),
              // Keep button
              _actionButton(
                icon: Icons.favorite_rounded,
                color: AppTheme.success,
                size: 64,
                onTap: () => _swipeAway(1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(PhotoAsset asset, {required bool isBackground}) {
    return Container(
      width: MediaQuery.of(context).size.width - 48,
      height: MediaQuery.of(context).size.height * 0.52,
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
                child: asset.thumbnail != null
                    ? Image.memory(asset.thumbnail!, fit: BoxFit.cover)
                    : Center(child: Icon(Icons.image_rounded, size: 60, color: Colors.grey[300])),
              ),
            ),
            // Info bar
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatSize(asset.size),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
                      const SizedBox(height: 2),
                      Text('${asset.width} × ${asset.height}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      '${asset.createDate.month}/${asset.createDate.day}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600),
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

  Widget _actionButton({required IconData icon, required Color color, required double size, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.4),
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
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
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
      setState(() { _dragX = 0; _dragY = 0; });
    }
  }

  void _swipeAway(int direction) {
    if (_isDone) return;

    final asset = _currentAsset!;
    if (direction > 0) {
      _toKeep.add(asset);
    } else {
      _toDelete.add(asset);
    }

    _animX = Tween<double>(begin: _dragX, end: direction * 500.0)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animY = Tween<double>(begin: _dragY, end: _dragY - 50)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _isAnimating = true;
    _animController.forward();
  }

  void _undo() {
    if (_currentIndex == 0) return;
    setState(() {
      _currentIndex--;
      final asset = widget.assets[_currentIndex];
      _toDelete.remove(asset);
      _toKeep.remove(asset);
    });
  }

  // --- Done ---

  Widget _buildDoneView() {
    final totalBytes = _toDelete.fold<int>(0, (s, a) => s + a.size);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [AppTheme.colorShadow(AppTheme.primary)],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('審核完成！', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            Text('${_toDelete.length} 張要刪除 · ${_toKeep.length} 張保留',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
            const SizedBox(height: 4),
            Text('可釋放 ${_formatSize(totalBytes)}',
                style: const TextStyle(color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 32),
            // Delete button
            Container(
              width: double.infinity, height: 52,
              decoration: BoxDecoration(gradient: AppTheme.dangerGradient, borderRadius: BorderRadius.circular(50),
                boxShadow: [AppTheme.colorShadow(AppTheme.danger)]),
              child: Material(color: Colors.transparent, child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () async {
                  final scanner = context.read<PhotoScannerService>();
                  await scanner.deleteAssets(_toDelete);
                  if (mounted) Navigator.pop(context, _toDelete.length);
                },
                child: Center(child: Text('刪除 ${_toDelete.length} 張照片',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
              )),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context, 0),
              child: const Text('返回', style: TextStyle(color: AppTheme.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('確定離開？'),
      content: Text('你已標記 ${_toDelete.length} 張照片要刪除，離開將不會執行。'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('繼續審核')),
        TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
            child: const Text('離開', style: TextStyle(color: AppTheme.danger))),
      ],
    ));
  }

  void _showResultDialog() {
    final remaining = widget.assets.length - _currentIndex;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('跳過剩餘照片？'),
      content: Text('還有 $remaining 張未審核，要直接刪除已標記的 ${_toDelete.length} 張嗎？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('繼續審核')),
        TextButton(onPressed: () { Navigator.pop(ctx); setState(() => _currentIndex = widget.assets.length); },
            child: const Text('完成', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700))),
      ],
    ));
  }

  String _formatSize(int b) {
    if (b < 1024) return '$b B';
    if (b < 1048576) return '${(b / 1024).toStringAsFixed(1)} KB';
    if (b < 1073741824) return '${(b / 1048576).toStringAsFixed(1)} MB';
    return '${(b / 1073741824).toStringAsFixed(1)} GB';
  }
}
