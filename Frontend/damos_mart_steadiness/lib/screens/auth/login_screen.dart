import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
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
  // Design system tokens
  static const Color _primary = Color(0xFF1B8C2E);
  static const Color _fieldBorder = Color(0xFFD1D5DB);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _red = Color(0xFFD42427);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ssoController = TextEditingController();
  bool _obscurePassword = true;

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
          title: 'Daftar Berhasil! 🎉',
          description: 'Akun kamu sudah dibuat. Silakan login pakai email & password kamu ya! 😊',
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
    if (!_formKey.currentState!.validate()) {
      PopUpAlert.showIncompleteData(context);
      return;
    }

    context.read<AuthBloc>().add(
            LoginSubmitted(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
  }

  void _showSsoDialog() {
    _ssoController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Login SSO Sekolah 🏫',
                    style: AppTextStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Masukkan token SSO simulasi kamu (Format: ssoId:Nama:Email, atau ketik nama bebas untuk auto-generate).',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                DamosTextField(
                  controller: _ssoController,
                  labelText: 'Token SSO Sekolah',
                  hintText: 'Contoh: sso-123:Faisal:faisal@smktelkom-jkt.sch.id',
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
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DamosButton(
                        text: 'Masuk 🚀',
                        onPressed: () {
                          if (_ssoController.text.trim().isNotEmpty) {
                            final token = _ssoController.text.trim();
                            Navigator.pop(context);
                            context.read<AuthBloc>().add(
                                  SsoLoginSubmitted(ssoToken: token),
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
        );
      },
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onFieldSubmitted,
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
          obscureText: isPassword && _obscurePassword,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          style: const TextStyle(fontSize: 14, color: _textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: border(_fieldBorder, 1.2),
            focusedBorder: border(_primary, 1.5),
            errorBorder: border(_red, 1.2),
            focusedErrorBorder: border(_red, 1.5),
            suffixIcon: isPassword
                ? GestureDetector(
                    onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: _textSecondary,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            PopUpAlert.show(
              context: context,
              title: 'Oops! 😅',
              description: state.error,
              isError: true,
            );
          } else if (state is Authenticated) {
            context.go('/home');
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // Logo
                    Center(
                      child: SizedBox(
                        width: 120,
                        height: 88,
                        child: Image.asset(
                          AppConstants.imageLogo,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.shopping_bag,
                            size: 56,
                            color: _primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Damos Mart',
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
                      style: TextStyle(
                        fontSize: 15,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 36),
                    _buildField(
                      controller: _emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 20),
                    _buildField(
                      controller: _passwordController,
                      label: 'Password',
                      isPassword: true,
                      validator: Validators.password,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submitLogin(),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          PopUpAlert.show(
                            context: context,
                            title: 'Lupa Password? 🔑',
                            description:
                                'Silakan hubungi petugas koperasi atau admin IT sekolah untuk mereset password kamu ya! 😊',
                          );
                        },
                        child: const Text(
                          'Lupa Password?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _red,
                          ),
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
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _primary.withOpacity(0.6),
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'LOGIN',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // OR divider
                    Row(
                      children: const [
                        Expanded(child: Divider(color: _fieldBorder, thickness: 1)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'OR',
                            style: TextStyle(fontSize: 13, color: _textSecondary),
                          ),
                        ),
                        Expanded(child: Divider(color: _fieldBorder, thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // SSO button (outline)
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : _showSsoDialog,
                        icon: const Icon(Icons.people_outline, size: 20, color: _textPrimary),
                        label: const Text(
                          'LOGIN DENGAN SSO',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: _textPrimary, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(color: _fieldBorder),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Belum Punya Akun? ',
                          style: TextStyle(fontSize: 14, color: _textPrimary),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/register'),
                          child: const Text(
                            'Daftar Sekarang',
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
          );
        },
      ),
    );
  }
}

