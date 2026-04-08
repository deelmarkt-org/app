/// Message types — per design system patterns.md §Chat.
enum MessageType {
  text,
  offer,
  systemAlert,
  scamWarning;

  /// Maps DB snake_case value to [MessageType]. Falls back to [text].
  static MessageType fromDb(String value) => switch (value) {
    'text' => MessageType.text,
    'offer' => MessageType.offer,
    'system_alert' => MessageType.systemAlert,
    'scam_warning' => MessageType.scamWarning,
    _ => MessageType.text,
  };

  String toDb() => switch (this) {
    MessageType.text => 'text',
    MessageType.offer => 'offer',
    MessageType.systemAlert => 'system_alert',
    MessageType.scamWarning => 'scam_warning',
  };
}
