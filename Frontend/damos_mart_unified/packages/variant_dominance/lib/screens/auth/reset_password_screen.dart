import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/password_rules.dart';
import '../../data/repositories/auth_repository.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/auth/damos_auth_app_bar.dart';
import '../../widgets/auth/damos_auth_text_field.dart';
import '../../widgets/auth/password_requirements.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/pop_up_alert.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.token,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _repository = AuthRepository();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  bool _isValidating = true;
  bool _tokenValid = false;

  @override
  void initState() {
    super.initState();
    _validateToken();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _validateToken() async {
    if (widget.token.isEmpty) {
      setState(() {
        _isValidating = false;
        _tokenValid = false;
      });
      return;
    }

    try {
      final valid = await _repository.validateResetToken(widget.token);
      if (!mounted) return;
      setState(() {
        _isValidating = false;
        _tokenValid = valid;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isValidating = false;
        _tokenValid = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final message = await _repository.resetPassword(
        token: widget.token,
        newPassword: _passwordController.text,
        confirmPassword: _confirmController.text,
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
    if (_isValidating) {
      return Scaffold(
        backgroundColor: DamosDominanceColors.background,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              SizedBox(height: 48),
              LoadingShimmer(width: 180, height: 28, borderRadius: 8),
              SizedBox(height: 24),
              LoadingShimmer(width: double.infinity, height: 48, borderRadius: 8),
              SizedBox(height: 16),
              LoadingShimmer(width: double.infinity, height: 48, borderRadius: 8),
              SizedBox(height: 16),
              LoadingShimmer(width: double.infinity, height: 48, borderRadius: 8),
            ],
          ),
        ),
      );
    }

    if (!_tokenValid) {
      return Scaffold(
        backgroundColor: DamosDominanceColors.background,
        appBar: const DamosAuthAppBar(title: 'Reset Password'),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Link reset password tidak valid atau sudah kedaluwarsa.',
                style: TextStyle(
                  fontSize: 14,
                  color: DamosDominanceColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => context.go('/forgot-password'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DamosDominanceColors.primary,
                    foregroundColor: DamosDominanceColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Minta Link Baru',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: DamosDominanceColors.background,
      appBar: const DamosAuthAppBar(title: 'Reset Password'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DamosAuthTextField(
                controller: _passwordController,
                hintText: 'Password Baru',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                onToggleVisibility: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                validator: PasswordRules.validate,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              PasswordRequirements(password: _passwordController.text),
              const SizedBox(height: 16),
              DamosAuthTextField(
                controller: _confirmController,
                hintText: 'Konfirmasi Password Baru',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureConfirm,
                onToggleVisibility: () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                },
                textInputAction: TextInputAction.done,
                validator: (value) => PasswordRules.confirm(value, _passwordController.text),
                onFieldSubmitted: (_) {
                  if (!_isSubmitting) _submit();
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DamosDominanceColors.primary,
                    foregroundColor: DamosDominanceColors.textOnPrimary,
                    disabledBackgroundColor:
                        DamosDominanceColors.primary.withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              DamosDominanceColors.textOnPrimary,
                            ),
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan',
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
