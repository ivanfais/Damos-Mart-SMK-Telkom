import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/auth/auth_shell.dart';
import '../../widgets/common/pop_up_alert.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.prefillContact});

  final String? prefillContact;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authRepository = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isSubmitting = false;
  bool _emailSent = false;
  String? _emailSubmitError;
  String _successMessage =
      'Link reset password telah dikirim ke email Anda. Periksa kotak masuk Gmail Anda.';

  @override
  void initState() {
    super.initState();
    if (widget.prefillContact != null && widget.prefillContact!.isNotEmpty) {
      _emailController.text = widget.prefillContact!;
    }
    _emailController.addListener(() {
      if (_emailSubmitError != null) {
        setState(() => _emailSubmitError = null);
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String get _email => _emailController.text.trim();

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) {
      PopUpAlert.showIncompleteData(context);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _emailSubmitError = null;
    });

    try {
      final message = await _authRepository.requestPasswordReset(_email);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _emailSent = true;
        _successMessage = message;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _emailSubmitError = e.message.contains('tidak terdaftar')
            ? 'Email tidak terdaftar'
            : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _emailSubmitError = 'Gagal mengirim link reset password';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthShell.background,
      appBar: AppBar(
        backgroundColor: AuthShell.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AuthShell.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _emailSent ? 'Cek Email Anda' : 'Lupa Kata Sandi',
          style: const TextStyle(
            color: AuthShell.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AuthShell.border),
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Form(
                key: _formKey,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _emailSent ? _buildSuccess() : _buildForm(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Masukkan email terdaftar Anda. Kami akan mengirim link reset password ke Gmail Anda.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AuthShell.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        AuthInputField(
          controller: _emailController,
          hintText: 'Masukkan Alamat Email',
          prefixIcon: Icons.person_outline,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          validator: Validators.email,
          onFieldSubmitted: (_) => _submitEmail(),
        ),
        if (_emailSubmitError != null) ...[
          const SizedBox(height: 8),
          Text(
            _emailSubmitError!,
            style: const TextStyle(color: Color(0xFFD42427), fontSize: 12),
          ),
        ],
        const SizedBox(height: 20),
        AuthPrimaryButton(
          label: 'Kirim Link Reset',
          onPressed: _isSubmitting || _email.isEmpty ? null : _submitEmail,
          isLoading: _isSubmitting,
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      key: const ValueKey('success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AuthShell.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AuthShell.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.mark_email_read_outlined,
                color: AuthShell.primary,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                _successMessage,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AuthShell.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Email: $_email',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AuthShell.textSecondary,
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
            color: AuthShell.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        AuthPrimaryButton(
          label: 'Kembali ke Login',
          onPressed: () => context.go('/login', extra: {'email': _email}),
        ),
      ],
    );
  }
}
