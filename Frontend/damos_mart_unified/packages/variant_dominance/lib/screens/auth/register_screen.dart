import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../core/utils/validators.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../config/app_constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Design system tokens
  static const Color _primary = Color(0xFF1B8C2E);
  static const Color _fieldBorder = Color(0xFFD1D5DB);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _red = Color(0xFFD42427);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _agreeToTerms = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitRegister() {
    if (!_formKey.currentState!.validate()) {
      PopUpAlert.showIncompleteData(context);
      return;
    }

    if (!_agreeToTerms) {
      PopUpAlert.show(
        context: context,
        title: 'Ketentuan Layanan',
        description:
            'Anda harus menyetujui Ketentuan Layanan dan Kebijakan Privasi Koperasi Damos Mart untuk melanjutkan pendaftaran.',
        isError: true,
      );
      return;
    }

    context.read<AuthBloc>().add(
          RegisterSubmitted(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            phone: _phoneController.text.trim(),
          ),
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
                      color: const Color(0xFF6B7280),
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
          } else if (state is RegistrationSuccess) {
            // Account created — send the user to login with email pre-filled.
            context.go('/login', extra: {
              'email': state.email,
              'registered': true,
            });
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SafeArea(
                  top: false,
                  child: Container(
                    width: double.infinity,
                    color: _primary,
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 16,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          splashRadius: 24,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 28),
                        const SizedBox(height: 24),
                        Center(
                          child: SizedBox(
                            width: 110,
                            height: 80,
                            child: Image.asset(
                              AppConstants.imageLogoKoperasi,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.shopping_bag,
                                size: 52,
                                color: _primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Buat Akun Baru',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildField(
                          controller: _nameController,
                          label: 'Nama Lengkap',
                          validator: (val) => Validators.required(val, fieldName: 'Nama Lengkap'),
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          controller: _emailController,
                          label: 'Alamat Email',
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          controller: _phoneController,
                          label: 'Nomor Telepon',
                          keyboardType: TextInputType.phone,
                          validator: Validators.phone,
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          controller: _passwordController,
                          label: 'Password',
                          isPassword: true,
                          validator: Validators.password,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submitRegister(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _agreeToTerms,
                                activeColor: _primary,
                                side: const BorderSide(color: _fieldBorder, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _agreeToTerms = val ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text.rich(
                                  TextSpan(
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _textPrimary,
                                      height: 1.4,
                                    ),
                                    children: const [
                                      TextSpan(text: 'Saya menyetujui '),
                                      TextSpan(
                                        text: 'Ketentuan Layanan dan Kebijakan Privasi',
                                        style: TextStyle(color: _red, fontWeight: FontWeight.w600),
                                      ),
                                      TextSpan(text: ' dari Koperasi Damos Mart.'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // DAFTAR button (disabled with 0.4 opacity until terms agreed)
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: (_agreeToTerms && !isLoading) ? _submitRegister : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: _primary.withOpacity(0.4),
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
                                    'DAFTAR',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Sudah punya akun? ',
                              style: TextStyle(fontSize: 14, color: _textPrimary),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/login'),
                              child: const Text(
                                'Login Sekarang',
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
              ],
            ),
          );
        },
      ),
    );
  }
}
