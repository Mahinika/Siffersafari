import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Generates simple, kid-friendly SFX WAV files (16-bit PCM, 44.1kHz, mono)
/// into assets/sounds.
///
/// It always creates timestamped backups if the target files already exist.
///
/// Usage:
///   dart run scripts/generate_sfx_wav.dart
///   dart run scripts/generate_sfx_wav.dart --out assets/sounds
///   dart run scripts/generate_sfx_wav.dart --only celebration
void main(List<String> args) {
  final outDir = _argValue(args, '--out') ?? 'assets/sounds';
  final only = _argValue(args, '--only');
  const sampleRate = 44100;

  final dir = Directory(outDir);
  dir.createSync(recursive: true);

  final stamp = DateTime.now()
      .toIso8601String()
      .replaceAll(':', '')
      .replaceAll('.', '')
      .replaceAll('-', '')
      .replaceAll('T', '_')
      .split('Z')
      .first;

  final onlySet = _parseOnlySet(only);

  final allTargets = <_NamedSound>[
    _NamedSound(
      name: 'click.wav',
      samples: _renderClick(sampleRate: sampleRate),
    ),
    _NamedSound(
      name: 'correct.wav',
      samples: _renderCorrect(sampleRate: sampleRate),
    ),
    _NamedSound(
      name: 'wrong.wav',
      samples: _renderWrong(sampleRate: sampleRate),
    ),
    _NamedSound(
      name: 'celebration.wav',
      samples: _renderCelebration(sampleRate: sampleRate),
    ),
  ];

  final targets = onlySet == null
      ? allTargets
          .where((t) => t.name != 'celebration.wav')
          .toList(growable: false)
      : allTargets
          .where((t) => onlySet.contains(_stemName(t.name)))
          .toList(growable: false);

  for (final t in targets) {
    final targetFile = File('${dir.path}/${t.name}');
    if (targetFile.existsSync()) {
      final backup = File('${dir.path}/${t.name}.backup_$stamp');
      targetFile.copySync(backup.path);
      stdout.writeln('[SFX] Backup: ${backup.path}');
    }

    final bytes = _encodeWavPcm16Mono(
      samples: t.samples,
      sampleRate: sampleRate,
    );
    targetFile.writeAsBytesSync(bytes);
    stdout.writeln(
      '[SFX] Wrote: ${targetFile.path}  (${t.samples.length} samples)',
    );
  }

  stdout.writeln('Done.');
}

Set<String>? _parseOnlySet(String? only) {
  if (only == null) return null;
  final parts = only
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .map((s) => s.toLowerCase())
      .toSet();
  if (parts.isEmpty) return null;
  return parts;
}

String _stemName(String filename) {
  // click.wav -> click
  final dot = filename.indexOf('.');
  return dot == -1
      ? filename.toLowerCase()
      : filename.substring(0, dot).toLowerCase();
}

String? _argValue(List<String> args, String key) {
  final index = args.indexOf(key);
  if (index == -1) return null;
  if (index + 1 >= args.length) return null;
  return args[index + 1];
}

class _NamedSound {
  const _NamedSound({required this.name, required this.samples});

  final String name;
  final List<double> samples; // [-1..1]
}

List<double> _renderClick({required int sampleRate}) {
  // Very short "pop" with a tiny pitch drop.
  const durationMs = 60;
  final n = (sampleRate * durationMs / 1000).round();
  final out = List<double>.filled(n, 0);

  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final freq = 1200 - 600 * (i / max(1, n - 1));
    final env = _expDecay(i, n, halfLifeFraction: 0.20);
    final s = sin(2 * pi * freq * t);

    // Mix with a little noise for "click" texture.
    final noise = (_hashNoise(i) * 2 - 1) * 0.15;

    out[i] = (s * 0.55 + noise) * env;
  }

  return _normalize(out, targetPeak: 0.85);
}

List<double> _renderCorrect({required int sampleRate}) {
  // Happy major arpeggio up.
  const durationMs = 520;
  final n = (sampleRate * durationMs / 1000).round();
  final out = List<double>.filled(n, 0);

  final notes = <double>[523.25, 659.25, 783.99]; // C5 E5 G5
  final segment = (n / notes.length).floor();

  for (var seg = 0; seg < notes.length; seg++) {
    final start = seg * segment;
    final end = seg == notes.length - 1 ? n : (seg + 1) * segment;
    final freq = notes[seg];

    for (var i = start; i < end; i++) {
      final t = i / sampleRate;
      final local = i - start;
      final localLen = end - start;

      final a = _adsr(
        local,
        localLen,
        attack: 0.09,
        decay: 0.16,
        sustain: 0.62,
        release: 0.24,
      );

      // Add slight "sparkle" harmonic.
      final base = sin(2 * pi * freq * t);
      final harm = sin(2 * pi * freq * 2 * t) * 0.10;
      out[i] += (base + harm) * a;
    }
  }

  // Gentle tail fade to avoid clicks.
  _fadeOut(out, sampleRate: sampleRate, ms: 45);
  return _normalize(out, targetPeak: 0.72);
}

List<double> _renderWrong({required int sampleRate}) {
  // Kid-friendly "oops": soft downward whoop + tiny final "bloop".
  const durationMs = 420;
  final n = (sampleRate * durationMs / 1000).round();
  final out = List<double>.filled(n, 0);

  // Part A: gentle down-gliss (0%..70%)
  final aEnd = (n * 0.70).round();
  // Part B: small up "bloop" (70%..100%)
  final bStart = aEnd;

  const vibHz = 5.5;
  const vibDepthHz = 9.0;

  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final x = i / max(1, n - 1);

    double freq;
    double env;

    if (i < aEnd) {
      final local = i / max(1, aEnd - 1);
      // 540Hz -> 360Hz
      freq = 540 + (360 - 540) * local;
      env = _adsr(
        i,
        n,
        attack: 0.08,
        decay: 0.18,
        sustain: 0.65,
        release: 0.30,
      );
    } else {
      final local = (i - bStart) / max(1, (n - bStart - 1));
      // 360Hz -> 430Hz (quick playful lift)
      freq = 360 + (430 - 360) * local;
      // Extra fade so the bloop doesn't feel like a new loud note.
      env = (1.0 - local) * 0.70;
    }

    final vib = sin(2 * pi * vibHz * t) * vibDepthHz;
    final f = freq + vib;

    // Soft rounded tone: pure sine + tiny harmonic.
    final base = sin(2 * pi * f * t);
    final harm = sin(2 * pi * f * 2 * t) * 0.05;

    // Gentle overall decay to keep it short and "snällt".
    final global = _expDecay(i, n, halfLifeFraction: 0.35) * (1.0 - 0.10 * x);

    out[i] = (base + harm) * env * global;
  }

  _fadeOut(out, sampleRate: sampleRate, ms: 75);
  return _normalize(out, targetPeak: 0.66);
}

List<double> _renderCelebration({required int sampleRate}) {
  // A longer, kid-friendly celebratory chime that feels "magisk".
  // Uses a gentle arpeggio, subtle bell-like partials, a bit of glitter,
  // and a light echo for extra "wow" without being harsh.
  const durationMs = 1400;
  final n = (sampleRate * durationMs / 1000).round();
  final out = List<double>.filled(n, 0);

  // Notes: start lower for warmth, then add higher notes for sparkle.
  // C5 E5 G5 + C6 + A5 (adds a "magisk" feel without dissonance).
  final notes = <double>[523.25, 659.25, 783.99, 1046.50, 880.00];
  final offsetsMs = <int>[0, 90, 180, 260, 340];
  final weights = <double>[0.34, 0.30, 0.26, 0.18, 0.20];

  for (var noteIndex = 0; noteIndex < notes.length; noteIndex++) {
    final f0 = notes[noteIndex];
    final start = (sampleRate * offsetsMs[noteIndex] / 1000).round();
    if (start >= n) continue;

    final localN = n - start;
    for (var i = start; i < n; i++) {
      final t = (i - start) / sampleRate;
      final localI = i - start;

      final env = _adsr(
        localI,
        localN,
        attack: 0.03,
        decay: 0.18,
        sustain: 0.22,
        release: 0.55,
      );

      // Tiny vibrato + detune so it feels alive (but still soft).
      final vib = sin(2 * pi * (5.2 + 0.2 * noteIndex) * t) * 3.0;
      final f = f0 + vib;

      final base = sin(2 * pi * f * t);
      final p2 = sin(2 * pi * f * 2.01 * t) * 0.14;
      final p3 = sin(2 * pi * f * 3.02 * t) * 0.08;
      final shimmer = sin(2 * pi * f * 1.005 * t) * 0.06;

      out[i] += (base + p2 + p3 + shimmer) * env * weights[noteIndex];
    }
  }

  // Gentle glitter layer that comes in pulses (more magical, less noise).
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final pulse = pow(sin(2 * pi * 7.5 * t).abs(), 8).toDouble();
    final glitterEnv = _expDecay(i, n, halfLifeFraction: 0.20) +
        0.35 * _expDecay(i, n, halfLifeFraction: 0.06);
    final glitter = (_hashNoise(i) * 2 - 1) * 0.05;
    out[i] += glitter * pulse * glitterEnv;
  }

  var withEcho = _applyEcho(
    out,
    sampleRate: sampleRate,
    delayMs: 120,
    decay: 0.38,
    taps: 3,
  );
  withEcho = _applyEcho(
    withEcho,
    sampleRate: sampleRate,
    delayMs: 240,
    decay: 0.22,
    taps: 2,
  );

  _fadeOut(withEcho, sampleRate: sampleRate, ms: 140);
  return _normalize(withEcho, targetPeak: 0.72);
}

List<double> _applyEcho(
  List<double> samples, {
  required int sampleRate,
  required int delayMs,
  required double decay,
  required int taps,
}) {
  final delay = (sampleRate * delayMs / 1000).round();
  if (delay <= 0 || taps <= 0) return samples;

  final out = List<double>.from(samples);
  for (var tap = 1; tap <= taps; tap++) {
    final d = delay * tap;
    if (d >= out.length) break;
    final g = pow(decay, tap).toDouble();
    for (var i = d; i < out.length; i++) {
      out[i] += samples[i - d] * g;
    }
  }

  return out;
}

List<int> _encodeWavPcm16Mono({
  required List<double> samples,
  required int sampleRate,
}) {
  // 16-bit PCM mono
  const numChannels = 1;
  const bitsPerSample = 16;
  const blockAlign = numChannels * (bitsPerSample ~/ 8);
  final byteRate = sampleRate * blockAlign;

  final dataLength = samples.length * 2;
  final riffLength = 36 + dataLength;

  final bytes = BytesBuilder(copy: false);

  void writeAscii(String s) => bytes.add(s.codeUnits);
  void writeUint32LE(int v) {
    bytes.add(
      [v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF],
    );
  }

  void writeUint16LE(int v) {
    bytes.add([v & 0xFF, (v >> 8) & 0xFF]);
  }

  writeAscii('RIFF');
  writeUint32LE(riffLength);
  writeAscii('WAVE');

  // fmt chunk
  writeAscii('fmt ');
  writeUint32LE(16); // PCM
  writeUint16LE(1); // audio format = PCM
  writeUint16LE(numChannels);
  writeUint32LE(sampleRate);
  writeUint32LE(byteRate);
  writeUint16LE(blockAlign);
  writeUint16LE(bitsPerSample);

  // data chunk
  writeAscii('data');
  writeUint32LE(dataLength);

  for (final s in samples) {
    final clamped = s.clamp(-1.0, 1.0);
    final v = (clamped * 32767.0).round();
    // int16 LE
    bytes.add([v & 0xFF, (v >> 8) & 0xFF]);
  }

  return bytes.takeBytes();
}

double _adsr(
  int i,
  int n, {
  required double attack,
  required double decay,
  required double sustain,
  required double release,
}) {
  // Fractions of n.
  final aN = max(1, (n * attack).round());
  final dN = max(1, (n * decay).round());
  final rN = max(1, (n * release).round());
  final sStart = aN + dN;
  final rStart = max(sStart, n - rN);

  if (i < aN) {
    return i / aN;
  }
  if (i < sStart) {
    final t = (i - aN) / dN;
    return 1.0 + (sustain - 1.0) * t;
  }
  if (i < rStart) {
    return sustain;
  }
  final t = (i - rStart) / max(1, (n - rStart));
  return sustain * (1.0 - t);
}

double _expDecay(int i, int n, {required double halfLifeFraction}) {
  // halfLifeFraction=0.2 means amplitude halves after 20% of the sample length.
  final halfLife = max(1.0, n * halfLifeFraction);
  return pow(0.5, i / halfLife).toDouble();
}

void _fadeOut(
  List<double> samples, {
  required int sampleRate,
  required int ms,
}) {
  final n = (sampleRate * ms / 1000).round();
  if (n <= 1) return;
  final start = max(0, samples.length - n);
  for (var i = start; i < samples.length; i++) {
    final t = (i - start) / max(1, (samples.length - start - 1));
    final g = 1.0 - t;
    samples[i] *= g;
  }
}

List<double> _normalize(List<double> samples, {required double targetPeak}) {
  var peak = 0.0;
  for (final s in samples) {
    final a = s.abs();
    if (a > peak) peak = a;
  }
  if (peak <= 1e-9) return samples;
  final gain = targetPeak / peak;
  return samples.map((s) => s * gain).toList(growable: false);
}

// Cheap deterministic noise without RNG state.
double _hashNoise(int i) {
  var x = i;
  x = (x ^ 0x6C8E9CF5) * 0x2D51;
  x ^= (x >> 15);
  x *= 0x1B873593;
  x ^= (x >> 13);
  // 0..1
  return (x & 0x7FFFFFFF) / 0x7FFFFFFF;
}
