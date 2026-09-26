import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';

import '../../services/photo_scanner_service.dart';
import 'asset_thumbnail.dart';
import 'photo_asset_labels.dart';

/// A complete still-image preview. Grid cropping must not hide deletion context.
Future<void> showAssetPreview(BuildContext context, PhotoAsset asset) =>
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 720,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.65,
                  child: InteractiveViewer(
                    child: AssetThumbnail(
                      asset: asset,
                      previewSize: 1200,
                      fullImage: true,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  context.l10n.assetPreviewDetails(
                    asset.width,
                    asset.height,
                    assetSizeLabel(asset, context: context),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.scanBackToCompare),
              ),
            ],
          ),
        ),
      ),
    );
