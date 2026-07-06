class Validators {
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? "Kolom ini"} wajib diisi ya! ⚠️';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi ya! ⚠️';
    }
    
    // Regular expression for email validation
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegExp.hasMatch(value)) {
      return 'Format email kamu sepertinya salah nih 😅';
    }
    return null;
  }

  static String? schoolEmail(String? value) {
    final emailError = email(value);
    if (emailError != null) return emailError;

    if (!value!.endsWith('@smktelkom-jkt.sch.id') && 
        !value.endsWith('@smktelkom-jkt.sc.id') && 
        !value.endsWith('@damosmart.com')) {
      return 'Gunakan email sekolah (@smktelkom-jkt.sch.id) ya! 🏫';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi ya! ⚠️';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter ya! 🔒';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor telepon wajib diisi ya! ⚠️';
    }
    final phoneRegExp = RegExp(r'^[0-9]{10,14}$');
    if (!phoneRegExp.hasMatch(value)) {
      return 'Masukkan nomor telepon yang valid ya (10-14 angka) 📞';
    }
    return null;
  }

  static String? emailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email atau nomor telepon wajib diisi ya! ⚠️';
    }
    final trimmed = value.trim();
    if (trimmed.contains('@')) {
      return email(trimmed);
    }
    return phone(trimmed.replaceAll(RegExp(r'[\s-]'), ''));
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password wajib diisi ya! ⚠️';
    }
    if (value != password) {
      return 'Password konfirmasi tidak cocok nih 😅';
    }
    return null;
  }
}
