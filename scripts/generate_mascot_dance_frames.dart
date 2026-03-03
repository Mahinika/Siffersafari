import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main(List<String> args) {
  final options = _parseArgs(args);

  final inputPath = options['in'] ?? 'assets/images/themes/jungle/character_v2.png';
  final outDirPath = options['out'] ?? 'artifacts/mascot_frames/character_v2_dance';
  final count = int.tryParse(options['count'] ?? '') ?? 16;
  final size = int.tryParse(options['size'] ?? '') ?? 256;
  final amp = int.tryParse(options['amp'] ?? '') ?? 10;
  final scaleAmp = double.tryParse(options['scale'] ?? '') ?? 0.06;

  if (count < 2) {
    stderr.writeln('count måste vara >= 2');
    exitCode = 2;
    return;
  }

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    stderr.writeln('Hittar inte input-bild: $inputPath');
    exitCode = 2;
    return;
  }

  final bytes = inputFile.readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    stderr.writeln('Kunde inte läsa PNG: $inputPath');
    exitCode = 2;
    return;
  }

  final base = _fitToSquare(decoded, size);

  final outDir = Directory(outDirPath);
  outDir.createSync(recursive: true);

  for (var i = 0; i < count; i++) {
    final t = (i / count) * math.pi * 2.0;

    // Small dance: bob + sway + tiny scale pulsation.
    final dx = (math.sin(t) * amp).round();
    final dy = (math.cos(t) * (amp * 0.6)).round();
    final s = 1.0 + (math.sin(t * 2.0) * scaleAmp);

    final scaledSize = (size * s).round().clamp((size * 0.7).round(), (size * 1.3).round());
    final scaled = img.copyResize(
      base,
      width: scaledSize,
      height: scaledSize,
      interpolation: img.Interpolation.linear,
    );

    final canvas = img.Image(width: size, height: size);
    img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

    final x = ((size - scaled.width) ~/ 2) + dx;
    final y = ((size - scaled.height) ~/ 2) + dy;

    img.compositeImage(canvas, scaled, dstX: x, dstY: y);

    final name = 'dance_${i.toString().padLeft(3, '0')}.png';
    final outFile = File('${outDir.path}/$name');
    outFile.writeAsBytesSync(img.encodePng(canvas));
  }

  stdout.writeln('KLAR: Skapade $count frames i: ${outDir.path}');
  stdout.writeln('Tips: kopiera till assets med:');
  stdout.writeln(
    '  Copy-Item "${outDir.path}\\dance_*.png" "assets/images/characters/character_v2/dance/" -Force',
  );
}

img.Image _fitToSquare(img.Image input, int size) {
  // Preserve aspect: fit within square, then place on transparent canvas.
  final scale = math.min(size / input.width, size / input.height);
  final w = (input.width * scale).round().clamp(1, size);
  final h = (input.height * scale).round().clamp(1, size);

  final resized = img.copyResize(
    input,
    width: w,
    height: h,
    interpolation: img.Interpolation.linear,
  );

  final canvas = img.Image(width: size, height: size);
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

  final x = (size - resized.width) ~/ 2;
  final y = (size - resized.height) ~/ 2;
  img.compositeImage(canvas, resized, dstX: x, dstY: y);

  return canvas;
}

Map<String, String> _parseArgs(List<String> args) {
  final out = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (!a.startsWith('--')) continue;
    final key = a.substring(2);
    final next = (i + 1) < args.length ? args[i + 1] : null;
    if (next != null && !next.startsWith('--')) {
      out[key] = next;
      i++;
    } else {
      out[key] = 'true';
    }
  }
  return out;
}
