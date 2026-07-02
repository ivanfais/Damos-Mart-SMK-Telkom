import 'package:flutter/material.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/auth/damos_auth_app_bar.dart';
import '../../widgets/auth/damos_auth_text_field.dart';
import '../../widgets/common/pop_up_alert.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _repository = AuthRepository();
  bool _isSubmitting = false;

  bool get _canSubmit {
    final email = _emailController.text.trim();
    return email.isNotEmpty && Validators.authEmail(email) == null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final message = await _repository.forgotPassword(_emailController.text.trim());
      if (!mounted) return;

      await PopUpAlert.showSuccess(
        context: context,
        title: 'Link Terkirim',
        description: message,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      PopUpAlert.show(
        context: context,
        title: 'Gagal Mengirim Link',
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
      appBar: const DamosAuthAppBar(title: 'Lupa Password'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Masukkan email Anda untuk reset password',
                style: TextStyle(
                  fontSize: 14,
                  color: DamosDominanceColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              DamosAuthTextField(
                controller: _emailController,
                hintText: 'Masukkan Alamat Email',
                prefixIcon: Icons.person_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                validator: Validators.authEmail,
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) {
                  if (_canSubmit && !_isSubmitting) _submit();
                },
              ),
              const SizedBox(height: 20),
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
                      side: BorderSide(
                        color: _canSubmit
                            ? DamosDominanceColors.primary
                            : DamosDominanceColors.buttonDisabledBorder,
                      ),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text(
                          'Kirim Reset Link',
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
