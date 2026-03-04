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

  final frameW = int.tryParse(parsed['frame-w'] ?? '') ??
      int.tryParse(parsed['w'] ?? '') ??
      0;
  final frameH = int.tryParse(parsed['frame-h'] ?? '') ??
      int.tryParse(parsed['h'] ?? '') ??
      0;

  final count = int.tryParse(parsed['count'] ?? '') ?? 0;
  final columns = int.tryParse(parsed['columns'] ?? '') ?? 0;

  final padLeft = int.tryParse(parsed['pad-left'] ?? '0') ?? 0;
  final padTop = int.tryParse(parsed['pad-top'] ?? '0') ?? 0;
  final gapX = int.tryParse(parsed['gap-x'] ?? '0') ?? 0;
  final gapY = int.tryParse(parsed['gap-y'] ?? '0') ?? 0;

  final overwrite = _isTruthy(parsed['overwrite']);

  if (inputPath == null || outDirPath == null) {
    stderr.writeln('Missing required args: --in and --out-dir');
    _printHelp();
    exit(2);
  }
  if (frameW <= 0 || frameH <= 0) {
    stderr.writeln('Missing/invalid frame size: --frame-w and --frame-h');
    exit(2);
  }
  if (count <= 0) {
    stderr.writeln('Missing/invalid --count (number of frames)');
    exit(2);
  }
  if (columns <= 0) {
    stderr.writeln('Missing/invalid --columns (frames per row in the sheet)');
    exit(2);
  }

  final inFile = File(inputPath);
  if (!inFile.existsSync()) {
    stderr.writeln('Input not found: $inputPath');
    exit(2);
  }

  final bytes = inFile.readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    stderr.writeln('Could not decode image: $inputPath');
    exit(2);
  }

  final image = _ensureRgba(decoded);

  final outDir = Directory(outDirPath);
  outDir.createSync(recursive: true);

  final expectedRows = ((count + columns - 1) / columns).floor();
  final sheetNeededW = padLeft + (columns * frameW) + ((columns - 1) * gapX);
  final sheetNeededH =
      padTop + (expectedRows * frameH) + ((expectedRows - 1) * gapY);

  if (image.width < sheetNeededW || image.height < sheetNeededH) {
    stderr.writeln('Spritesheet too small for the given params.');
    stderr.writeln('Sheet: ${image.width}x${image.height}');
    stderr.writeln('Needed: ${sheetNeededW}x$sheetNeededH');
    stderr.writeln(
      'Tip: check --columns/--count/--frame-w/--frame-h and padding/gaps.',
    );
    exit(2);
  }

  stdout.writeln('---');
  stdout.writeln('Input: $inputPath');
  stdout.writeln('Sheet: ${image.width}x${image.height}');
  stdout.writeln('Frame: ${frameW}x$frameH  count=$count  columns=$columns');
  stdout.writeln('Pad: left=$padLeft top=$padTop  Gap: x=$gapX y=$gapY');
  stdout.writeln('Out: $outDirPath  prefix=$prefix  overwrite=$overwrite');

  for (var i = 0; i < count; i++) {
    final col = i % columns;
    final row = i ~/ columns;

    final x = padLeft + col * (frameW + gapX);
    final y = padTop + row * (frameH + gapY);

    final outName = '$prefix${i.toString().padLeft(3, '0')}.png';
    final outPath = '${outDir.path}${Platform.pathSeparator}$outName';
    final outFile = File(outPath);

    if (outFile.existsSync() && !overwrite) {
      stderr.writeln('Refusing to overwrite existing file: $outPath');
      stderr.writeln('Re-run with --overwrite=true if this is intended.');
      exit(2);
    }

    final frame =
        img.copyCrop(image, x: x, y: y, width: frameW, height: frameH);
    outFile.writeAsBytesSync(img.encodePng(frame));
  }

  stdout.writeln('Wrote $count frame(s).');
}

img.Image _ensureRgba(img.Image image) {
  if (image.numChannels == 4) return image;
  return img.bakeOrientation(image);
}

bool _isTruthy(String? value) {
  if (value == null) return false;
  final v = value.trim().toLowerCase();
  return v == '1' || v == 'true' || v == 'yes' || v == 'y' || v == 'on';
}

void _printHelp() {
  stdout.writeln('''
Split a spritesheet into numbered PNG frames.

Typical use for Ville (character_v2):
  1) Export a spritesheet from LibreSprite (File -> Export Sprite Sheet).
  2) Run this script to write frames to the action folder.

Required:
  --in <path>                 Input spritesheet PNG
  --out-dir <dir>             Output directory
  --frame-w <px>              Frame width
  --frame-h <px>              Frame height
  --count <n>                 Number of frames to export
  --columns <n>               Frames per row in the sheet

Optional:
  --prefix <text>             Output prefix (default: frame_)
  --pad-left <px>             Left padding before first frame (default: 0)
  --pad-top <px>              Top padding before first frame (default: 0)
  --gap-x <px>                Horizontal gap between frames (default: 0)
  --gap-y <px>                Vertical gap between frames (default: 0)
  --overwrite=true|false      Allow overwriting existing files (default: false)

Examples:
  # Replace Ville run animation (8 frames, one row, 512x512 each)
  dart run scripts/split_spritesheet.dart 
    --in artifacts/run_sheet.png 
    --out-dir assets/images/characters/character_v2/run 
    --prefix run_ 
    --frame-w 512 --frame-h 512 
    --count 8 --columns 8 
    --overwrite=true

  # Idle frames
  dart run scripts/split_spritesheet.dart 
    --in artifacts/idle_sheet.png 
    --out-dir assets/images/characters/character_v2/idle 
    --prefix idle_ 
    --frame-w 512 --frame-h 512 
    --count 8 --columns 8 
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

    // Flags or key-value.
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
