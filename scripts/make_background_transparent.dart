import 'dart:collection';
import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  final parsed = _parseArgs(args);
  if (parsed.containsKey('help') || parsed.containsKey('h') || args.isEmpty) {
    _printHelp();
    exit(0);
  }

  final inputPath = parsed['in'] ?? parsed['input'];
  final outputPath = parsed['out'] ?? parsed['output'];
  final tolerance = int.tryParse(parsed['tolerance'] ?? '18') ?? 18;
  final minComponentRatio =
      double.tryParse(parsed['min-component-ratio'] ?? '0.01') ?? 0.01;

  if (inputPath == null || outputPath == null) {
    stderr.writeln('Missing required args: --in and --out');
    _printHelp();
    exit(2);
  }

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    stderr.writeln('Input not found: $inputPath');
    exit(2);
  }

  final bytes = inputFile.readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) {
    stderr.writeln('Could not decode image: $inputPath');
    exit(2);
  }

  final rgba = _ensureRgba(image);

  final bgs = _estimateCornerBackgrounds(rgba);
  final removed = _removeBackground(
    rgba,
    bgs,
    tolerance: tolerance,
    minComponentRatio: minComponentRatio,
  );

  final outFile = File(outputPath);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsBytesSync(img.encodePng(rgba));

  stdout.writeln('Wrote: $outputPath');
  stdout.writeln('Background corner samples (tolerance=$tolerance):');
  for (var i = 0; i < bgs.length; i++) {
    final c = bgs[i];
    stdout.writeln('  #${i + 1}: rgb(${c.r},${c.g},${c.b})');
  }
  stdout.writeln('Min component ratio: $minComponentRatio');
  stdout.writeln('Made transparent pixels: $removed');
}

img.Image _ensureRgba(img.Image source) {
  if (source.numChannels == 4) return source;

  final out = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 4,
  );

  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final p = source.getPixel(x, y);
      out.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), 255);
    }
  }

  return out;
}

void _printHelp() {
  stdout.writeln('''
Make a flat background transparent by flood-filling from the corners.

Required:
  --in <path>         Input PNG/JPG
  --out <path>        Output PNG (with alpha)

Optional:
  --tolerance <0-255> Color distance tolerance (default 18)
  --min-component-ratio <0..1> Also remove enclosed background components if they
                               are at least this fraction of the image (default 0.01)

Example:
  dart run scripts/make_background_transparent.dart --in assets/images/themes/space/tmp.png --out assets/images/themes/space/character.png --tolerance 18
''');
}

List<({int r, int g, int b})> _estimateCornerBackgrounds(img.Image image) {
  // Average a small 6x6 area in each corner. Using each corner separately makes
  // the removal robust to slight gradients/vignettes.
  const sample = 6;
  final points = <(int x0, int y0)>[
    (0, 0),
    (image.width - sample, 0),
    (0, image.height - sample),
    (image.width - sample, image.height - sample),
  ];

  final out = <({int r, int g, int b})>[];
  for (final (x0, y0) in points) {
    var rSum = 0;
    var gSum = 0;
    var bSum = 0;
    var n = 0;
    for (var y = y0; y < y0 + sample; y++) {
      for (var x = x0; x < x0 + sample; x++) {
        final p = image.getPixel(x, y);
        rSum += p.r.toInt();
        gSum += p.g.toInt();
        bSum += p.b.toInt();
        n++;
      }
    }
    out.add(
        (r: (rSum / n).round(), g: (gSum / n).round(), b: (bSum / n).round()));
  }

  return out;
}

int _removeBackground(
  img.Image image,
  List<({int r, int g, int b})> bgs, {
  required int tolerance,
  required double minComponentRatio,
}) {
  final w = image.width;
  final h = image.height;

  bool matches(img.Pixel p) {
    for (final bg in bgs) {
      final dr = (p.r.toInt() - bg.r).abs();
      final dg = (p.g.toInt() - bg.g).abs();
      final db = (p.b.toInt() - bg.b).abs();
      // Manhattan distance is fine here.
      if ((dr + dg + db) <= tolerance) return true;
    }
    return false;
  }

  final bgMask = List<bool>.filled(w * h, false);
  int idx(int x, int y) => y * w + x;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = image.getPixel(x, y);
      bgMask[idx(x, y)] = matches(p);
    }
  }

  final minComponentPixels =
      (w * h * minComponentRatio).round().clamp(1, w * h);

  // Label connected components of bgMask; later remove those touching the edge
  // (classic flood-fill) and also large enclosed components.
  final labels = List<int>.filled(w * h, -1);
  final componentSizes = <int>[];
  final componentTouchesEdge = <bool>[];
  int nextLabel = 0;

  final q = Queue<(int x, int y)>();
  void enqueue(int x, int y) => q.add((x, y));

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = idx(x, y);
      if (!bgMask[i] || labels[i] != -1) continue;

      final label = nextLabel++;
      var size = 0;
      var touchesEdge = false;

      labels[i] = label;
      enqueue(x, y);

      while (q.isNotEmpty) {
        final (cx, cy) = q.removeFirst();
        final ci = idx(cx, cy);
        if (!bgMask[ci]) continue;

        size++;
        if (cx == 0 || cy == 0 || cx == w - 1 || cy == h - 1) {
          touchesEdge = true;
        }

        void tryNeighbor(int nx, int ny) {
          if (nx < 0 || nx >= w || ny < 0 || ny >= h) return;
          final ni = idx(nx, ny);
          if (!bgMask[ni] || labels[ni] != -1) return;
          labels[ni] = label;
          enqueue(nx, ny);
        }

        tryNeighbor(cx + 1, cy);
        tryNeighbor(cx - 1, cy);
        tryNeighbor(cx, cy + 1);
        tryNeighbor(cx, cy - 1);
      }

      componentSizes.add(size);
      componentTouchesEdge.add(touchesEdge);
    }
  }

  var removed = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = idx(x, y);
      final label = labels[i];
      if (label == -1) continue;

      final shouldRemove = componentTouchesEdge[label] ||
          componentSizes[label] >= minComponentPixels;
      if (!shouldRemove) continue;

      final p = image.getPixel(x, y);
      image.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), 0);
      removed++;
    }
  }

  return removed;
}

Map<String, String?> _parseArgs(List<String> args) {
  final out = <String, String?>{};
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (!a.startsWith('-')) continue;

    final key = a.replaceFirst(RegExp(r'^-+'), '');
    String? value;
    final eqIndex = key.indexOf('=');
    if (eqIndex != -1) {
      final k = key.substring(0, eqIndex);
      value = key.substring(eqIndex + 1);
      out[k] = value;
      continue;
    }

    if (i + 1 < args.length && !args[i + 1].startsWith('-')) {
      value = args[i + 1];
      i++;
    } else {
      value = 'true';
    }

    out[key] = value;
  }
  return out;
}
