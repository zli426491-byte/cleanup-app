import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cleanup_app/services/photo_content_analysis.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List encoded(img.Image image) => Uint8List.fromList(img.encodePng(image));

img.Image scene({int seed = 1, int exposure = 0, int shift = 0}) {
  final image = img.Image(width: 192, height: 128);
  final random = math.Random(seed);
  final shapes = List.generate(
    24,
    (_) => [
      random.nextInt(160),
      random.nextInt(105),
      8 + random.nextInt(25),
      random.nextInt(220),
      random.nextInt(220),
      random.nextInt(220),
    ],
  );
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final sx = x - shift;
      var r = 60 + sx ~/ 5;
      var g = 80 + y ~/ 3;
      var b = 170 - y ~/ 2;
      for (final shape in shapes) {
        if (sx >= shape[0] &&
            sx < shape[0] + shape[2] &&
            y >= shape[1] &&
            y < shape[1] + shape[2]) {
          r = shape[3];
          g = shape[4];
          b = shape[5];
        }
      }
      image.setPixelRgb(
        x,
        y,
        (r + exposure).clamp(0, 255),
        (g + exposure).clamp(0, 255),
        (b + exposure).clamp(0, 255),
      );
    }
  }
  return image;
}

AnalyzedPhoto photo(String id, ContentSignature? signature) => AnalyzedPhoto(
  id: id,
  width: 3000,
  height: 2000,
  createDate: DateTime(2026, 9, 26, 12),
  signature: signature,
);

void main() {
  test(
    '16-bit channels and invisible transparent colors are handled safely',
    () {
      final source = scene();
      final highDepth = source.convert(format: img.Format.uint16);
      final standard = analyzePhotoThumbnail(encoded(source));
      final converted = analyzePhotoThumbnail(encoded(highDepth));
      expect(converted.isValid, isTrue);
      expect(converted.brightness, closeTo(standard.brightness, 0.002));
      expect(visualDistance(standard, converted), lessThanOrEqualTo(3));
      final transparent = img.Image(width: 96, height: 96, numChannels: 4);
      for (var y = 0; y < 96; y++) {
        for (var x = 0; x < 96; x++) {
          transparent.setPixelRgba(x, y, x * 2, y * 2, 100, 0);
        }
      }
      final invisible = analyzePhotoThumbnail(encoded(transparent));
      expect(invisible.isLowInformation, isTrue);
      expect(visualDistance(invisible, standard), isNull);
    },
  );

  test('malformed persisted features cannot enter visual groups', () {
    final original = analyzePhotoThumbnail(encoded(scene()));
    final poisoned = ContentSignature.fromMap({
      ...original.toMap(),
      'spatialLuminance': List<double>.filled(64, double.nan),
    });
    expect(visualDistance(original, poisoned), isNull);
    expect(
      groupSimilarPhotos([photo('good', original), photo('bad', poisoned)]),
      isEmpty,
    );
  });

  test('broken and tiny images provide no similarity or quality evidence', () {
    for (final bytes in [
      Uint8List(0),
      Uint8List.fromList([1, 2, 3]),
      encoded(img.Image(width: 2, height: 2)),
    ]) {
      final signature = analyzePhotoThumbnail(bytes);
      expect(signature.isValid, isFalse);
      expect(signature.qualityScore, 0);
      expect(visualDistance(signature, signature), isNull);
    }
  });

  test('plain black white and colored images never form visual groups', () {
    final signatures = <ContentSignature>[];
    for (final color in [
      img.ColorRgb8(0, 0, 0),
      img.ColorRgb8(255, 255, 255),
      img.ColorRgb8(255, 0, 0),
      img.ColorRgb8(0, 0, 255),
    ]) {
      final image = img.Image(width: 96, height: 64)..clear(color);
      final signature = analyzePhotoThumbnail(encoded(image));
      expect(signature.isValid, isTrue);
      expect(signature.isLowInformation, isTrue);
      expect(signature.qualityScore, 0);
      signatures.add(signature);
    }
    for (final a in signatures) {
      for (final b in signatures) {
        expect(visualDistance(a, b), isNull);
      }
    }
    expect(
      groupSimilarPhotos([
        for (var i = 0; i < signatures.length; i++) photo('$i', signatures[i]),
      ]),
      isEmpty,
    );
  });

  test('same metadata does not group unrelated visible content', () {
    final first = analyzePhotoThumbnail(encoded(scene(seed: 1)));
    final second = analyzePhotoThumbnail(encoded(scene(seed: 81)));
    expect(
      groupSimilarPhotos([photo('a', first), photo('b', second)]),
      isEmpty,
    );
  });

  test(
    'nearby capture and slight exposure edits are visual review candidates',
    () {
      final first = analyzePhotoThumbnail(encoded(scene()));
      final burst = analyzePhotoThumbnail(encoded(scene(shift: 1)));
      final edited = analyzePhotoThumbnail(encoded(scene(exposure: 7)));
      expect(visualDistance(first, burst), lessThanOrEqualTo(10));
      expect(visualDistance(first, edited), lessThanOrEqualTo(10));
      final result = groupSimilarPhotos([
        photo('a', first),
        photo('b', burst),
        photo('c', edited),
        photo('unrelated', analyzePhotoThumbnail(encoded(scene(seed: 52)))),
        photo('pending', null),
        photo('failed', ContentSignature.invalid()),
      ]);
      expect(result, hasLength(1));
      expect(result.single, unorderedEquals(['a', 'b', 'c']));
    },
  );

  test('matching luminance pattern with different colors is excluded', () {
    final red = img.Image(width: 128, height: 128);
    final blue = img.Image(width: 128, height: 128);
    for (var y = 0; y < 128; y++) {
      for (var x = 0; x < 128; x++) {
        final high = (x ~/ 16 + y ~/ 16).isEven;
        red.setPixelRgb(x, y, high ? 250 : 0, 30, 30);
        blue.setPixelRgb(x, y, 30, 30, high ? 250 : 0);
      }
    }
    final a = analyzePhotoThumbnail(encoded(red));
    final b = analyzePhotoThumbnail(encoded(blue));
    expect(a.isLowInformation, isFalse);
    expect(b.isLowInformation, isFalse);
    expect(visualDistance(a, b), isNull);
  });

  test('JSON round trip preserves comparison and explainable quality', () {
    final a = analyzePhotoThumbnail(encoded(scene()));
    final restored = ContentSignature.fromMap(
      jsonDecode(jsonEncode(a.toMap())) as Map<String, dynamic>,
    );
    expect(visualDistance(a, restored), 0);
    expect(restored.qualityScore, inInclusiveRange(0, 100));
    expect(restored.qualityReasons, isNotEmpty);
    expect(restored.qualityReasons, contains('整體亮度適中'));
    expect(() => restored.perceptualBits.add(1), throwsUnsupportedError);
  });

  test(
    'quality compares edge detail, without subject or expression claims',
    () {
      final sharp = scene();
      final blurred = img.gaussianBlur(img.Image.from(sharp), radius: 6);
      final a = analyzePhotoThumbnail(encoded(sharp));
      final b = analyzePhotoThumbnail(encoded(blurred));
      expect(a.sharpness, greaterThan(b.sharpness));
      expect(a.qualityScore, greaterThan(b.qualityScore));
      expect(a.qualityReasons.join(), isNot(contains('表情')));
    },
  );

  test(
    'group suggestions put best measured quality first and deduplicate IDs',
    () {
      final signature = analyzePhotoThumbnail(encoded(scene()));
      final map = signature.toMap();
      final lower = ContentSignature.fromMap({...map, 'qualityScore': 1.0});
      expect(
        groupSimilarPhotos([
          photo('lower', lower),
          photo('best', signature),
          photo('best', signature),
        ]),
        [
          ['best', 'lower'],
        ],
      );
    },
  );

  test('large candidate sets remain content based and deterministic', () {
    final signature = analyzePhotoThumbnail(encoded(scene()));
    final unrelated = analyzePhotoThumbnail(encoded(scene(seed: 999)));
    final photos = [
      for (var i = 0; i < 2500; i++) photo('a$i', signature),
      photo('other', unrelated),
    ];
    final groups = groupSimilarPhotos(photos);
    expect(groups, hasLength(1));
    expect(groups.single.length, 2500);
    expect(groups.single, isNot(contains('other')));
  });

  test(
    'crowded immutable candidates preserve distance boundaries and grouping decisions',
    () {
      ContentSignature feature(
        math.Random random, {
        List<double>? spatial,
      }) => ContentSignature(
        isValid: true,
        isLowInformation: false,
        perceptualBits: List.generate(64, (i) => i < 8 ? 0 : random.nextInt(2)),
        gradientBits: List.generate(64, (i) => i < 8 ? 0 : random.nextInt(2)),
        colorMeans: const [.5, .5, .5],
        colorHistogram: List.filled(12, .25),
        spatialLuminance:
            spatial ?? List.generate(64, (_) => random.nextDouble() * 2 - 1),
        brightness: .5,
        sharpness: .02,
        qualityScore: 75,
        qualityReasons: const [],
      );

      // Reference the former spatial decision, including its sqrt boundary and
      // the established weighted/rounded Hamming distance for these valid inputs.
      int? referenceDistance(ContentSignature a, ContentSignature b) {
        var spatial = 0.0;
        var perceptual = 0;
        var gradient = 0;
        for (var i = 0; i < 64; i++) {
          spatial += math.pow(a.spatialLuminance[i] - b.spatialLuminance[i], 2);
          if (a.perceptualBits[i] != b.perceptualBits[i]) perceptual++;
          if (a.gradientBits[i] != b.gradientBits[i]) gradient++;
        }
        return math.sqrt(spatial / 64) > .38
            ? null
            : ((perceptual * 2 + gradient) / 3).round();
      }

      for (final seed in [1, 19, 103]) {
        final random = math.Random(seed);
        final zero = feature(random, spatial: List.filled(64, 0));
        for (final boundary in [.38 - 1e-12, .38, .38 + 1e-12]) {
          final other = feature(random, spatial: List.filled(64, boundary));
          expect(visualDistance(zero, other), referenceDistance(zero, other));
        }
        // All 512 distinct assets share an indexed band, saturating the 128-entry
        // candidate bucket. Their incompatible structures must remain ungrouped,
        // while true matching review candidates still join their representatives.
        final signatures = List.generate(512, (_) => feature(random));
        for (var i = 1; i < signatures.length; i++) {
          expect(
            visualDistance(signatures[0], signatures[i]),
            referenceDistance(signatures[0], signatures[i]),
          );
        }
        final assets = [
          for (var i = 0; i < signatures.length; i++)
            photo('asset-${i.toString().padLeft(4, '0')}', signatures[i]),
          for (var i = 0; i < 5; i++) photo('copy-$i', signatures[i]),
        ];
        final groups = groupSimilarPhotos(assets);
        expect(groups, hasLength(5));
        for (var i = 0; i < 5; i++) {
          expect(
            groups,
            contains(
              unorderedEquals([
                'asset-${i.toString().padLeft(4, '0')}',
                'copy-$i',
              ]),
            ),
          );
        }
        expect(
          groupSimilarPhotos(assets.reversed.toList()),
          groups,
          reason:
              'Immutable eligibility validation must preserve deterministic groups.',
        );
      }
    },
  );
}
