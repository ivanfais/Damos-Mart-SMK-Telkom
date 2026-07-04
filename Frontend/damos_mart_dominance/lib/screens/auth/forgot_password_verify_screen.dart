import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/auth/damos_auth_app_bar.dart';
import '../../widgets/auth/damos_auth_text_field.dart';
import '../../widgets/common/pop_up_alert.dart';

class ForgotPasswordVerifyScreen extends StatefulWidget {
  final String email;

  const ForgotPasswordVerifyScreen({
    super.key,
    required this.email,
  });

  @override
  State<ForgotPasswordVerifyScreen> createState() => _ForgotPasswordVerifyScreenState();
}

class _ForgotPasswordVerifyScreenState extends State<ForgotPasswordVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repository = AuthRepository();
  bool _isSubmitting = false;

  bool get _canSubmit {
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    return code.length == 4 && password.length >= 6;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final message = await _repository.resetPasswordWithEmail(
        email: widget.email,
        code: _codeController.text.trim(),
        newPassword: _passwordController.text,
      );
      if (!mounted) return;

      await PopUpAlert.showSuccess(
        context: context,
        title: 'Password Diperbarui',
        description: message,
      );
      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      PopUpAlert.show(
        context: context,
        title: 'Gagal Reset Password',
        description: e.toString(),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DamosDominanceColors.background,
      appBar: const DamosAuthAppBar(title: 'Verifikasi Kode'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Kode 4 digit dikirim ke ${widget.email}. Gunakan kode demo 1234.',
                style: const TextStyle(
                  fontSize: 14,
                  color: DamosDominanceColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              DamosAuthTextField(
                controller: _codeController,
                hintText: 'Masukkan Kode 4 Digit',
                prefixIcon: Icons.security,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().length != 4) {
                    return 'Kode verifikasi harus 4 digit';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              DamosAuthTextField(
                controller: _passwordController,
                hintText: 'Password Baru',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) {
                  if (_canSubmit && !_isSubmitting) _submit();
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _canSubmit && !_isSubmitting ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DamosDominanceColors.primary,
                    foregroundColor: DamosDominanceColors.textOnPrimary,
                    disabledBackgroundColor: DamosDominanceColors.buttonDisabledFill,
                    disabledForegroundColor: DamosDominanceColors.buttonDisabledText,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text(
                          'Simpan Password',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
