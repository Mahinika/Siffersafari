import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  final parsed = _parseArgs(args);
  if (parsed.containsKey('help') || parsed.containsKey('h') || args.isEmpty) {
    _printHelp();
    exit(0);
  }

  final inDirPath = parsed['in-dir'] ?? parsed['in'] ?? parsed['input-dir'];
  final outDirPath = parsed['out-dir'] ?? parsed['out'] ?? parsed['output-dir'];
  final prefix = parsed['prefix'];
  final size = int.tryParse(parsed['size'] ?? '64') ?? 64;
  final margin = int.tryParse(parsed['margin'] ?? '0') ?? 0;
  final padToSquare = (parsed['pad-square'] ?? 'true').toLowerCase() != 'false';
  final overwrite = _isTruthy(parsed['overwrite']);

  if (inDirPath == null || outDirPath == null) {
    stderr.writeln('Missing required args: --in-dir and --out-dir');
    _printHelp();
    exit(2);
  }
  if (size <= 0 || size > 4096) {
    stderr.writeln('Invalid --size: $size');
    exit(2);
  }
  if (margin < 0 || margin > 2048) {
    stderr.writeln('Invalid --margin: $margin');
    exit(2);
  }

  final inDir = Directory(inDirPath);
  if (!inDir.existsSync()) {
    stderr.writeln('Input dir not found: $inDirPath');
    exit(2);
  }

  final files = inDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.png'))
      .where((f) {
    if (prefix == null || prefix.trim().isEmpty) return true;
    return f.uri.pathSegments.last.startsWith(prefix);
  }).toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (files.isEmpty) {
    stderr.writeln('No PNG files found in: $inDirPath');
    exit(2);
  }

  final decoded = <_NamedImage>[];
  for (final f in files) {
    final bytes = f.readAsBytesSync();
    final image = img.decodeImage(bytes);
    if (image == null) {
      stderr.writeln('Failed to decode: ${f.path}');
      continue;
    }
    decoded.add(
      _NamedImage(name: f.uri.pathSegments.last, image: _ensureRgba(image)),
    );
  }

  if (decoded.isEmpty) {
    stderr.writeln('No decodable PNG files in: $inDirPath');
    exit(2);
  }

  // Compute a union bbox across all frames so the crop is stable (avoids jitter).
  final union = _unionNonTransparentBbox(decoded.map((e) => e.image).toList());
  if (union == null) {
    stderr.writeln('All frames appear fully transparent. Aborting.');
    exit(2);
  }

  final outDir = Directory(outDirPath)..createSync(recursive: true);

  stdout.writeln('---');
  stdout.writeln(
    'In:  $inDirPath  frames=${decoded.length}  prefix=${prefix ?? '(none)'}',
  );
  stdout.writeln(
    'Out: $outDirPath  size=${size}x$size  margin=$margin  padSquare=$padToSquare  overwrite=$overwrite',
  );
  stdout.writeln(
    'Union bbox: x=${union.x}..${union.x + union.w - 1}  y=${union.y}..${union.y + union.h - 1}  (w=${union.w} h=${union.h})',
  );

  for (final fr in decoded) {
    final outPath = '${outDir.path}${Platform.pathSeparator}${fr.name}';
    final outFile = File(outPath);

    if (outFile.existsSync() && !overwrite) {
      stderr.writeln('Refusing to overwrite existing file: $outPath');
      stderr.writeln('Re-run with --overwrite=true if this is intended.');
      exit(2);
    }

    final cropped = _cropWithMargin(fr.image, union, margin: margin);
    final prepared = padToSquare ? _padToSquareTransparent(cropped) : cropped;
    final resized = img.copyResize(
      prepared,
      width: size,
      height: size,
      interpolation: img.Interpolation.nearest,
    );

    outFile.writeAsBytesSync(img.encodePng(resized));
  }

  stdout.writeln('Wrote ${decoded.length} frame(s).');
}

class _NamedImage {
  _NamedImage({required this.name, required this.image});
  final String name;
  final img.Image image;
}

typedef _Rect = ({int x, int y, int w, int h});

img.Image _ensureRgba(img.Image image) {
  // image.decodeImage already returns an Image; keep as-is.
  // For safety, bake orientation (no-op for PNG) and ensure 4 channels.
  final baked = img.bakeOrientation(image);
  if (baked.numChannels == 4) return baked;
  final out =
      img.Image(width: baked.width, height: baked.height, numChannels: 4);
  img.compositeImage(out, baked);
  return out;
}

_Rect? _largestConnectedComponentBbox(img.Image image) {
  final w = image.width;
  final h = image.height;
  final n = w * h;

  int index(int x, int y) => y * w + x;

  final mask = Uint8List(n);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (image.getPixel(x, y).a.toInt() > 0) {
        mask[index(x, y)] = 1;
      }
    }
  }

  final visited = Uint8List(n);
  final stack = <int>[];

  var bestSize = 0;
  _Rect? best;

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final start = index(x, y);
      if (mask[start] == 0 || visited[start] != 0) continue;

      visited[start] = 1;
      stack.add(start);

      var size = 0;
      var minX = x;
      var maxX = x;
      var minY = y;
      var maxY = y;

      while (stack.isNotEmpty) {
        final i = stack.removeLast();
        size++;
        final cx = i % w;
        final cy = i ~/ w;

        if (cx < minX) minX = cx;
        if (cx > maxX) maxX = cx;
        if (cy < minY) minY = cy;
        if (cy > maxY) maxY = cy;

        void tryVisit(int nx, int ny) {
          if (nx < 0 || ny < 0 || nx >= w || ny >= h) return;
          final ni = index(nx, ny);
          if (mask[ni] == 0 || visited[ni] != 0) return;
          visited[ni] = 1;
          stack.add(ni);
        }

        tryVisit(cx - 1, cy);
        tryVisit(cx + 1, cy);
        tryVisit(cx, cy - 1);
        tryVisit(cx, cy + 1);
      }

      if (size > bestSize) {
        bestSize = size;
        best = (x: minX, y: minY, w: maxX - minX + 1, h: maxY - minY + 1);
      }
    }
  }

  return best;
}

_Rect? _unionNonTransparentBbox(List<img.Image> images) {
  _Rect? union;
  for (final image in images) {
    // Use the largest connected component to avoid union-bboxes being blown up
    // by a few stray pixels far away from the character.
    final bbox = _largestConnectedComponentBbox(image);
    if (bbox == null) continue;

    if (union == null) {
      union = bbox;
      continue;
    }

    final x0 = _min(union.x, bbox.x);
    final y0 = _min(union.y, bbox.y);
    final x1 = _max(union.x + union.w - 1, bbox.x + bbox.w - 1);
    final y1 = _max(union.y + union.h - 1, bbox.y + bbox.h - 1);
    union = (x: x0, y: y0, w: x1 - x0 + 1, h: y1 - y0 + 1);
  }

  return union;
}

img.Image _cropWithMargin(img.Image image, _Rect rect, {required int margin}) {
  final w = image.width;
  final h = image.height;

  final x0 = (rect.x - margin).clamp(0, w - 1);
  final y0 = (rect.y - margin).clamp(0, h - 1);

  final x1 = (rect.x + rect.w - 1 + margin).clamp(0, w - 1);
  final y1 = (rect.y + rect.h - 1 + margin).clamp(0, h - 1);

  final cw = (x1 - x0 + 1).clamp(1, w);
  final ch = (y1 - y0 + 1).clamp(1, h);

  return img.copyCrop(image, x: x0, y: y0, width: cw, height: ch);
}

img.Image _padToSquareTransparent(img.Image image) {
  final size = _max(image.width, image.height);
  final out = img.Image(width: size, height: size, numChannels: 4);

  // Transparent by default (0,0,0,0). Composite in the center.
  final ox = (size - image.width) ~/ 2;
  final oy = (size - image.height) ~/ 2;
  img.compositeImage(out, image, dstX: ox, dstY: oy);
  return out;
}

int _min(int a, int b) => a < b ? a : b;
int _max(int a, int b) => a > b ? a : b;

bool _isTruthy(String? value) {
  if (value == null) return false;
  final v = value.trim().toLowerCase();
  return v == '1' || v == 'true' || v == 'yes' || v == 'y' || v == 'on';
}

void _printHelp() {
  stdout.writeln('''
Downscale a set of PNG frames to pixel-art friendly size using nearest-neighbor.

This script avoids jitter by computing a union crop-box over all frames first,
then cropping every frame with the SAME rect before resizing.

Required:
  --in-dir <dir>              Input directory with PNG frames
  --out-dir <dir>             Output directory

Optional:
  --prefix <text>             Only include files starting with prefix (e.g. run_)
  --size <px>                 Output width/height (default: 64)
  --margin <px>               Extra pixels around union bbox before resizing (default: 0)
  --pad-square=true|false     Pad crop to square before resizing (default: true)
  --overwrite=true|false      Allow overwriting output files (default: false)

Notes:
  Cropping uses the largest connected non-transparent region in each frame to
  ignore isolated stray pixels (prevents the union crop from becoming 512x512).

Examples:
  # Create 64x64 run frames next to originals
  dart run scripts/downscale_frames.dart
    --in-dir assets/images/characters/character_v2/run
    --out-dir artifacts/mascot_frames/character_v2_run/run_64
    --prefix run_
    --size 64
    --margin 8

  # Same for idle
  dart run scripts/downscale_frames.dart
    --in-dir assets/images/characters/character_v2/idle
    --out-dir artifacts/mascot_frames/character_v2_idle/idle_64
    --prefix idle_
    --size 64
    --margin 8
''');
}

Map<String, String?> _parseArgs(List<String> args) {
  final out = <String, String?>{};
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (!a.startsWith('-')) continue;

    final key = a.replaceFirst(RegExp(r'^-+'), '');
    final eqIndex = key.indexOf('=');
    if (eqIndex >= 0) {
      final k = key.substring(0, eqIndex);
      final v = key.substring(eqIndex + 1);
      out[k] = v;
      continue;
    }

    final next = (i + 1) < args.length ? args[i + 1] : null;
    if (next == null || next.startsWith('-')) {
      out[key] = 'true';
      continue;
    }

    out[key] = next;
    i++;
  }
  return out;
}
