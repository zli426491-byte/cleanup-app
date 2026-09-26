import '../../services/photo_scanner_service.dart';

String assetSizeLabel(PhotoAsset asset) {
  if (!asset.sizeKnown) return '容量未取得';
  final bytes = asset.size;
  if (bytes >= 1073741824) {
    return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
  }
  if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '$bytes bytes';
}
