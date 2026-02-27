import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  if (args.isEmpty || args.contains('-h') || args.contains('--help')) {
    stdout.writeln(
        'Usage: dart run scripts/analyze_comfyui_batch.dart <fileOrDir> [more...]');
    stdout
        .writeln('Prints one-line diagnostics per image (alpha, bbox, edge).');
    exit(0);
  }

  final files = <File>[];
  for (final a in args) {
    final entityType = FileSystemEntity.typeSync(a);
    if (entityType == FileSystemEntityType.notFound) {
      stderr.writeln('Not found: $a');
      exitCode = 2;
      continue;
    }
    if (entityType == FileSystemEntityType.directory) {
      final dir = Directory(a);
      for (final e in dir.listSync(recursive: true, followLinks: false)) {
        if (e is! File) continue;
        final lower = e.path.toLowerCase();
        if (lower.endsWith('.png') ||
            lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg')) {
          files.add(e);
        }
      }
    } else if (entityType == FileSystemEntityType.file) {
      files.add(File(a));
    }
  }

  if (files.isEmpty) {
    stderr.writeln('No image files found.');
    exit(2);
  }

  files.sort((a, b) => a.path.compareTo(b.path));

  stdout.writeln('path\tsize\tch\ttrans%\tedgenon0\tbbox%\tflags\tcorners');

  for (final f in files) {
    final bytes = f.readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      stdout.writeln('${f.path}\t?\t?\t?\t?\t?\tDECODE_FAIL\t-');
      continue;
    }

    final w = decoded.width;
    final h = decoded.height;
    final total = w * h;
    final hasAlpha = decoded.numChannels >= 4;

    int alphaAt(int x, int y) =>
        hasAlpha ? decoded.getPixel(x, y).a.toInt() : 255;

    var edgeNonTransparent = 0;
    for (var x = 0; x < w; x++) {
      if (alphaAt(x, 0) > 0) edgeNonTransparent++;
      if (alphaAt(x, h - 1) > 0) edgeNonTransparent++;
    }
    for (var y = 1; y < h - 1; y++) {
      if (alphaAt(0, y) > 0) edgeNonTransparent++;
      if (alphaAt(w - 1, y) > 0) edgeNonTransparent++;
    }

    var transparent = 0;

    var minX = w, minY = h, maxX = -1, maxY = -1;

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final a = alphaAt(x, y);
        if (a == 0) {
          transparent++;
          continue;
        }
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }

    final bboxW = maxX >= 0 ? (maxX - minX + 1) : 0;
    final bboxH = maxY >= 0 ? (maxY - minY + 1) : 0;
    final bboxArea = bboxW * bboxH;

    String pct(num n) => ((n / total) * 100).toStringAsFixed(2);

    final flags = <String>[];
    if (!hasAlpha) flags.add('NO_ALPHA');
    if (transparent / total < 0.20 && hasAlpha) flags.add('LOW_TRANS');
    if (edgeNonTransparent > 0 && hasAlpha) flags.add('EDGE');
    if (bboxArea == total) flags.add('FULL_BBOX');

    img.Pixel p(int x, int y) => decoded.getPixel(x, y);
    final tl = p(0, 0);
    final tr = p(w - 1, 0);
    final bl = p(0, h - 1);
    final br = p(w - 1, h - 1);

    int cornerDist(img.Pixel a, img.Pixel b) {
      final dr = (a.r.toInt() - b.r.toInt()).abs();
      final dg = (a.g.toInt() - b.g.toInt()).abs();
      final db = (a.b.toInt() - b.b.toInt()).abs();
      return dr + dg + db;
    }

    final maxCornerDist = [
      cornerDist(tl, tr),
      cornerDist(tl, bl),
      cornerDist(tl, br),
      cornerDist(tr, bl),
      cornerDist(tr, br),
      cornerDist(bl, br),
    ].reduce((a, b) => a > b ? a : b);

    if (maxCornerDist > 80) flags.add('MULTI_CORNER_BG');

    String c(img.Pixel q) =>
        '(${q.r.toInt()},${q.g.toInt()},${q.b.toInt()},${hasAlpha ? q.a.toInt() : 255})';

    final corners = 'TL${c(tl)} TR${c(tr)} BL${c(bl)} BR${c(br)}';

    stdout.writeln(
      '${f.path}\t${w}x$h\t${decoded.numChannels}\t${pct(transparent)}\t$edgeNonTransparent\t${pct(bboxArea)}\t${flags.isEmpty ? '-' : flags.join(',')}\t$corners',
    );
  }
}
