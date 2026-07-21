import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/common/damos_text_field.dart';
import '../../widgets/common/pop_up_alert.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? prefillEmail;

  const ForgotPasswordScreen({super.key, this.prefillEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const Color _bg = Color(0xFFFCF8F8);
  static const Color _primary = Color(0xFF018D1A);
  static const Color _dark = Color(0xFF111111);
  static const Color _grey = Color(0xFF555555);
  static const Color _red = Color(0xFFD32F2F);

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
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _dark),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _emailSent ? 'Cek Email Anda' : 'Lupa Password',
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: _dark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _emailSent ? _buildSuccess() : _buildForm(),
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
            fontFamily: 'Poppins',
            fontSize: 14,
            height: 1.5,
            color: _dark,
          ),
        ),
        const SizedBox(height: 20),
        DamosTextField(
          controller: _emailController,
          labelText: 'Email',
          hintText: 'Masukkan Alamat Email',
          prefixIcon: Icons.person_outline,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.email,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submitEmail(),
        ),
        if (_emailSubmitError != null) ...[
          const SizedBox(height: 8),
          Text(
            _emailSubmitError!,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: _red,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isSubmitting || _email.isEmpty ? null : _submitEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _primary.withValues(alpha: 0.55),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Kirim Link Reset',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
          ),
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
            color: _primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.mark_email_read_outlined, color: _primary, size: 32),
              const SizedBox(height: 12),
              Text(
                _successMessage,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  height: 1.5,
                  color: _dark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Email: $_email',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Buka email Anda, klik link reset password, lalu buat password baru di halaman reset.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            height: 1.45,
            color: _grey,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
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
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
