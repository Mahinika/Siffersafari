import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  final parsed = _parseArgs(args);
  if (parsed.containsKey('help') || parsed.containsKey('h') || args.isEmpty) {
    _printHelp();
    exit(0);
  }

  final dirPath = parsed['dir'] ?? parsed['d'];
  if (dirPath == null) {
    stderr.writeln('Missing required arg: --dir');
    _printHelp();
    exit(2);
  }

  final prefix = parsed['prefix'];

  final fps = int.tryParse(parsed['fps'] ?? '') ?? 8;
  if (fps <= 0 || fps > 60) {
    stderr.writeln('Invalid --fps: $fps (expected 1..60)');
    exit(2);
  }
  final frameDurationMs = (1000 / fps).round().clamp(1, 60000);

  final dir = Directory(dirPath);
  if (!dir.existsSync()) {
    stderr.writeln('Directory not found: $dirPath');
    exit(2);
  }

  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.png'))
      .where((f) {
        if (prefix == null || prefix.trim().isEmpty) return true;
        return f.uri.pathSegments.last.startsWith(prefix);
      })
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (files.isEmpty) {
    stderr.writeln('No PNG files found in: $dirPath');
    exit(2);
  }

  final outPath = parsed['out'] ??
      parsed['o'] ??
      _defaultOutPath(dirPath: dirPath, prefix: prefix);

  final outFile = File(outPath);
  outFile.parent.createSync(recursive: true);

  // GIF uses 1/100 sec units. Keep >= 1 to avoid zero-delay frames.
  final frameDurationHundredths = _clampInt((frameDurationMs / 10).round(), 1, 60000);

  final encoder = img.GifEncoder(repeat: 0);

  int? targetWidth;
  int? targetHeight;
  var decodedFrames = 0;

  for (final f in files) {
    final bytes = f.readAsBytesSync();
    final decoded = img.decodePng(bytes);
    if (decoded == null) {
      stderr.writeln('Failed to decode: ${f.path}');
      continue;
    }

    var frame = decoded.convert(format: img.Format.uint8);
    if (targetWidth == null || targetHeight == null) {
      targetWidth = frame.width;
      targetHeight = frame.height;
    } else if (frame.width != targetWidth || frame.height != targetHeight) {
      frame = img.copyResize(
        frame,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.nearest,
      );
    }

    encoder.addFrame(frame, duration: frameDurationHundredths);
    decodedFrames++;
  }

  if (decodedFrames < 2) {
    stderr.writeln('Only $decodedFrames decodable frame(s). Need >= 2 for preview.');
    exit(2);
  }

  final gifBytes = encoder.finish();
  if (gifBytes == null || gifBytes.isEmpty) {
    stderr.writeln('Failed to encode GIF.');
    exit(2);
  }

  outFile.writeAsBytesSync(gifBytes);

  stdout.writeln('Wrote: ${outFile.path}');
  stdout.writeln('Frames: $decodedFrames @ ${fps}fps (~${frameDurationMs}ms/frame)');
}

int _clampInt(int value, int minValue, int maxValue) {
  if (value < minValue) return minValue;
  if (value > maxValue) return maxValue;
  return value;
}

String _defaultOutPath({required String dirPath, required String? prefix}) {
  // Put previews next to the frames directory by default.
  final baseName = (prefix == null || prefix.trim().isEmpty)
      ? 'preview'
      : prefix.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]+'), '');
  final safeBase = baseName.isEmpty ? 'preview' : baseName;
  return '${dirPath.replaceAll('\\', '/')}/$safeBase.gif';
}

void _printHelp() {
  stdout.writeln('''
Build a GIF preview from PNG animation frames (no emulator needed).

Required:
  --dir <path>        Directory with PNG frames

Optional:
  --prefix <text>     Only include files whose name starts with prefix (e.g. idle_)
  --fps <int>         Frames per second (default 8)
  --out <path>        Output GIF path (default: <dir>/<prefix>.gif)

Examples:
  dart run scripts/preview_animation_gif.dart --dir assets/images/characters/character_v2/idle --prefix idle_ --fps 10 --out artifacts/comfyui/previews/idle.gif
  dart run scripts/preview_animation_gif.dart --dir assets/images/characters/character_v2/run  --prefix run_  --fps 12 --out artifacts/comfyui/previews/run.gif
''');
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
