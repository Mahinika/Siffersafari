import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  final projectRoot = Directory.current.path;
  final resRoot = '$projectRoot/android/app/src/main/res';

  final targets = <String, int>{
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  var wroteAny = false;
  for (final entry in targets.entries) {
    final dirName = entry.key;
    final size = entry.value;

    final outPath = '$resRoot/$dirName/ic_launcher.png';
    final outFile = File(outPath);
    if (!outFile.parent.existsSync()) {
      stderr.writeln('Missing Android res dir: ${outFile.parent.path}');
      exitCode = 2;
      continue;
    }

    final icon = _renderIcon(size);
    outFile.writeAsBytesSync(img.encodePng(icon, level: 6));
    stdout.writeln('Wrote $outPath (${size}x$size)');
    wroteAny = true;
  }

  if (!wroteAny) {
    stderr.writeln('No icons written. Are you running this from project root?');
    exitCode = 1;
  }
}

img.Image _renderIcon(int size) {
  final canvas = img.Image(width: size, height: size);

  // Background (warm off-white)
  img.fill(canvas, color: img.ColorRgb8(0xF6, 0xF2, 0xE8));

  // Chalkboard frame + board
  final frameMargin = (size * 0.14).round();
  final top = (size * 0.18).round();
  final boardW = size - frameMargin * 2;
  final boardH = (size * 0.56).round();
  final left = frameMargin;

  img.fillRect(
    canvas,
    x1: left,
    y1: top,
    x2: left + boardW,
    y2: top + boardH,
    color: img.ColorRgb8(0x2B, 0x2B, 0x2B),
  );

  final innerPad = (size * 0.03).round();
  img.fillRect(
    canvas,
    x1: left + innerPad,
    y1: top + innerPad,
    x2: left + boardW - innerPad,
    y2: top + boardH - innerPad,
    color: img.ColorRgb8(0x1F, 0x63, 0x3D),
  );

  // Chalk tray
  final trayH = (size * 0.05).round();
  final trayY = top + boardH - (size * 0.07).round();
  img.fillRect(
    canvas,
    x1: left + (size * 0.10).round(),
    y1: trayY,
    x2: left + boardW - (size * 0.10).round(),
    y2: trayY + trayH,
    color: img.ColorRgb8(0x3A, 0x2B, 0x21),
  );

  // Big multiplication 'X'
  final xCenter = size ~/ 2;
  final yCenter = top + (boardH * 0.46).round();
  final arm = (size * 0.16).round();
  final thickness = (size * 0.06).clamp(3, 18).round();

  _drawThickLine(
    canvas,
    xCenter - arm,
    yCenter - arm,
    xCenter + arm,
    yCenter + arm,
    thickness: thickness,
    color: img.ColorRgb8(0xF3, 0xF6, 0xFF),
  );
  _drawThickLine(
    canvas,
    xCenter + arm,
    yCenter - arm,
    xCenter - arm,
    yCenter + arm,
    thickness: thickness,
    color: img.ColorRgb8(0xF3, 0xF6, 0xFF),
  );

  // Small equation (kept subtle so it doesn't get mushy at small sizes)
  if (size >= 96) {
    img.drawString(canvas, '2x3=6',
        font: img.arial24,
        x: (size * 0.28).round(),
        y: (top + boardH * 0.70).round(),
        color: img.ColorRgb8(0xF3, 0xF6, 0xFF));
  }

  // Simple pencil accent (bottom-right)
  final pencilY = (size * 0.78).round();
  final pencilX = (size * 0.58).round();
  final pencilW = (size * 0.34).round();
  final pencilH = (size * 0.08).round();

  img.fillRect(
    canvas,
    x1: pencilX,
    y1: pencilY,
    x2: pencilX + pencilW,
    y2: pencilY + pencilH,
    color: img.ColorRgb8(0xF4, 0xC5, 0x42),
  );

  // Pencil tip (kept rectangular for compatibility across image versions)
  final tipW = (size * 0.06).round();
  img.fillRect(
    canvas,
    x1: pencilX + pencilW,
    y1: pencilY,
    x2: pencilX + pencilW + tipW,
    y2: pencilY + pencilH,
    color: img.ColorRgb8(0xEA, 0xD6, 0xC3),
  );
  img.fillRect(
    canvas,
    x1: pencilX + pencilW + (tipW * 0.62).round(),
    y1: pencilY + (pencilH * 0.25).round(),
    x2: pencilX + pencilW + tipW,
    y2: pencilY + (pencilH * 0.75).round(),
    color: img.ColorRgb8(0x3B, 0x2B, 0x22),
  );

  return canvas;
}

void _drawThickLine(
  img.Image canvas,
  int x1,
  int y1,
  int x2,
  int y2, {
  required int thickness,
  required img.Color color,
}) {
  // The image package's drawLine thickness API has varied across versions.
  // This implementation is version-agnostic: draw multiple parallel lines.
  final dx = (x2 - x1).toDouble();
  final dy = (y2 - y1).toDouble();
  final len = (dx.abs() + dy.abs()).clamp(1, 1 << 30).toDouble();

  // Unit normal (approx)
  final nx = -dy / len;
  final ny = dx / len;

  final half = (thickness / 2).floor();
  for (var i = -half; i <= half; i++) {
    final ox = (nx * i).round();
    final oy = (ny * i).round();
    img.drawLine(
      canvas,
      x1: x1 + ox,
      y1: y1 + oy,
      x2: x2 + ox,
      y2: y2 + oy,
      color: color,
    );
  }
}
