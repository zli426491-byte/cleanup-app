import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Thumbnail evidence for visual review, never proof of identical originals.
/// All fields use isolate-sendable values and can be persisted as JSON.
class ContentSignature {
  final bool isValid;
  final bool isLowInformation;
  final List<int> perceptualBits;
  final List<int> gradientBits;
  final List<double> colorMeans;
  final List<double> colorHistogram;
  final List<double> spatialLuminance;
  final double brightness;
  final double sharpness;
  final double qualityScore;
  final List<String> qualityReasons;

  bool get isBlurry => isValid && !isLowInformation && sharpness < 0.004;
  bool get isDark => isValid && brightness < 0.15;
  bool get isOverexposed => isValid && brightness > 0.85;

  ContentSignature({
    required this.isValid,
    required this.isLowInformation,
    required List<int> perceptualBits,
    required List<int> gradientBits,
    required List<double> colorMeans,
    required List<double> colorHistogram,
    required List<double> spatialLuminance,
    required this.brightness,
    required this.sharpness,
    required this.qualityScore,
    required List<String> qualityReasons,
  }) : perceptualBits = List.unmodifiable(perceptualBits),
       gradientBits = List.unmodifiable(gradientBits),
       colorMeans = List.unmodifiable(colorMeans),
       colorHistogram = List.unmodifiable(colorHistogram),
       spatialLuminance = List.unmodifiable(spatialLuminance),
       qualityReasons = List.unmodifiable(qualityReasons);

  factory ContentSignature.invalid() => ContentSignature(
    isValid: false,
    isLowInformation: true,
    perceptualBits: const [],
    gradientBits: const [],
    colorMeans: const [],
    colorHistogram: const [],
    spatialLuminance: const [],
    brightness: 0,
    sharpness: 0,
    qualityScore: 0,
    qualityReasons: const ['無法解碼預覽，未評估畫面品質'],
  );

  Map<String, Object> toMap() => {
    'isValid': isValid,
    'isLowInformation': isLowInformation,
    'perceptualBits': perceptualBits,
    'gradientBits': gradientBits,
    'colorMeans': colorMeans,
    'colorHistogram': colorHistogram,
    'spatialLuminance': spatialLuminance,
    'brightness': brightness,
    'sharpness': sharpness,
    'qualityScore': qualityScore,
    'qualityReasons': qualityReasons,
  };

  factory ContentSignature.fromMap(Map<String, dynamic> map) {
    List<int> ints(String key) =>
        (map[key] as List).cast<num>().map((value) => value.toInt()).toList();
    List<double> doubles(String key) => (map[key] as List)
        .cast<num>()
        .map((value) => value.toDouble())
        .toList();
    return ContentSignature(
      isValid: map['isValid'] as bool,
      isLowInformation: map['isLowInformation'] as bool,
      perceptualBits: ints('perceptualBits'),
      gradientBits: ints('gradientBits'),
      colorMeans: doubles('colorMeans'),
      colorHistogram: doubles('colorHistogram'),
      spatialLuminance: doubles('spatialLuminance'),
      brightness: (map['brightness'] as num).toDouble(),
      sharpness: (map['sharpness'] as num).toDouble(),
      qualityScore: (map['qualityScore'] as num).toDouble(),
      qualityReasons: (map['qualityReasons'] as List).cast<String>(),
    );
  }
}

/// Metadata is retained for presentation, never used as similarity evidence.
class AnalyzedPhoto {
  final String id;
  final int width;
  final int height;
  final DateTime createDate;
  final ContentSignature? signature;

  const AnalyzedPhoto({
    required this.id,
    required this.width,
    required this.height,
    required this.createDate,
    this.signature,
  });
}

/// Suitable as a top-level `compute` callback. Input should be a bounded
/// thumbnail, not an unbounded original file. Failed decoding is not evidence.
ContentSignature analyzePhotoThumbnail(Uint8List bytes) {
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null || decoded.width < 8 || decoded.height < 8) {
      return ContentSignature.invalid();
    }
    final oriented = img.bakeOrientation(decoded);
    final square = img.copyResize(
      oriented,
      width: 32,
      height: 32,
      interpolation: img.Interpolation.average,
    );
    final luminance = <double>[];
    final means = [0.0, 0.0, 0.0];
    final histogram = List<double>.filled(12, 0);
    for (final pixel in square) {
      final channels = _rgb(pixel);
      luminance.add(_luma(channels));
      for (var channel = 0; channel < 3; channel++) {
        means[channel] += channels[channel] / 1024;
        final bin = (channels[channel] * 4).floor().clamp(0, 3);
        histogram[channel * 4 + bin] += 1 / 1024;
      }
    }
    final brightness = _mean(luminance);
    final deviation = math.sqrt(_variance(luminance));
    final lowInformation = deviation < 0.035;
    final spatial = <double>[];
    for (var blockY = 0; blockY < 8; blockY++) {
      for (var blockX = 0; blockX < 8; blockX++) {
        var total = 0.0;
        for (var dy = 0; dy < 4; dy++) {
          for (var dx = 0; dx < 4; dx++) {
            total += luminance[(blockY * 4 + dy) * 32 + blockX * 4 + dx];
          }
        }
        spatial.add((total / 16 - brightness) / math.max(deviation, 0.035));
      }
    }
    final coefficients = <double>[];
    for (var v = 0; v < 8; v++) {
      for (var u = 0; u < 8; u++) {
        var coefficient = 0.0;
        for (var y = 0; y < 32; y++) {
          for (var x = 0; x < 32; x++) {
            coefficient +=
                luminance[y * 32 + x] * _cosines[u][x] * _cosines[v][y];
          }
        }
        coefficients.add(coefficient);
      }
    }
    final sorted = coefficients.skip(1).toList()..sort();
    final median = sorted[sorted.length ~/ 2];
    final perceptual = [
      0,
      ...coefficients.skip(1).map((v) => v > median ? 1 : 0),
    ];
    final gradientImage = img.copyResize(
      oriented,
      width: 9,
      height: 8,
      interpolation: img.Interpolation.average,
    );
    final gradient = <int>[];
    for (var y = 0; y < 8; y++) {
      for (var x = 0; x < 8; x++) {
        final left = gradientImage.getPixel(x, y);
        final right = gradientImage.getPixel(x + 1, y);
        gradient.add(_luma(_rgb(left)) > _luma(_rgb(right)) ? 1 : 0);
      }
    }
    final laplacians = <double>[];
    for (var y = 1; y < 31; y++) {
      for (var x = 1; x < 31; x++) {
        final index = y * 32 + x;
        laplacians.add(
          -4 * luminance[index] +
              luminance[index - 1] +
              luminance[index + 1] +
              luminance[index - 32] +
              luminance[index + 32],
        );
      }
    }
    // This describes thumbnail edge detail, not subjects, expression or taste.
    final sharpness = _variance(laplacians);
    final clarityScore = (math.log(1 + sharpness * 1000) / math.log(101)).clamp(
      0.0,
      1.0,
    );
    final exposureScore = (1 - (brightness - 0.5).abs() * 2).clamp(0.0, 1.0);
    final quality = lowInformation
        ? 0.0
        : (clarityScore * 65 + exposureScore * 35);
    final reasons = <String>[
      if (lowInformation) '畫面資訊不足，不提供品質保留建議',
      if (!lowInformation) sharpness >= 0.004 ? '縮圖邊緣較清楚' : '縮圖邊緣細節較少',
      if (!lowInformation)
        brightness < 0.15
            ? '整體畫面偏暗'
            : brightness > 0.85
            ? '整體畫面偏亮'
            : '整體亮度適中',
    ];
    return ContentSignature(
      isValid: true,
      isLowInformation: lowInformation,
      perceptualBits: perceptual,
      gradientBits: gradient,
      colorMeans: means,
      colorHistogram: histogram,
      spatialLuminance: spatial,
      brightness: brightness,
      sharpness: sharpness,
      qualityScore: quality,
      qualityReasons: reasons,
    );
  } catch (_) {
    return ContentSignature.invalid();
  }
}

final _cosines = List.generate(
  8,
  (u) => List.generate(32, (x) => math.cos((2 * x + 1) * u * math.pi / 64)),
);

double _luma(List<double> rgb) =>
    rgb[0] * 0.299 + rgb[1] * 0.587 + rgb[2] * 0.114;
List<double> _rgb(img.Color pixel) {
  final alpha =
      (pixel.length == 2
              ? pixel[1] / pixel.maxChannelValue
              : pixel.length >= 4
              ? pixel.aNormalized
              : 1.0)
          .toDouble()
          .clamp(0.0, 1.0);
  // Transparent color channels are invisible, and must not create evidence.
  final channels = pixel.length < 3
      ? List<num>.filled(3, pixel.rNormalized)
      : [pixel.rNormalized, pixel.gNormalized, pixel.bNormalized];
  return channels
      .map((channel) => channel.toDouble().clamp(0.0, 1.0) * alpha + 1 - alpha)
      .toList();
}

double _mean(List<double> values) =>
    values.reduce((a, b) => a + b) / values.length;
double _variance(List<double> values) {
  final mean = _mean(values);
  return values.fold<double>(
        0,
        (sum, value) => sum + math.pow(value - mean, 2),
      ) /
      values.length;
}

bool _comparable(ContentSignature? signature) =>
    signature != null &&
    signature.isValid &&
    !signature.isLowInformation &&
    signature.perceptualBits.length == 64 &&
    signature.gradientBits.length == 64 &&
    signature.colorMeans.length == 3 &&
    signature.colorHistogram.length == 12 &&
    signature.spatialLuminance.length == 64 &&
    signature.perceptualBits.every((value) => value == 0 || value == 1) &&
    signature.gradientBits.every((value) => value == 0 || value == 1) &&
    signature.colorMeans.every((value) => value.isFinite) &&
    signature.colorHistogram.every((value) => value.isFinite) &&
    signature.spatialLuminance.every((value) => value.isFinite) &&
    signature.qualityScore.isFinite;

/// Returns a conservative visual distance (0–64), or null for insufficient
/// evidence/incompatible color or structure. Zero still is NOT byte equality.
int? visualDistance(ContentSignature a, ContentSignature b) {
  if (!_comparable(a) || !_comparable(b)) return null;
  for (var i = 0; i < 3; i++) {
    if ((a.colorMeans[i] - b.colorMeans[i]).abs() > 0.18) return null;
  }
  var colorDifference = 0.0;
  for (var i = 0; i < 12; i++) {
    colorDifference += (a.colorHistogram[i] - b.colorHistogram[i]).abs();
  }
  if (colorDifference / 6 > 0.28) return null;
  var spatialDifference = 0.0;
  var perceptualDistance = 0;
  var gradientDistance = 0;
  for (var i = 0; i < 64; i++) {
    spatialDifference += math.pow(
      a.spatialLuminance[i] - b.spatialLuminance[i],
      2,
    );
    if (a.perceptualBits[i] != b.perceptualBits[i]) perceptualDistance++;
    if (a.gradientBits[i] != b.gradientBits[i]) gradientDistance++;
  }
  if (math.sqrt(spatialDifference / 64) > 0.38) return null;
  return ((perceptualDistance * 2 + gradientDistance) / 3).round();
}

/// Approximate, content-indexed candidate grouping. No time/name/size matching.
/// SHA256-verified duplicates must be excluded by the caller. Work is bounded
/// by 128 candidate clusters per photo and 128 entries per hash bucket; some
/// similar photos may therefore be missed. Every member matches its group's
/// representative, so weak transitive matches cannot grow a misleading chain.
/// First ID is a reversible quality suggestion, NEVER a deletion instruction.
List<List<String>> groupSimilarPhotos(List<AnalyzedPhoto> photos) {
  final unique = <String, AnalyzedPhoto>{};
  for (final photo in photos) {
    if (_comparable(photo.signature)) unique.putIfAbsent(photo.id, () => photo);
  }
  final eligible = unique.values.toList()
    ..sort((a, b) {
      final quality = b.signature!.qualityScore.compareTo(
        a.signature!.qualityScore,
      );
      return quality != 0 ? quality : a.id.compareTo(b.id);
    });
  final groups = <List<AnalyzedPhoto>>[];
  final buckets = <String, List<int>>{};
  for (final photo in eligible) {
    final keys = _indexKeys(photo.signature!);
    final candidates = <int>{};
    for (final key in keys) {
      for (final index in buckets[key] ?? const <int>[]) {
        candidates.add(index);
        if (candidates.length >= 128) break;
      }
      if (candidates.length >= 128) break;
    }
    int? bestGroup;
    var bestDistance = 11;
    for (final index in candidates) {
      final representative = groups[index].first.signature!;
      final distance = visualDistance(representative, photo.signature!);
      if (distance != null && distance < bestDistance) {
        bestDistance = distance;
        bestGroup = index;
      }
    }
    if (bestGroup != null) {
      groups[bestGroup].add(photo);
    } else {
      final index = groups.length;
      groups.add([photo]);
      for (final key in keys) {
        final bucket = buckets.putIfAbsent(key, () => []);
        if (bucket.length < 128) bucket.add(index);
      }
    }
  }
  return groups
      .where((group) => group.length > 1)
      .map((group) => group.map((photo) => photo.id).toList())
      .toList();
}

List<String> _indexKeys(ContentSignature signature) {
  final keys = <String>[];
  for (var kind = 0; kind < 2; kind++) {
    final bits = kind == 0 ? signature.perceptualBits : signature.gradientBits;
    for (var band = 0; band < 8; band++) {
      var value = 0;
      for (var bit = 0; bit < 8; bit++) {
        value = (value << 1) | bits[band * 8 + bit];
      }
      keys.add('$kind:$band:$value');
    }
  }
  return keys;
}
