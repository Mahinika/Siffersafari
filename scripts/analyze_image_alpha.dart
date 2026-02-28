import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  if (args.isEmpty || args.contains('-h') || args.contains('--help')) {
    stdout
        .writeln('Usage: dart run scripts/analyze_image_alpha.dart <path.png>');
    exit(0);
  }

  final path = args.first;
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

  final w = decoded.width;
  final h = decoded.height;
  final total = w * h;

  img.Pixel px(int x, int y) => decoded.getPixel(x, y);
  String rgba(img.Pixel p) =>
      'rgba(${p.r.toInt()},${p.g.toInt()},${p.b.toInt()},${p.a.toInt()})';

  final tl = px(0, 0);
  final tr = px(w - 1, 0);
  final bl = px(0, h - 1);
  final br = px(w - 1, h - 1);

  var transparent = 0;
  var semi = 0;
  var opaque = 0;

  int minX = w, minY = h, maxX = -1, maxY = -1;

  var edgeNonTransparent = 0;
  for (var x = 0; x < w; x++) {
    if (px(x, 0).a.toInt() > 0) edgeNonTransparent++;
    if (px(x, h - 1).a.toInt() > 0) edgeNonTransparent++;
  }
  for (var y = 1; y < h - 1; y++) {
    if (px(0, y).a.toInt() > 0) edgeNonTransparent++;
    if (px(w - 1, y).a.toInt() > 0) edgeNonTransparent++;
  }

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = decoded.getPixel(x, y);
      final a = p.a.toInt();
      if (a == 0) {
        transparent++;
        continue;
      }
      if (a == 255) {
        opaque++;
      } else {
        semi++;
      }

      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
  }

  final nonTransparent = total - transparent;
  final bboxW = maxX >= 0 ? (maxX - minX + 1) : 0;
  final bboxH = maxY >= 0 ? (maxY - minY + 1) : 0;

  String pct(int n) => ((n / total) * 100).toStringAsFixed(2);

  stdout.writeln('File: $path');
  stdout.writeln('Size: ${w}x$h  channels=${decoded.numChannels}');
  stdout.writeln('Corners:');
  stdout.writeln('  TL ${rgba(tl)}');
  stdout.writeln('  TR ${rgba(tr)}');
  stdout.writeln('  BL ${rgba(bl)}');
  stdout.writeln('  BR ${rgba(br)}');
  stdout.writeln('Edge non-transparent pixels: $edgeNonTransparent');
  stdout.writeln('Alpha breakdown:');
  stdout.writeln('  transparent: $transparent (${pct(transparent)}%)');
  stdout.writeln('  semi:        $semi (${pct(semi)}%)');
  stdout.writeln('  opaque:      $opaque (${pct(opaque)}%)');

  if (nonTransparent == 0) {
    stdout.writeln('WARNING: everything is transparent (likely broken).');
    exit(1);
  }

  stdout.writeln(
    'Non-transparent bbox: x=$minX..$maxX y=$minY..$maxY  (w=$bboxW h=$bboxH)',
  );

  // Heuristics
  final transparentPct = transparent / total;
  if (transparentPct < 0.2) {
    stdout.writeln(
      'NOTE: Low transparency ratio; background might not be fully removed.',
    );
  }
  if (transparentPct > 0.95) {
    stdout.writeln(
      'NOTE: Very high transparency ratio; check that the character is not too thin/eroded.',
    );
  }
}
