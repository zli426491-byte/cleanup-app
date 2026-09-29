import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'photo_asset.dart' show formatBytes;

class StorageInfo {
  final int totalSpace;
  final int usedSpace;
  final int freeSpace;
  final bool isEstimate;

  const StorageInfo({
    required this.totalSpace,
    required this.usedSpace,
    required this.freeSpace,
    this.isEstimate = false,
  });

  /// Usage ratio from 0.0 (empty) to 1.0 (full).
  double get usedPercentage =>
      totalSpace > 0 ? (usedSpace / totalSpace).clamp(0.0, 1.0) : 0.0;

  /// Usage as a display-friendly percentage string (e.g. "73.2%").
  String get usedPercentageFormatted =>
      '${(usedPercentage * 100).toStringAsFixed(1)}%';

  String get totalSpaceFormatted => formatBytes(totalSpace);
  String get usedSpaceFormatted => formatBytes(usedSpace);
  String get freeSpaceFormatted => formatBytes(freeSpace);

  /// Label suffix shown in UI when data is estimated (not real disk info).
  String get estimateLabel => isEstimate ? ' (估計值)' : '';

  static const unknown = StorageInfo(
    totalSpace: 0,
    usedSpace: 0,
    freeSpace: 0,
    isEstimate: true,
  );

  static const _channel = MethodChannel('cleanup/photo_resources');

  /// Device capacity from iOS volume resource values. Any other platform, or a
  /// failed lookup, returns [unknown]: zero values must never be displayed as
  /// measured storage.
  static Future<StorageInfo> current() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return unknown;
    try {
      final values = await _channel
          .invokeMapMethod<String, Object?>('deviceStorage', const {})
          .timeout(const Duration(seconds: 3));
      final total = (values?['total'] as num?)?.toInt() ?? 0;
      final free = (values?['free'] as num?)?.toInt() ?? -1;
      if (total <= 0 || free < 0 || free > total) return unknown;
      return StorageInfo(
        totalSpace: total,
        usedSpace: total - free,
        freeSpace: free,
      );
    } catch (_) {
      return unknown;
    }
  }

  StorageInfo copyWith({
    int? totalSpace,
    int? usedSpace,
    int? freeSpace,
    bool? isEstimate,
  }) {
    return StorageInfo(
      totalSpace: totalSpace ?? this.totalSpace,
      usedSpace: usedSpace ?? this.usedSpace,
      freeSpace: freeSpace ?? this.freeSpace,
      isEstimate: isEstimate ?? this.isEstimate,
    );
  }

  @override
  String toString() =>
      'StorageInfo(total: $totalSpaceFormatted, used: $usedSpaceFormatted '
      '[$usedPercentageFormatted], free: $freeSpaceFormatted)';
}
