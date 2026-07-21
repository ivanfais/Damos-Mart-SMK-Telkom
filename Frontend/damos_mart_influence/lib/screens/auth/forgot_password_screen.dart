import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_constants.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/common/pop_up_alert.dart';

enum _ForgotStep { email, code, newPassword }

class ForgotPasswordScreen extends StatefulWidget {
  final String? prefillEmail;

  const ForgotPasswordScreen({super.key, this.prefillEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const Color _primary = Color(0xFF1B8C2E);
  static const Color _fieldBorder = Color(0xFFD1D5DB);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _red = Color(0xFFD42427);
  static const Color _infoBg = Color(0xFFF0F9F1);

  final _authRepository = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _ForgotStep _step = _ForgotStep.email;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.prefillEmail != null && widget.prefillEmail!.isNotEmpty) {
      _emailController.text = widget.prefillEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _email => _emailController.text.trim();

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) {
      PopUpAlert.showIncompleteData(context);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _authRepository.requestPasswordReset(_email);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _step = _ForgotStep.code;
        _codeController.clear();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      PopUpAlert.show(context: context, title: 'Gagal', description: e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      PopUpAlert.show(
        context: context,
        title: 'Gagal',
        description: 'Terjadi kesalahan. Coba lagi ya.',
        isError: true,
      );
    }
  }

  void _submitCode() {
    if (!_formKey.currentState!.validate()) {
      PopUpAlert.showIncompleteData(context);
      return;
    }

    setState(() {
      _step = _ForgotStep.newPassword;
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  Future<void> _submitNewPassword() async {
    if (!_formKey.currentState!.validate()) {
      PopUpAlert.showIncompleteData(context);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _authRepository.resetPassword(
        email: _email,
        code: _codeController.text.trim(),
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      await PopUpAlert.showSuccess(
        context: context,
        title: 'Password Diperbarui',
        description: 'Password kamu berhasil diganti. Silakan login dengan password baru.',
      );

      if (mounted) {
        context.go('/login', extra: {'email': _email});
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      PopUpAlert.show(context: context, title: 'Gagal', description: e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      PopUpAlert.show(
        context: context,
        title: 'Gagal',
        description: 'Terjadi kesalahan. Coba lagi ya.',
        isError: true,
      );
    }
  }

  void _handleBack() {
    if (_step == _ForgotStep.code) {
      setState(() => _step = _ForgotStep.email);
      return;
    }
    if (_step == _ForgotStep.newPassword) {
      setState(() => _step = _ForgotStep.code);
      return;
    }
    context.pop();
  }

  String get _subtitle {
    switch (_step) {
      case _ForgotStep.email:
        return 'Masukkan email terdaftar untuk menerima kode verifikasi reset password.';
      case _ForgotStep.code:
        return 'Masukkan kode verifikasi 4 digit yang dikirim ke email kamu.';
      case _ForgotStep.newPassword:
        return 'Buat password baru untuk akun $_email.';
    }
  }

  String get _buttonLabel {
    switch (_step) {
      case _ForgotStep.email:
        return 'LANJUT';
      case _ForgotStep.code:
        return 'VERIFIKASI';
      case _ForgotStep.newPassword:
        return 'SIMPAN PASSWORD';
    }
  }

  VoidCallback? get _onSubmit {
    if (_isSubmitting) return null;
    switch (_step) {
      case _ForgotStep.email:
        return _submitEmail;
      case _ForgotStep.code:
        return _submitCode;
      case _ForgotStep.newPassword:
        return _submitNewPassword;
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    TextInputAction textInputAction = TextInputAction.done,
    void Function(String)? onFieldSubmitted,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    String? hintText,
  }) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          style: const TextStyle(fontSize: 14, color: _textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hintText,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: border(_fieldBorder, 1.2),
            focusedBorder: border(_primary, 1.5),
            errorBorder: border(_red, 1.2),
            focusedErrorBorder: border(_red, 1.5),
            suffixIcon: isPassword && onToggleObscure != null
                ? GestureDetector(
                    onTap: onToggleObscure,
                    child: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: _textSecondary,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case _ForgotStep.email:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submitEmail(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _infoBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primary.withValues(alpha: 0.2)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: _primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pastikan email sudah terdaftar di Damos Mart.',
                      style: TextStyle(fontSize: 13, height: 1.45, color: _textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case _ForgotStep.code:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildField(
              controller: _codeController,
              label: 'Kode Verifikasi',
              keyboardType: TextInputType.number,
              hintText: '••••',
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().length != 4) {
                  return 'Masukkan kode 4 digit ya!';
                }
                return null;
              },
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submitCode(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _infoBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primary.withValues(alpha: 0.2)),
              ),
              child: const Text(
                'Cek inbox email kamu. Kode berlaku 15 menit.',
                style: TextStyle(fontSize: 13, height: 1.45, color: _textSecondary),
              ),
            ),
          ],
        );
      case _ForgotStep.newPassword:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildField(
              controller: _passwordController,
              label: 'Password Baru',
              isPassword: true,
              obscure: _obscurePassword,
              onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
              validator: Validators.password,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),
            _buildField(
              controller: _confirmPasswordController,
              label: 'Konfirmasi Password Baru',
              isPassword: true,
              obscure: _obscureConfirmPassword,
              onToggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              validator: (value) => Validators.confirmPassword(value, _passwordController.text),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submitNewPassword(),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: _handleBack,
                    icon: const Icon(Icons.arrow_back, color: _textPrimary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 120,
                    height: 88,
                    child: Image.asset(
                      AppConstants.imageLogo,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.shopping_bag,
                        size: 56,
                        color: _primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Lupa Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'SMK Telkom Jakarta',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: _textSecondary),
                ),
                const SizedBox(height: 28),
                Text(
                  _subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, height: 1.5, color: _textSecondary),
                ),
                const SizedBox(height: 24),
                _buildStepContent(),
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _primary.withValues(alpha: 0.6),
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _buttonLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Ingat password? ',
                      style: TextStyle(fontSize: 14, color: _textPrimary),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: const Text(
                        'Kembali Login',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
