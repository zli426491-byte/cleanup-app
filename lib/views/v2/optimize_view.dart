import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:provider/provider.dart';

import '../../models/photo_asset.dart' show formatBytes;
import '../../services/photo_scanner_service.dart';
import '../../services/subscription_manager.dart';
import '../../utils/app_theme.dart';
import '../components/video_compression_view.dart';
import '../paywall/paywall_view.dart';
import '../scanner/asset_thumbnail.dart';
import 'cleanup_category.dart';
import 'ui_kit.dart';

/// "Optimize" tab: video compression entry.
class OptimizeTabView extends StatelessWidget {
  const OptimizeTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final videos = context.select<PhotoScannerService, List<PhotoAsset>>(
      (s) => s.scanResult.videos,
    );
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            Text(l10n.navOptimize, style: AppTheme.largeTitle),
            const SizedBox(height: 16),
            TintCard(
              key: const ValueKey('optimize-video-compress'),
              padding: const EdgeInsets.all(12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VideoCompressListView(),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.video_settings_rounded, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.v2VideoCompress,
                            style: AppTheme.heading2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 150,
                    child: Row(
                      children: [
                        for (var i = 0; i < 2; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ColoredBox(
                                    color: Colors.white,
                                    child: i < videos.length
                                        ? AssetThumbnail(
                                            asset: videos[i],
                                            previewSize: 300,
                                          )
                                        : const Icon(
                                            Icons.movie_rounded,
                                            size: 48,
                                            color: AppTheme.primaryMuted,
                                          ),
                                  ),
                                  if (i == 1 || videos.length < 2)
                                    PositionedDirectional(
                                      end: 8,
                                      bottom: 8,
                                      child: InfoPill(
                                        text: l10n.v2VideoCount(videos.length),
                                        detail: videos.isEmpty
                                            ? null
                                            : formatBytes(sumBytes(videos)),
                                        chevron: true,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
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
}

/// Videos sorted by size; tapping one opens the compression page (Pro).
class VideoCompressListView extends StatelessWidget {
  const VideoCompressListView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final videos = List.of(
      context.select<PhotoScannerService, List<PhotoAsset>>(
        (s) => s.scanResult.videos,
      ),
    )..sort((a, b) => b.size.compareTo(a.size));
    final total = sumBytes(videos);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PageTopBar(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.v2VideoCompress,
                            style: AppTheme.largeTitle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            total > 0
                                ? formatBytes(total)
                                : l10n.v2VideoCount(videos.length),
                            style: AppTheme.caption,
                          ),
                          const SizedBox(height: 16),
                          TintCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                const Icon(Icons.video_settings_rounded),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.v2VideoCompressBody,
                                    style: AppTheme.caption,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (videos.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          l10n.v2EmptyCategory,
                          style: AppTheme.heading2,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.82,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _VideoTile(asset: videos[i]),
                          childCount: videos.length,
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
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.asset});
  final PhotoAsset asset;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: asset.sizeKnown ? formatBytes(asset.size) : null,
    child: GestureDetector(
      onTap: () {
        final isPro = context.read<SubscriptionManager>().isPro;
        if (!isPro) {
          PaywallView.showUnlock(context, source: 'video_compress');
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VideoCompressionView(asset: asset)),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.r16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppTheme.primaryLight,
              child: AssetThumbnail(asset: asset, previewSize: 320),
            ),
            PositionedDirectional(
              end: 10,
              bottom: 10,
              child: InfoPill(
                text: asset.sizeKnown
                    ? formatBytes(asset.size)
                    : context.l10n.v2VideoCompress,
                chevron: true,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
