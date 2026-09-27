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

  /// Device capacity has not been supplied by a platform implementation.
  /// Zero values mean unknown and must never be displayed as measured storage.
  /// The UI uses the scanner's verified media byte count instead.
  static Future<StorageInfo> current() async => const StorageInfo(
    totalSpace: 0,
    usedSpace: 0,
    freeSpace: 0,
    isEstimate: true,
  );

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
