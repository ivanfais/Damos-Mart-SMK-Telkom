import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/auth/auth_shell.dart';
import '../../widgets/common/pop_up_alert.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

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
      final message = await _repository.resetPasswordWithToken(
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
      return const Scaffold(
        backgroundColor: AuthShell.background,
        body: Center(
          child: CircularProgressIndicator(color: AuthShell.primary),
        ),
      );
    }

    if (!_tokenValid) {
      return Scaffold(
        backgroundColor: AuthShell.background,
        appBar: AppBar(
          backgroundColor: AuthShell.background,
          elevation: 0,
          title: const Text(
            'Reset Password',
            style: TextStyle(
              color: AuthShell.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Link reset password tidak valid atau sudah kedaluwarsa.',
                style: TextStyle(fontSize: 14, color: AuthShell.textPrimary),
              ),
              const SizedBox(height: 20),
              AuthPrimaryButton(
                label: 'Minta Link Baru',
                onPressed: () => context.go('/forgot-password'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AuthShell.background,
      appBar: AppBar(
        backgroundColor: AuthShell.background,
        elevation: 0,
        title: const Text(
          'Reset Password',
          style: TextStyle(
            color: AuthShell.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthInputField(
                controller: _passwordController,
                hintText: 'Password Baru',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscurePassword,
                onToggleVisibility: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                validator: Validators.password,
              ),
              const SizedBox(height: 16),
              AuthInputField(
                controller: _confirmController,
                hintText: 'Konfirmasi Password Baru',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscureConfirm,
                onToggleVisibility: () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                },
                textInputAction: TextInputAction.done,
                validator: (value) =>
                    Validators.confirmPassword(value, _passwordController.text),
                onFieldSubmitted: (_) {
                  if (!_isSubmitting) _submit();
                },
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'Simpan Perubahan',
                onPressed: _isSubmitting ? null : _submit,
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
