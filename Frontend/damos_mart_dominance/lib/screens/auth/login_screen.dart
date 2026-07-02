import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../core/utils/validators.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/auth/damos_auth_text_field.dart';
import '../../widgets/auth/damos_brand_header.dart';
import '../../widgets/auth/damos_powered_by_footer.dart';
import '../../widgets/common/pop_up_alert.dart';

class LoginScreen extends StatefulWidget {
  final String? prefillEmail;
  final bool registered;

  const LoginScreen({
    super.key,
    this.prefillEmail,
    this.registered = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

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
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
          LoginSubmitted(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  Widget _labeledField({
    required String label,
    required Widget field,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: DamosDominanceColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DamosDominanceColors.background,
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
            context.go('/home');
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Column(
            children: [
              Container(
                width: double.infinity,
                color: DamosDominanceColors.primary,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 24,
                  bottom: 28,
                  left: 24,
                  right: 24,
                ),
                child: const DamosBrandHeader(
                  subtitle: 'Koperasi Siswa SMK Telkom Jakarta',
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Selamat Datang Kembali',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: DamosDominanceColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (widget.registered)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: DamosDominanceColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Akun berhasil dibuat. Silakan login untuk melanjutkan.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: DamosDominanceColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        const Text(
                          'Masuk ke akun anda untuk melanjutkan',
                          style: TextStyle(
                            fontSize: 14,
                            color: DamosDominanceColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _labeledField(
                          label: 'Email',
                          field: DamosAuthTextField(
                            controller: _emailController,
                            hintText: 'Masukkan Email SSO',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: Validators.authEmail,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _labeledField(
                          label: 'Password',
                          field: DamosAuthTextField(
                            controller: _passwordController,
                            hintText: 'Masukkan password',
                            obscureText: _obscurePassword,
                            onToggleVisibility: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                            textInputAction: TextInputAction.done,
                            validator: Validators.authPassword,
                            onFieldSubmitted: (_) => _submitLogin(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Material(
                              color: Colors.transparent,
                              clipBehavior: Clip.none,
                              child: InkWell(
                                onTap: () => context.push('/forgot-password'),
                                borderRadius: BorderRadius.circular(4),
                                splashColor: DamosDominanceColors.primary.withValues(alpha: 0.15),
                                highlightColor: DamosDominanceColors.primary.withValues(alpha: 0.08),
                                child: const Padding(
                                  padding: EdgeInsets.fromLTRB(4, 4, 4, 6),
                                  child: Text(
                                    'Lupa Password?',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                      color: DamosDominanceColors.primary,
                                      decoration: TextDecoration.underline,
                                      decorationColor: DamosDominanceColors.primary,
                                      decorationThickness: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _submitLogin,
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
                            child: isLoading
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
                                    'Masuk',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Belum punya akun? ',
                              style: TextStyle(
                                fontSize: 14,
                                color: DamosDominanceColors.textSecondary,
                              ),
                            ),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => context.push('/register'),
                                child: const Text(
                                  'Daftar sekarang',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: DamosDominanceColors.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: DamosPoweredByFooter(),
              ),
            ],
          );
        },
      ),
    );
  }
}
