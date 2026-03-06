/// Configuration for PIN recovery via security question only.
class PinRecoveryConfig {
  const PinRecoveryConfig({
    required this.securityQuestion,
    required this.securityAnswerHash,
    this.createdAt,
  });

  /// The security question (plaintext, shown to user)
  final String securityQuestion;

  /// BCrypt hash of the answer (case-insensitive lowercase)
  final String securityAnswerHash;

  /// When this recovery config was created (for potential rotation)
  final DateTime? createdAt;

  PinRecoveryConfig copyWith({
    String? securityQuestion,
    String? securityAnswerHash,
    DateTime? createdAt,
  }) {
    return PinRecoveryConfig(
      securityQuestion: securityQuestion ?? this.securityQuestion,
      securityAnswerHash: securityAnswerHash ?? this.securityAnswerHash,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => '''PinRecoveryConfig(
    question: $securityQuestion,
    createdAt: $createdAt
  )''';
}

/// Default security questions suitable for parents of children
const defaultSecurityQuestions = <String>[
  'Vad är ditt barns favoritfärg?',
  'I vilken stad är du född?',
  'Vad heter ditt favoritdjur?',
  'Vilket är ditt favoritår för semestern?',
  'Vad är namnet på ditt första husdjur?',
  'I vilken månad är du född?',
  'Vad är ditt favoritfilmgenre?',
  'Vilket sport är ditt favoritlag?',
  'Vad är namnet på ditt favoritmat?',
  'I vilken åttonde födelsedag hände något minnes värdigt?',
];
