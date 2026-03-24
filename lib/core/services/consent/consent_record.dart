/// Privacy policy version — bump to trigger re-consent for all users.
/// Phase 2: read from Firebase Remote Config for dynamic updates.
const kPrivacyPolicyVersion = '1.0.0';

/// Level of cookie/tracking consent granted by the user.
enum ConsentLevel { allCookies, necessaryOnly }

/// Specific data processing purposes (GDPR Article 7(2)).
enum ConsentPurpose { essential, analytics, marketing }

/// Where consent was recorded.
enum ConsentSource { banner, settings }

/// Immutable GDPR consent record.
///
/// Stores what was consented to, when, in which language, and from where.
/// [isOutdated] returns true when [version] does not match
/// [kPrivacyPolicyVersion], triggering re-consent.
///
/// Phase 2 (reso): sync to backend for GDPR audit trail.
class ConsentRecord {
  const ConsentRecord({
    required this.level,
    required this.version,
    required this.timestamp,
    required this.locale,
    required this.source,
    required this.purposes,
  });

  final ConsentLevel level;
  final String version;
  final DateTime timestamp;
  final String locale;
  final ConsentSource source;
  final Map<ConsentPurpose, bool> purposes;

  bool isOutdated(String currentVersion) => version != currentVersion;

  Map<String, dynamic> toJson() => {
    'level': level.name,
    'version': version,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'locale': locale,
    'source': source.name,
    'purposes': {for (final e in purposes.entries) e.key.name: e.value},
  };

  factory ConsentRecord.fromJson(Map<String, dynamic> json) {
    return ConsentRecord(
      level: ConsentLevel.values.byName(json['level'] as String),
      version: json['version'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      locale: json['locale'] as String,
      source: ConsentSource.values.byName(json['source'] as String),
      purposes: (json['purposes'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(ConsentPurpose.values.byName(k), v as bool),
      ),
    );
  }
}
