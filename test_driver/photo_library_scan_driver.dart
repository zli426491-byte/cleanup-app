import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// Host-side results from the actual simulator's integration binding. The
/// driver preserves failures and does not mock Photos, assert fake sizes, or
/// grant permission. --keep-app-running preserves the shared seed Documents.
Future<void> main() async {
  final resultPath = Platform.environment['CLEANUP_LIBRARY_RESULT_DIRECTORY'];
  final workload = int.tryParse(
    Platform.environment['CLEANUP_LIBRARY_WORKLOAD'] ?? '',
  );
  if (resultPath == null ||
      workload == null ||
      ![1000, 10000].contains(workload)) {
    throw StateError(
      'A real-library result directory and workload are required.',
    );
  }
  final resultDirectory = Directory(resultPath);
  await resultDirectory.create(recursive: true);
  await integrationDriver(
    timeout: const Duration(minutes: 15),
    writeResponseOnFailure: true,
    responseDataCallback: (data) async {
      await File(
        '${resultDirectory.path}/driver-response.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(data));
      final report = data?['libraryScan'];
      if (report is! Map ||
          report['workloadPhotos'] != workload ||
          report['actualFixtureCount'] != workload + workload ~/ 20 + 2 ||
          report['workloadShortVideos'] != workload ~/ 20 ||
          report['workloadLargeVideos'] != 2 ||
          report['usesRealPhotosLibrary'] != true ||
          report['usesRealFlutterScannerAndNativeBridge'] != true ||
          report['usesV2HomeScanStartAndResume'] != true ||
          report['v2NavigationReachesVerifiedResults'] != true ||
          report['usesMockChannelsOrFakeSizes'] != false ||
          report['exactDuplicatePairDetected'] != true ||
          report['differentPhotosNotGroupedWithExactPair'] != true ||
          report['largeMovieAbove64MiBDetectedWithExactBytes'] != true ||
          report['categoryEntryAutomaticallyVerified'] != true ||
          report['sizeOnlyPreservedHashes'] != true ||
          report['cancelAndResumeRecoveredMovies'] != true) {
        throw StateError(
          'The real simulator did not return its complete verified report.',
        );
      }
      await File(
        '${resultDirectory.path}/host-library-result.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(report));
    },
  );
}
