import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../core/utils/validators.dart';
import '../../widgets/common/damos_button.dart';
import '../../widgets/common/damos_text_field.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../config/app_constants.dart';

class LoginScreen extends StatefulWidget {
  final String? prefillEmail;
  final bool justRegistered;

  const LoginScreen({
    super.key,
    this.prefillEmail,
    this.justRegistered = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _bg       = Color(0xFFFCF8F8);
  static const Color _primary  = Color(0xFF018D1A);
  static const Color _border   = Color(0xFFCCCCCC);
  static const Color _dark     = Color(0xFF111111);
  static const Color _grey     = Color(0xFF555555);
  static const Color _red      = Color(0xFFD32F2F);

  final _formKey            = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _ssoController      = TextEditingController();
  bool _obscurePassword     = true;

  @override
  void initState() {
    super.initState();
    if (widget.prefillEmail != null && widget.prefillEmail!.isNotEmpty) {
      _emailController.text = widget.prefillEmail!;
    }
    if (widget.justRegistered) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        PopUpAlert.showSuccess(
          context: context,
          title: 'Daftar Berhasil!',
          description: 'Akun Anda sudah dibuat. Silakan login dengan email dan password.',
        );
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _ssoController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(LoginSubmitted(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    ));
  }

  void _showLoginSuccess(BuildContext ctx) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => const _LoginSuccessPopup(),
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (ctx.mounted) {
        Navigator.of(ctx, rootNavigator: true).pop();
        ctx.go('/home');
      }
    });
  }

  void _showSsoDialog() {
    _ssoController.clear();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Login SSO Sekolah',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
              const SizedBox(height: 8),
              const Text(
                'Masukkan token SSO simulasi (Format: ssoId:Nama:Email).',
                style: TextStyle(fontSize: 13, color: _grey),
              ),
              const SizedBox(height: 16),
              DamosTextField(
                controller: _ssoController,
                labelText: 'Token SSO Sekolah',
                hintText: 'Contoh: sso-123:Nama:email@smktelkom-jkt.sch.id',
                prefixIcon: Icons.vpn_key_outlined,
                validator: (val) => Validators.required(val, fieldName: 'Token SSO'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: DamosButton(
                      text: 'Batal',
                      variant: DamosButtonVariant.outline,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DamosButton(
                      text: 'Masuk',
                      onPressed: () {
                        if (_ssoController.text.trim().isNotEmpty) {
                          Navigator.pop(ctx);
                          context.read<AuthBloc>().add(
                                SsoLoginSubmitted(ssoToken: _ssoController.text.trim()),
                              );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            PopUpAlert.show(
              context: context,
              title: 'Login Gagal',
              description: state.error,
              isError: true,
            );
          } else if (state is Authenticated) {
            _showLoginSuccess(context);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),

                    // Logo
                    Center(
                      child: SizedBox(
                        width: 110,
                        height: 82,
                        child: Image.asset(
                          AppConstants.imageLogo,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const _InlineLogo(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Damos Mart',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'SMK Telkom Jakarta',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: _grey),
                    ),

                    const SizedBox(height: 36),

                    // Email
                    _FieldLabel(label: 'Email'),
                    const SizedBox(height: 6),
                    _buildInput(
                      controller: _emailController,
                      hint: 'rakapradana@gmail.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                      textInputAction: TextInputAction.next,
                    ),

                    const SizedBox(height: 16),

                    // Password
                    _FieldLabel(label: 'Password'),
                    const SizedBox(height: 6),
                    _buildInput(
                      controller: _passwordController,
                      hint: '',
                      isPassword: true,
                      validator: Validators.password,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submitLogin(),
                    ),

                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => context.push('/forgot-password'),
                        child: const Text(
                          'Lupa Password?',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _red),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // LOGIN button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submitLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          disabledBackgroundColor: _primary.withOpacity(0.55),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation(Colors.white)),
                              )
                            : const Text(
                                'LOGIN',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // OR divider
                    Row(
                      children: const [
                        Expanded(child: Divider(color: _border, thickness: 1)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR',
                              style: TextStyle(
                                  fontFamily: 'Poppins', fontSize: 12, color: _grey)),
                        ),
                        Expanded(child: Divider(color: _border, thickness: 1)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // SSO button
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : _showSsoDialog,
                        icon: const Icon(Icons.people_alt_outlined, size: 20, color: _dark),
                        label: const Text(
                          'LOGIN DENGAN SSO',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _dark),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: _dark, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Divider(color: _border),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Belum Punya Akun? ',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: _dark)),
                        GestureDetector(
                          onTap: () => context.push('/register'),
                          child: const Text(
                            'Daftar Sekarang',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _primary,
                              decoration: TextDecoration.underline,
                              decorationColor: _primary,
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
          );
        },
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: _dark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _red, width: 1.5),
        ),
        suffixIcon: isPassword
            ? GestureDetector(
                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: _grey,
                ),
              )
            : null,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF111111),
      ),
    );
  }
}

/// Popup "Berhasil Login" — green card with seal-badge checkmark
class _LoginSuccessPopup extends StatelessWidget {
  const _LoginSuccessPopup();

  static const Color _green = Color(0xFF018D1A);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 260,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          color: _green,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Seal badge icon
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, size: 44, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'Berhasil Login',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fallback logo widget jika asset tidak ditemukan
class _InlineLogo extends StatelessWidget {
  const _InlineLogo();

  static const Color _green  = Color(0xFF1B8C2E);
  static const Color _yellow = Color(0xFFF5C518);
  static const Color _red    = Color(0xFFD42427);
  static const Color _blue   = Color(0xFF1A3C8F);

  @override
  Widget build(BuildContext context) {
    const w = 110.0;
    const h = 82.0;
    return SizedBox(
      width: w, height: h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _oval(w, h, _green),
          _oval(w * 0.91, h * 0.89, _yellow),
          _oval(w * 0.82, h * 0.76, _red),
          _oval(w * 0.70, h * 0.60, Colors.white),
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('OMI',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _blue, height: 1.1)),
              Text('DAMOS MART',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _blue, height: 1.1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _oval(double w, double h, Color c) => Container(
        width: w, height: h,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.all(Radius.elliptical(w / 2, h / 2)),
        ),
      );
}
