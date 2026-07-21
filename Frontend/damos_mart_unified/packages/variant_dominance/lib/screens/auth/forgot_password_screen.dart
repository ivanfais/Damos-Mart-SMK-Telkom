import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/auth/damos_auth_app_bar.dart';
import '../../widgets/auth/damos_auth_text_field.dart';

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

  final _authRepository = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isSubmitting = false;
  bool _showValidation = false;
  bool _emailSent = false;
  String? _emailSubmitError;
  String _successMessage =
      'Link reset password telah dikirim ke email Anda. Periksa kotak masuk Gmail Anda.';

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
      _emailSubmitError = null;
    });

    try {
      final message = await _authRepository.forgotPassword(_email);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _emailSent = true;
        _successMessage = message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _emailSubmitError = _resolveEmailSubmitError(e);
      });
    }
  }

  String _resolveEmailSubmitError(Object error) {
    if (error is ApiException) {
      if (error.code == 'USER_NOT_FOUND' ||
          error.message.contains('Email tidak terdaftar')) {
        return 'Email tidak terdaftar';
      }
      return error.message;
    }
    return 'Email tidak terdaftar';
  }

  Widget _buildEmailForm() {
    return Column(
      key: const ValueKey('forgot-password-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Masukkan email terdaftar Anda. Kami akan mengirim link reset password ke Gmail Anda.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        DamosAuthTextField(
          controller: _emailController,
          hintText: 'Masukkan Alamat Email',
          prefixIcon: Icons.person_outline,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.authEmail,
          textInputAction: TextInputAction.done,
          showErrorState: _emailSubmitError != null,
          onChanged: (_) => setState(() {
            _emailSubmitError = null;
          }),
          onFieldSubmitted: (_) => _submitEmail(),
        ),
        if (_emailSubmitError != null) ...[
          const SizedBox(height: 8),
          Text(
            _emailSubmitError!,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: DamosDominanceColors.error,
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isSubmitting || _email.isEmpty ? null : _submitEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _email.isNotEmpty ? _primary : DamosDominanceColors.fieldFill,
              foregroundColor:
                  _email.isNotEmpty ? Colors.white : _textPrimary,
              disabledBackgroundColor: DamosDominanceColors.fieldFill,
              disabledForegroundColor: _textPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: _email.isEmpty
                      ? DamosDominanceColors.fieldBorder
                      : Colors.transparent,
                ),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(_primary),
                    ),
                  )
                : const Text(
                    'Kirim Link Reset',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      key: const ValueKey('forgot-password-success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DamosDominanceColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DamosDominanceColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.mark_email_read_outlined,
                color: _primary,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                _successMessage,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Email: $_email',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Buka email Anda, klik link reset password, lalu buat password baru di halaman reset.',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: _textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () => context.go('/login', extra: {'email': _email}),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Kembali ke Login',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: DamosAuthAppBar(
        title: _emailSent ? 'Cek Email Anda' : 'Lupa Password',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            autovalidateMode: _showValidation
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _emailSent ? _buildSuccessState() : _buildEmailForm(),
            ),
          ),
        ),
      ),
    );
  }
}
