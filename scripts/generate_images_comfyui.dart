import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main(List<String> args) async {
  final parsed = _parseArgs(args);
  if (parsed.containsKey('help') || parsed.containsKey('h') || args.isEmpty) {
    _printHelp();
    exit(0);
  }

  final server = Uri.parse(parsed['server'] ?? 'http://127.0.0.1:8188');
  final workflowPath = parsed['workflow'];
  final promptText = parsed['prompt'];
  final negativePromptText = parsed['negative'] ?? parsed['neg'];
  final outDir = parsed['out'] ?? 'assets/images/generated';
  final count = int.tryParse(parsed['count'] ?? parsed['n'] ?? '1') ?? 1;

  if (workflowPath == null || promptText == null) {
    stderr.writeln('Missing required args: --workflow and --prompt');
    _printHelp();
    exit(2);
  }

  final workflowFile = File(workflowPath);
  if (!workflowFile.existsSync()) {
    stderr.writeln('Workflow file not found: $workflowPath');
    exit(2);
  }

  final graphDynamic = jsonDecode(workflowFile.readAsStringSync());
  if (graphDynamic is! Map<String, dynamic>) {
    stderr.writeln('Workflow JSON must be an object (API-format graph).');
    exit(2);
  }

  final graph = _deepCopyMap(graphDynamic);

  final seedArg = parsed['seed'];
  final stepsArg = parsed['steps'];
  final cfgArg = parsed['cfg'];
  final widthArg = parsed['width'];
  final heightArg = parsed['height'];
  final batchArg = parsed['batch'];

  final seed = seedArg == null ? null : int.tryParse(seedArg);
  final steps = stepsArg == null ? null : int.tryParse(stepsArg);
  final width = widthArg == null ? null : int.tryParse(widthArg);
  final height = heightArg == null ? null : int.tryParse(heightArg);
  final batch = batchArg == null ? null : int.tryParse(batchArg);
  final cfg = cfgArg == null ? null : double.tryParse(cfgArg);

  _applyPromptPlaceholders(
    graph,
    promptText: promptText,
    negativePromptText: negativePromptText,
  );

  _applyCommonNumericOverrides(
    graph,
    seed: seed,
    steps: steps,
    cfg: cfg,
    width: width,
    height: height,
    batch: batch,
  );

  Directory(outDir).createSync(recursive: true);

  final clientId = _randomClientId();

  final imagesSaved = <String>[];
  for (var i = 0; i < count; i++) {
    final runSeed = seed ?? Random.secure().nextInt(1 << 31);
    _applyCommonNumericOverrides(graph, seed: runSeed);

    stdout.writeln(
        '[ComfyUI] Generating image ${i + 1}/$count (seed=$runSeed)...');

    final promptId = await _submitPrompt(server, graph, clientId: clientId);
    final outputs = await _waitForOutputs(server, promptId);

    final downloaded = await _downloadAllImages(server, outputs);
    if (downloaded.isEmpty) {
      stderr.writeln('[ComfyUI] No images returned for prompt_id=$promptId');
      continue;
    }

    for (final img in downloaded) {
      final ext = img.extension;
      final fileName = _buildOutputName(
        promptText: promptText,
        seed: runSeed,
        index: imagesSaved.length + 1,
        extension: ext,
      );
      final filePath = '$outDir/$fileName';
      File(filePath).writeAsBytesSync(img.bytes);
      imagesSaved.add(filePath);
      stdout.writeln('[ComfyUI] Saved: $filePath');
    }
  }

  if (imagesSaved.isEmpty) {
    stderr.writeln(
        'No images saved. Check that ComfyUI is running and your workflow outputs images.');
    exit(1);
  }

  stdout.writeln('Done. Saved ${imagesSaved.length} image(s).');
}

void _printHelp() {
  stdout.writeln('''
Generate PNG/JPG via ComfyUI (local) and save into assets.

Required:
  --workflow <path>   Path to ComfyUI workflow exported in "API format" (JSON)
  --prompt  <text>    Positive prompt

Optional:
  --server <url>      Default: http://127.0.0.1:8188
  --negative <text>   Negative prompt (requires __NEGATIVE_PROMPT__ placeholder)
  --out <dir>         Default: assets/images/generated
  --count <n>         Number of generations (default 1)
  --seed <int>        If omitted, uses random seed per image
  --steps <int>       Overrides KSampler steps (if present)
  --cfg <double>      Overrides KSampler cfg (if present)
  --width <int>       Overrides EmptyLatentImage width (if present)
  --height <int>      Overrides EmptyLatentImage height (if present)
  --batch <int>       Overrides EmptyLatentImage batch_size (if present)

Workflow placeholders (recommended):
  Put these exact strings in your workflow text fields before exporting:
    __POSITIVE_PROMPT__
    __NEGATIVE_PROMPT__

Example:
  dart run scripts/generate_images_comfyui.dart --workflow scripts/comfyui/workflows/txt2img_api.json --prompt "cute friendly space mascot, flat vector, kids app" --negative "scary, gore, realistic" --width 1024 --height 1024 --steps 25 --cfg 6.5 --count 4
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

String _randomClientId() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rand = Random.secure();
  return List.generate(16, (_) => chars[rand.nextInt(chars.length)]).join();
}

Map<String, dynamic> _deepCopyMap(Map<String, dynamic> input) {
  return jsonDecode(jsonEncode(input)) as Map<String, dynamic>;
}

void _applyPromptPlaceholders(
  Map<String, dynamic> graph, {
  required String promptText,
  String? negativePromptText,
}) {
  dynamic replace(dynamic value) {
    if (value is Map) {
      final m = <String, dynamic>{};
      for (final entry in value.entries) {
        m[entry.key.toString()] = replace(entry.value);
      }
      return m;
    }
    if (value is List) {
      return value.map(replace).toList();
    }
    if (value is String) {
      if (value == '__POSITIVE_PROMPT__') return promptText;
      if (value == '__NEGATIVE_PROMPT__') return negativePromptText ?? '';
    }
    return value;
  }

  final replaced = replace(graph);
  if (replaced is Map<String, dynamic>) {
    graph
      ..clear()
      ..addAll(replaced);
  }

  final hasPositive = _containsString(graph, promptText);
  if (!hasPositive) {
    // Fallback: set first CLIPTextEncode node text if no placeholders were used.
    for (final node in graph.values) {
      if (node is! Map) continue;
      final classType = node['class_type'];
      if (classType is! String) continue;
      if (!classType.startsWith('CLIPTextEncode')) continue;
      final inputs = node['inputs'];
      if (inputs is! Map) continue;
      if (inputs['text'] is String) {
        inputs['text'] = promptText;
        break;
      }
    }
  }
}

bool _containsString(dynamic value, String needle) {
  if (value is Map) {
    return value.values.any((v) => _containsString(v, needle));
  }
  if (value is List) {
    return value.any((v) => _containsString(v, needle));
  }
  if (value is String) {
    return value == needle;
  }
  return false;
}

void _applyCommonNumericOverrides(
  Map<String, dynamic> graph, {
  int? seed,
  int? steps,
  double? cfg,
  int? width,
  int? height,
  int? batch,
}) {
  for (final node in graph.values) {
    if (node is! Map) continue;
    final classType = node['class_type'];
    if (classType is! String) continue;
    final inputs = node['inputs'];
    if (inputs is! Map) continue;

    if (classType == 'KSampler') {
      if (seed != null) inputs['seed'] = seed;
      if (steps != null) inputs['steps'] = steps;
      if (cfg != null) inputs['cfg'] = cfg;
    }

    if (classType == 'KSamplerAdvanced') {
      if (seed != null) inputs['noise_seed'] = seed;
      if (steps != null) inputs['steps'] = steps;
      if (cfg != null) inputs['cfg'] = cfg;
    }

    if (classType == 'EmptyLatentImage') {
      if (width != null) inputs['width'] = width;
      if (height != null) inputs['height'] = height;
      if (batch != null) inputs['batch_size'] = batch;
    }
  }
}

Future<String> _submitPrompt(Uri server, Map<String, dynamic> graph,
    {required String clientId}) async {
  final uri = server.replace(path: '/prompt');

  final body = jsonEncode({
    'prompt': graph,
    'client_id': clientId,
  });

  final response = await _httpJson('POST', uri, body: body);
  final promptId = response['prompt_id'];
  if (promptId is! String || promptId.isEmpty) {
    throw StateError(
        'ComfyUI /prompt did not return prompt_id. Response: $response');
  }
  return promptId;
}

Future<Map<String, dynamic>> _waitForOutputs(
    Uri server, String promptId) async {
  final uri = server.replace(path: '/history/$promptId');
  final deadline = DateTime.now().add(const Duration(minutes: 5));

  while (DateTime.now().isBefore(deadline)) {
    try {
      final res = await _httpJson('GET', uri);
      final item = res[promptId];
      if (item is Map && item['outputs'] is Map) {
        return (item['outputs'] as Map).cast<String, dynamic>();
      }
    } catch (_) {
      // History endpoint may 404 briefly; keep polling.
    }

    await Future<void>.delayed(const Duration(milliseconds: 700));
  }

  throw TimeoutException(
      'Timed out waiting for ComfyUI outputs for prompt_id=$promptId');
}

class _DownloadedImage {
  _DownloadedImage(this.bytes, {required this.extension});
  final List<int> bytes;
  final String extension;
}

Future<List<_DownloadedImage>> _downloadAllImages(
    Uri server, Map<String, dynamic> outputs) async {
  final result = <_DownloadedImage>[];

  for (final output in outputs.values) {
    if (output is! Map) continue;
    final images = output['images'];
    if (images is! List) continue;

    for (final img in images) {
      if (img is! Map) continue;
      final filename = img['filename'];
      final subfolder = img['subfolder'];
      final type = img['type'];

      if (filename is! String || filename.isEmpty) continue;

      final viewUri = server.replace(
        path: '/view',
        queryParameters: {
          'filename': filename,
          if (subfolder is String && subfolder.isNotEmpty)
            'subfolder': subfolder,
          if (type is String && type.isNotEmpty) 'type': type,
        },
      );

      final bytes = await _httpBytes('GET', viewUri);
      final extension = _guessExtension(filename, bytes);
      result.add(_DownloadedImage(bytes, extension: extension));
    }
  }

  return result;
}

String _guessExtension(String filename, List<int> bytes) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return 'png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'jpg';

  // Magic bytes fallback.
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'png';
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'jpg';
  }
  return 'png';
}

String _buildOutputName({
  required String promptText,
  required int seed,
  required int index,
  required String extension,
}) {
  final safe = promptText
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final prefix = safe.isEmpty ? 'image' : safe;
  return '${prefix.substring(0, min(prefix.length, 48))}_seed${seed}_$index.$extension';
}

Future<Map<String, dynamic>> _httpJson(String method, Uri uri,
    {String? body}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (body != null) {
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.add(utf8.encode(body));
    }

    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('HTTP ${response.statusCode} calling $uri: $text');
    }

    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      throw FormatException('Expected JSON object from $uri, got: $decoded');
    }
    return decoded.cast<String, dynamic>();
  } finally {
    client.close(force: true);
  }
}

Future<List<int>> _httpBytes(String method, Uri uri) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, uri);
    final response = await request.close();
    final bytes =
        await response.fold<List<int>>(<int>[], (a, b) => a..addAll(b));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('HTTP ${response.statusCode} calling $uri');
    }

    return bytes;
  } finally {
    client.close(force: true);
  }
}
