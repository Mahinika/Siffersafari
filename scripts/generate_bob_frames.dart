import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  final parsed = _parseArgs(args);
  if (parsed.containsKey('help') || parsed.containsKey('h') || args.isEmpty) {
    _printHelp();
    exit(0);
  }

  final inputPath = parsed['in'] ?? parsed['input'];
  final outDirPath = parsed['out-dir'] ?? parsed['out'] ?? parsed['output-dir'];
  final prefix = parsed['prefix'] ?? 'frame_';
  final overwrite = _isTruthy(parsed['overwrite']);

  final dxs = _parseIntList(parsed['dx']);
  final dys = _parseIntList(parsed['dy']);

  // Default: 8-frame idle bob.
  final defaultDy = <int>[0, -1, -2, -1, 0, 1, 2, 1];
  final defaultDx = List<int>.filled(defaultDy.length, 0);

  final dx = (dxs == null || dxs.isEmpty) ? defaultDx : dxs;
  final dy = (dys == null || dys.isEmpty) ? defaultDy : dys;

  if (dx.length != dy.length) {
    stderr.writeln('dx and dy must have the same length.');
    stderr.writeln('Got dx=${dx.length} dy=${dy.length}');
    exit(2);
  }

  final frameCount = dx.length;

  if (inputPath == null || outDirPath == null) {
    stderr.writeln('Missing required args: --in and --out-dir');
    _printHelp();
    exit(2);
  }

  final inFile = File(inputPath);
  if (!inFile.existsSync()) {
    stderr.writeln('Input not found: $inputPath');
    exit(2);
  }

  final decoded = img.decodeImage(inFile.readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('Could not decode image: $inputPath');
    exit(2);
  }

  final source = _ensureRgba(decoded);
  final outDir = Directory(outDirPath)..createSync(recursive: true);

  stdout.writeln('---');
  stdout.writeln('Input: $inputPath (${source.width}x${source.height})');
  stdout.writeln('Out:   $outDirPath');
  stdout.writeln('Frames: $frameCount  prefix=$prefix overwrite=$overwrite');
  stdout.writeln('dx: $dx');
  stdout.writeln('dy: $dy');

  for (var i = 0; i < frameCount; i++) {
    final outName = '$prefix${i.toString().padLeft(3, '0')}.png';
    final outPath = '${outDir.path}${Platform.pathSeparator}$outName';
    final outFile = File(outPath);

    if (outFile.existsSync() && !overwrite) {
      stderr.writeln('Refusing to overwrite existing file: $outPath');
      stderr.writeln('Re-run with --overwrite=true if this is intended.');
      exit(2);
    }

    final frame =
        img.Image(width: source.width, height: source.height, numChannels: 4);
    // Transparent by default.
    img.compositeImage(frame, source, dstX: dx[i], dstY: dy[i]);
    outFile.writeAsBytesSync(img.encodePng(frame));
  }

  stdout.writeln('Wrote $frameCount frame(s).');
}

img.Image _ensureRgba(img.Image image) {
  final baked = img.bakeOrientation(image);
  if (baked.numChannels == 4) return baked;
  final out =
      img.Image(width: baked.width, height: baked.height, numChannels: 4);
  img.compositeImage(out, baked);
  return out;
}

List<int>? _parseIntList(String? value) {
  if (value == null) return null;
  final v = value.trim();
  if (v.isEmpty) return null;

  // Accept: "0,-1,-2" or "0 -1 -2".
  final parts = v.split(RegExp(r'[\s,]+')).where((p) => p.trim().isNotEmpty);
  final out = <int>[];
  for (final p in parts) {
    final n = int.tryParse(p);
    if (n == null) {
      stderr.writeln('Invalid integer in list: "$p"');
      exit(2);
    }
    out.add(n);
  }
  return out;
}

bool _isTruthy(String? value) {
  if (value == null) return false;
  final v = value.trim().toLowerCase();
  return v == '1' || v == 'true' || v == 'yes' || v == 'y' || v == 'on';
}

void _printHelp() {
  stdout.writeln('''
Generate simple animation frames by shifting a single PNG by (dx,dy) per frame.

Required:
  --in <path>                 Input PNG (single frame)
  --out-dir <dir>             Output directory

Optional:
  --prefix <text>             Output prefix (default: frame_)
  --dx "list"                Comma/space separated dx values (default: all 0)
  --dy "list"                Comma/space separated dy values
                             Default dy (idle bob, 8 frames): 0,-1,-2,-1,0,1,2,1
  --overwrite=true|false      Allow overwriting output files (default: false)

Examples:
  # Create 8 idle frames for Ville directly into assets
  dart run scripts/generate_bob_frames.dart 
    --in assets/images/themes/jungle/character_v2.png 
    --out-dir assets/images/characters/character_v2/idle 
    --prefix idle_ 
    --overwrite=true

  # Make a faster bob (smaller movement)
  dart run scripts/generate_bob_frames.dart 
    --in assets/images/themes/jungle/character_v2.png 
    --out-dir artifacts/tmp_idle 
    --prefix idle_ 
    --dy "0,-1,0,1,0,-1,0,1" 
    --overwrite=true
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
