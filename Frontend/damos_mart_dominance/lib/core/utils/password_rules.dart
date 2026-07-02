class PasswordRules {
  static bool hasMinLength(String value) => value.length >= 8;

  static bool hasUppercase(String value) => RegExp(r'[A-Z]').hasMatch(value);

  static bool hasDigit(String value) => RegExp(r'[0-9]').hasMatch(value);

  static bool hasSymbol(String value) => RegExp(r'[@$!]').hasMatch(value);

  static bool isValid(String value) =>
      hasMinLength(value) &&
      hasUppercase(value) &&
      hasDigit(value) &&
      hasSymbol(value);

  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }
    if (!isValid(value)) {
      return 'Password belum memenuhi persyaratan';
    }
    return null;
  }

  static String? confirm(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }
    if (value != password) {
      return 'Konfirmasi password tidak cocok';
    }
    return null;
  }
}
