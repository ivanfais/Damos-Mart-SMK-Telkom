import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/auth/damos_auth_app_bar.dart';
import '../../widgets/auth/damos_auth_text_field.dart';
import '../../widgets/auth/password_requirements.dart';
import '../../widgets/common/pop_up_alert.dart';

enum _ForgotStep { email, code, newPassword }

class ForgotPasswordScreen extends StatefulWidget {
  final String? prefillEmail;

  const ForgotPasswordScreen({super.key, this.prefillEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const Color _primary = DamosDominanceColors.primary;
  static const Color _textPrimary = DamosDominanceColors.textPrimary;
  static const Color _textSecondary = DamosDominanceColors.textSecondary;
  static const Color _infoBg = Color(0xFFF0F9F1);
  static const String _dummyCode = '1234';

  final _authRepository = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _ForgotStep _step = _ForgotStep.email;
  bool _isSubmitting = false;
  bool _showValidation = false;
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
    setState(() => _showValidation = true);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _showValidation = false;
    });
    try {
      await _authRepository.forgotPassword(_email);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _step = _ForgotStep.code;
        _codeController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      PopUpAlert.show(
        context: context,
        title: 'Gagal',
        description: e.toString(),
        isError: true,
      );
    }
  }

  void _submitCode() {
    setState(() => _showValidation = true);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_codeController.text.trim() != _dummyCode) {
      PopUpAlert.show(
        context: context,
        title: 'Kode Salah',
        description: 'Kode verifikasi tidak valid. Coba lagi ya.',
        isError: true,
      );
      return;
    }

    setState(() {
      _step = _ForgotStep.newPassword;
      _passwordController.clear();
      _confirmPasswordController.clear();
      _showValidation = false;
    });
  }

  Future<void> _submitNewPassword() async {
    setState(() => _showValidation = true);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _authRepository.resetPasswordWithEmail(
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

      if (!mounted) return;
      context.go('/login', extra: {'email': _email});
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      PopUpAlert.show(
        context: context,
        title: 'Gagal',
        description: e.toString(),
        isError: true,
      );
    }
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
        return 'Kirim Reset Link';
      case _ForgotStep.code:
        return 'VERIFIKASI';
      case _ForgotStep.newPassword:
        return 'SIMPAN PERUBAHAN';
    }
  }

  bool get _canSubmit {
    if (_isSubmitting) return false;
    switch (_step) {
      case _ForgotStep.email:
        return Validators.authEmail(_email) == null;
      case _ForgotStep.code:
        return _codeController.text.trim().length == 4;
      case _ForgotStep.newPassword:
        return Validators.authPassword(_passwordController.text) == null &&
            _confirmPasswordController.text == _passwordController.text &&
            _confirmPasswordController.text.isNotEmpty;
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

  Widget _buildStepContent() {
    switch (_step) {
      case _ForgotStep.email:
        return Column(
          key: const ValueKey(_ForgotStep.email),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DamosAuthTextField(
              controller: _emailController,
              hintText: 'Masukkan Alamat Email',
              keyboardType: TextInputType.emailAddress,
              validator: Validators.authEmail,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _submitEmail(),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _infoBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primary.withOpacity(0.2)),
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
          key: const ValueKey(_ForgotStep.code),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DamosAuthTextField(
              controller: _codeController,
              hintText: 'Masukkan 4 digit kode',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().length != 4) {
                  return 'Masukkan kode 4 digit ya!';
                }
                return null;
              },
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _submitCode(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _infoBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primary.withOpacity(0.2)),
              ),
              child: Text(
                'Demo: gunakan kode $_dummyCode untuk verifikasi.',
                style: const TextStyle(fontSize: 13, height: 1.45, color: _textSecondary),
              ),
            ),
          ],
        );
      case _ForgotStep.newPassword:
        return Column(
          key: const ValueKey(_ForgotStep.newPassword),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DamosAuthTextField(
              controller: _passwordController,
              hintText: 'Password Baru',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
              validator: Validators.authPassword,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            PasswordRequirements(password: _passwordController.text),
            const SizedBox(height: 16),
            DamosAuthTextField(
              controller: _confirmPasswordController,
              hintText: 'Konfirmasi Password Baru',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscureConfirmPassword,
              onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Konfirmasi password wajib diisi';
                }
                if (value != _passwordController.text) {
                  return 'Password baru yang anda masukkan tidak sesuai';
                }
                return null;
              },
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _submitNewPassword(),
            ),
          ],
        );
    }
  }

  String get _appBarTitle {
    switch (_step) {
      case _ForgotStep.email:
        return 'Lupa Password';
      case _ForgotStep.code:
        return 'Verifikasi Kode';
      case _ForgotStep.newPassword:
        return 'Reset Password';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DamosDominanceColors.background,
      appBar: DamosAuthAppBar(title: _appBarTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            autovalidateMode: _showValidation ? AutovalidateMode.always : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  _subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, height: 1.5, color: _textSecondary),
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _buildStepContent(),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _canSubmit
                          ? [
                              BoxShadow(
                                color: _primary.withOpacity(0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                      onPressed: _onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
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
                ),
                const SizedBox(height: 18),
                if (_step == _ForgotStep.email) ...[
                  const SizedBox(height: 12),
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
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
