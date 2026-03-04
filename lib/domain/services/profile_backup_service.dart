import 'dart:convert';

class ProfileBackup {
  const ProfileBackup({
    required this.schemaVersion,
    required this.userId,
    required this.userData,
    required this.quizHistory,
  });

  final int schemaVersion;
  final String userId;
  final Map<String, dynamic> userData;
  final List<Map<String, dynamic>> quizHistory;
}

/// Pure utility for validating and parsing profile backup payloads.
///
/// This makes backup/restore safer by failing early on corrupted or
/// incompatible payloads.
class ProfileBackupService {
  static const int currentSchemaVersion = 1;

  String encode(ProfileBackup backup) {
    final map = <String, dynamic>{
      'schemaVersion': backup.schemaVersion,
      'userId': backup.userId,
      'userData': backup.userData,
      'quizHistory': backup.quizHistory,
    };
    return jsonEncode(map);
  }

  ProfileBackup decode(
    String json, {
    int minSupportedVersion = 1,
    int maxSupportedVersion = currentSchemaVersion,
  }) {
    final dynamic parsed;
    try {
      parsed = jsonDecode(json);
    } catch (_) {
      throw const FormatException('Backup payload is not valid JSON');
    }

    if (parsed is! Map) {
      throw const FormatException('Backup payload must be a JSON object');
    }

    final map = Map<String, dynamic>.from(parsed);

    final version = map['schemaVersion'];
    if (version is! int) {
      throw const FormatException('Missing or invalid schemaVersion');
    }
    if (version < minSupportedVersion || version > maxSupportedVersion) {
      throw FormatException('Unsupported backup schema version: $version');
    }

    final userId = map['userId'];
    if (userId is! String || userId.isEmpty) {
      throw const FormatException('Missing or invalid userId');
    }

    final userDataRaw = map['userData'];
    if (userDataRaw is! Map) {
      throw const FormatException('Missing or invalid userData');
    }
    final userData = Map<String, dynamic>.from(userDataRaw);
    final userName = userData['name'];
    if (userName is! String || userName.trim().isEmpty) {
      throw const FormatException('Missing or invalid userData.name');
    }

    final quizHistoryRaw = map['quizHistory'];
    if (quizHistoryRaw is! List) {
      throw const FormatException('Missing or invalid quizHistory');
    }

    final quizHistory = <Map<String, dynamic>>[];
    for (final item in quizHistoryRaw) {
      if (item is! Map) {
        throw const FormatException('quizHistory contains invalid entries');
      }
      final session = Map<String, dynamic>.from(item);
      final sessionId = session['sessionId'];
      if (sessionId is! String || sessionId.trim().isEmpty) {
        throw const FormatException(
            'quizHistory entry missing valid sessionId');
      }
      quizHistory.add(session);
    }

    return ProfileBackup(
      schemaVersion: version,
      userId: userId,
      userData: userData,
      quizHistory: quizHistory,
    );
  }
}
