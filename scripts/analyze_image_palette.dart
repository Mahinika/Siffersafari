import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  if (args.isEmpty || args.contains('-h') || args.contains('--help')) {
    stdout.writeln(
      'Usage: dart run scripts/analyze_image_palette.dart <path.png>',
    );
    stdout.writeln('Options:');
    stdout
        .writeln('  --top <n>         Number of colors to print (default: 12)');
    stdout.writeln('  --step <n>        Sample every n pixels (default: 1)');
    stdout.writeln(
      '  --bucketBits <n>  Quantization bits per channel 1..8 (default: 4)',
    );
    exit(0);
  }

  final path = args.first;
  final opts = _parseArgs(args.skip(1).toList());
  final top = _parseInt(opts['top'], fallback: 12, min: 1, max: 64);
  final step = _parseInt(opts['step'], fallback: 1, min: 1, max: 64);
  final bucketBits = _parseInt(opts['bucketBits'], fallback: 4, min: 1, max: 8);

  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('File not found: $path');
    exit(2);
  }

  final decoded = img.decodeImage(file.readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('Could not decode: $path');
    exit(2);
  }

  final image = img.bakeOrientation(decoded);
  final w = image.width;
  final h = image.height;

  final counts = <int, int>{};
  var sampled = 0;
  var nonTransparent = 0;

  for (var y = 0; y < h; y += step) {
    for (var x = 0; x < w; x += step) {
      sampled++;
      final p = image.getPixel(x, y);
      final a = p.a.toInt();
      if (a == 0) continue;
      nonTransparent++;

      final q = _quantizeRgb(p.r.toInt(), p.g.toInt(), p.b.toInt(), bucketBits);
      counts[q] = (counts[q] ?? 0) + 1;
    }
  }

  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  stdout.writeln('File: $path');
  stdout.writeln('Size: ${w}x$h  channels=${image.numChannels}');
  stdout.writeln('Sampled pixels: $sampled (step=$step)');
  stdout.writeln('Non-transparent sampled: $nonTransparent');
  stdout.writeln('Quantization: bucketBits=$bucketBits (per channel)');
  stdout.writeln('Top colors (approx):');

  final denom = nonTransparent == 0 ? 1 : nonTransparent;
  for (var i = 0; i < entries.length && i < top; i++) {
    final e = entries[i];
    final rgb = _dequantizeRgb(e.key, bucketBits);
    final pct = (e.value / denom) * 100;
    stdout.writeln(
      '  ${i + 1}. #${_hex2(rgb.$1)}${_hex2(rgb.$2)}${_hex2(rgb.$3)}  ~rgb(${rgb.$1},${rgb.$2},${rgb.$3})  ${pct.toStringAsFixed(2)}% (${e.value})',
    );
  }
}

int _quantizeRgb(int r, int g, int b, int bucketBits) {
  final shift = 8 - bucketBits;
  final qr = (r >> shift) & ((1 << bucketBits) - 1);
  final qg = (g >> shift) & ((1 << bucketBits) - 1);
  final qb = (b >> shift) & ((1 << bucketBits) - 1);
  return (qr << (bucketBits * 2)) | (qg << bucketBits) | qb;
}

(int, int, int) _dequantizeRgb(int q, int bucketBits) {
  final mask = (1 << bucketBits) - 1;
  final qb = q & mask;
  final qg = (q >> bucketBits) & mask;
  final qr = (q >> (bucketBits * 2)) & mask;

  // Map bucket center back to 0..255.
  int expand(int v) {
    final levels = 1 << bucketBits;
    return (((v + 0.5) * 255) / (levels - 1)).round().clamp(0, 255);
  }

  return (expand(qr), expand(qg), expand(qb));
}

Map<String, String> _parseArgs(List<String> args) {
  final out = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (!a.startsWith('-')) continue;

    final key = a.replaceFirst(RegExp(r'^-+'), '');
    if (i + 1 < args.length && !args[i + 1].startsWith('-')) {
      out[key] = args[i + 1];
      i++;
    } else {
      out[key] = 'true';
    }
  }
  return out;
}

int _parseInt(
  String? value, {
  required int fallback,
  required int min,
  required int max,
}) {
  final n = int.tryParse((value ?? '').trim()) ?? fallback;
  return n.clamp(min, max);
}

String _hex2(int v) => v.toRadixString(16).padLeft(2, '0').toUpperCase();
