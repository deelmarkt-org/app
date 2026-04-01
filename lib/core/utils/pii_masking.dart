/// PII masking utilities — extracted from AppLogger for §2.1 compliance.
///
/// Masks common PII patterns before logging: email, phone, IBAN, BSN.
abstract final class PiiMasker {
  /// Mask common PII patterns in [input].
  ///
  /// Replaces: email addresses, Dutch phone numbers (+31...),
  /// IBAN (NL...), BSN (9-digit sequences preceded by "BSN" label).
  static String mask(String input) {
    var masked = input;
    // Email
    masked = masked.replaceAll(
      RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+'),
      '***@***.***',
    );
    // Dutch phone (+31 or 06)
    masked = masked.replaceAll(RegExp(r'(\+31|0031|06)\d{8,9}'), '+31*****');
    // IBAN
    masked = masked.replaceAll(
      RegExp(r'[A-Z]{2}\d{2}[A-Z]{4}\d{10}'),
      'NL**BANK**********',
    );
    // BSN (Dutch citizen service number): 9 digits preceded by BSN context
    masked = masked.replaceAll(
      RegExp(r'[Bb][Ss][Nn][:\s]*\d{9}'),
      'BSN: *********',
    );
    return masked;
  }
}
