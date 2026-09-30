import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:cleanup_app/l10n/l10n.dart';

import '../../services/photo_scanner_service.dart';

String assetSizeLabel(PhotoAsset asset, {BuildContext? context}) {
  final strings = appStringsOf(context);
  if (!asset.sizeKnown) return strings.assetSizeUnknown;
  final bytes = asset.size;
  String decimal(double value, int digits) => NumberFormat(
    digits == 2 ? '0.00' : '0.0',
    strings.localeName,
  ).format(value);
  if (bytes >= 1073741824) {
    return strings.assetSizeGigabytes(decimal(bytes / 1073741824, 2));
  }
  if (bytes >= 1048576) {
    return strings.assetSizeMegabytes(decimal(bytes / 1048576, 1));
  }
  if (bytes >= 1024) {
    return strings.assetSizeKilobytes(decimal(bytes / 1024, 1));
  }
  return strings.assetSizeBytes(bytes);
}
