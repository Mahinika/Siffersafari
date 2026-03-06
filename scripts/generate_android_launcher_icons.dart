import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  final projectRoot = Directory.current.path;

  // Input image path
  final inputPath = args.isNotEmpty
      ? args[0]
      : '$projectRoot/assets/images/app_icon/icon_source.png';

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    stderr.writeln('Input image not found: $inputPath');
    stderr.writeln(
      'Usage: dart run scripts/generate_android_launcher_icons.dart [path/to/icon.png]',
    );
    exitCode = 1;
    return;
  }

  // Load source image
  final bytes = inputFile.readAsBytesSync();
  final sourceImage = img.decodeImage(bytes);
  if (sourceImage == null) {
    stderr.writeln('Failed to decode image: $inputPath');
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Loaded source image: ${sourceImage.width}x${sourceImage.height}',
  );

  final resRoot = '$projectRoot/android/app/src/main/res';

  final bg = _averageOpaqueColor(sourceImage);
  final bgHex = _rgbToHex(bg);

  // Write adaptive icon XML (API 26+)
  final anydpiV26 = Directory('$resRoot/mipmap-anydpi-v26');
  if (!anydpiV26.existsSync()) {
    anydpiV26.createSync(recursive: true);
  }

  File('${anydpiV26.path}/ic_launcher.xml').writeAsStringSync(
    _adaptiveIconXml(
      background: '@color/ic_launcher_background',
      foreground: '@mipmap/ic_launcher_foreground',
    ),
  );
  File('${anydpiV26.path}/ic_launcher_round.xml').writeAsStringSync(
    _adaptiveIconXml(
      background: '@color/ic_launcher_background',
      foreground: '@mipmap/ic_launcher_foreground',
    ),
  );

  // Write adaptive icon background color
  final valuesDir = Directory('$resRoot/values');
  if (!valuesDir.existsSync()) {
    stderr.writeln('Missing Android values dir: ${valuesDir.path}');
    exitCode = 2;
    return;
  }
  File('${valuesDir.path}/ic_launcher_background.xml').writeAsStringSync(
    _launcherBackgroundColorXml(bgHex),
  );

  stdout.writeln('Adaptive icon background: $bgHex');

  // Legacy icons (pre-26 + fallback)
  final legacyTargets = <String, int>{
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  // Adaptive icon layers are 108dp. Pixel sizes below follow Android templates.
  final adaptiveLayerTargets = <String, int>{
    'mipmap-mdpi': 108,
    'mipmap-hdpi': 162,
    'mipmap-xhdpi': 216,
    'mipmap-xxhdpi': 324,
    'mipmap-xxxhdpi': 432,
  };

  var wroteAny = false;

  for (final entry in legacyTargets.entries) {
    final dirName = entry.key;
    final size = entry.value;

    final outPath = '$resRoot/$dirName/ic_launcher.png';
    final outFile = File(outPath);
    if (!outFile.parent.existsSync()) {
      stderr.writeln('Missing Android res dir: ${outFile.parent.path}');
      exitCode = 2;
      continue;
    }

    final icon = _renderLegacyIcon(
      sourceImage: sourceImage,
      size: size,
      background: bg,
    );
    outFile.writeAsBytesSync(img.encodePng(icon, level: 6));
    stdout.writeln('Wrote $outPath (${size}x$size)');
    wroteAny = true;
  }

  for (final entry in adaptiveLayerTargets.entries) {
    final dirName = entry.key;
    final size = entry.value;

    final outPath = '$resRoot/$dirName/ic_launcher_foreground.png';
    final outFile = File(outPath);
    if (!outFile.parent.existsSync()) {
      stderr.writeln('Missing Android res dir: ${outFile.parent.path}');
      exitCode = 2;
      continue;
    }

    final fg = _renderAdaptiveForeground(
      sourceImage: sourceImage,
      size: size,
    );
    outFile.writeAsBytesSync(img.encodePng(fg, level: 6));
    stdout.writeln('Wrote $outPath (${size}x$size)');
    wroteAny = true;
  }

  if (!wroteAny) {
    stderr.writeln('No icons written. Are you running this from project root?');
    exitCode = 1;
  }
}

img.Image _renderLegacyIcon({
  required img.Image sourceImage,
  required int size,
  required img.ColorRgb8 background,
}) {
  final canvas = img.Image(width: size, height: size);
  img.fill(canvas, color: background);

  // Give the icon some breathing room, but keep it large.
  final padding = (size * 0.06).round().clamp(2, 24);
  final innerSize = (size - padding * 2).clamp(1, size);
  final resized = img.copyResize(
    sourceImage,
    width: innerSize,
    height: innerSize,
    interpolation: img.Interpolation.average,
  );

  img.compositeImage(canvas, resized, dstX: padding, dstY: padding);
  return canvas;
}

img.Image _renderAdaptiveForeground({
  required img.Image sourceImage,
  required int size,
}) {
  final canvas = img.Image(width: size, height: size);
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

  // Slightly larger than legacy, but keep safe-ish margins for masks.
  final padding = (size * 0.10).round().clamp(6, 64);
  final innerSize = (size - padding * 2).clamp(1, size);
  final resized = img.copyResize(
    sourceImage,
    width: innerSize,
    height: innerSize,
    interpolation: img.Interpolation.average,
  );
  img.compositeImage(canvas, resized, dstX: padding, dstY: padding);
  return canvas;
}

img.ColorRgb8 _averageOpaqueColor(img.Image sourceImage) {
  // Downscale to make averaging fast.
  final small = img.copyResize(
    sourceImage,
    width: 64,
    height: 64,
    interpolation: img.Interpolation.average,
  );

  var r = 0;
  var g = 0;
  var b = 0;
  var count = 0;

  for (var y = 0; y < small.height; y++) {
    for (var x = 0; x < small.width; x++) {
      final p = small.getPixel(x, y);
      final a = p.a;
      if (a <= 8) continue;
      r += p.r.toInt();
      g += p.g.toInt();
      b += p.b.toInt();
      count++;
    }
  }

  if (count == 0) {
    // Fallback: a neutral mid-gray.
    return img.ColorRgb8(0x66, 0x66, 0x66);
  }

  return img.ColorRgb8(
    (r / count).round().clamp(0, 255),
    (g / count).round().clamp(0, 255),
    (b / count).round().clamp(0, 255),
  );
}

String _rgbToHex(img.ColorRgb8 c) {
  String two(int v) => v.toRadixString(16).padLeft(2, '0').toUpperCase();
  return '#${two(c.r.toInt())}${two(c.g.toInt())}${two(c.b.toInt())}';
}

String _launcherBackgroundColorXml(String colorHex) {
  return '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">$colorHex</color>
</resources>
''';
}

String _adaptiveIconXml({
  required String background,
  required String foreground,
}) {
  return '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="$background" />
    <foreground android:drawable="$foreground" />
</adaptive-icon>
''';
}
