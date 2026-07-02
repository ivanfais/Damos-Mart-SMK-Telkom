import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../core/utils/validators.dart';
import '../../widgets/auth/auth_shell.dart';
import '../../widgets/common/pop_up_alert.dart';

class LoginScreen extends StatefulWidget {
  final String? prefillEmail;
  final bool justRegistered;
  final int initialTab;

  const LoginScreen({
    super.key,
    this.prefillEmail,
    this.justRegistered = false,
    this.initialTab = 0,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _selectedTab = 0;

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;

    if (widget.prefillEmail != null && widget.prefillEmail!.isNotEmpty) {
      _emailController.text = widget.prefillEmail!;
      _registerEmailController.text = widget.prefillEmail!;
    }

    if (widget.justRegistered) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        PopUpAlert.showSuccess(
          context: context,
          title: 'Daftar Berhasil!',
          description: 'Akun kamu sudah dibuat. Silakan login pakai email dan kata sandi kamu.',
        );
      });
    }
  }

  @override
  void didUpdateWidget(LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _selectedTab = widget.initialTab;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _registerEmailController.dispose();
    _phoneController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (!_loginFormKey.currentState!.validate()) {
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

  void _submitRegister() {
    if (!_registerFormKey.currentState!.validate()) {
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
            email: _registerEmailController.text.trim(),
            password: _registerPasswordController.text,
            phone: _phoneController.text.trim(),
          ),
        );
  }

  void _showForgotPassword() {
    PopUpAlert.show(
      context: context,
      title: 'Lupa Kata Sandi?',
      description:
          'Silakan hubungi petugas koperasi atau admin IT sekolah untuk mereset kata sandi kamu.',
    );
  }

  Widget _buildLoginForm(bool isLoading) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthInputField(
            controller: _emailController,
            hintText: 'Masukkan Email',
            prefixIcon: Icons.badge_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AuthInputField(
            controller: _passwordController,
            label: 'Kata Sandi',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            obscureText: _obscureLoginPassword,
            onToggleVisibility: () {
              setState(() => _obscureLoginPassword = !_obscureLoginPassword);
            },
            validator: Validators.password,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitLogin(),
          ),
          const SizedBox(height: 20),
          AuthPrimaryButton(
            label: 'Masuk',
            isLoading: isLoading,
            onPressed: _submitLogin,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showForgotPassword,
            child: const Text(
              'Lupa Kata Sandi?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AuthShell.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(bool isLoading) {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthInputField(
            controller: _nameController,
            hintText: 'Masukkan Nama Lengkap',
            prefixIcon: Icons.person_outline,
            validator: (val) => Validators.required(val, fieldName: 'Nama Lengkap'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AuthInputField(
            controller: _registerEmailController,
            hintText: 'Masukkan Email',
            prefixIcon: Icons.badge_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AuthInputField(
            controller: _phoneController,
            hintText: 'Masukkan Nomor Telepon',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: Validators.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AuthInputField(
            controller: _registerPasswordController,
            label: 'Kata Sandi',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            obscureText: _obscureRegisterPassword,
            onToggleVisibility: () {
              setState(() => _obscureRegisterPassword = !_obscureRegisterPassword);
            },
            validator: Validators.password,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitRegister(),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _agreeToTerms,
                  activeColor: AuthShell.primary,
                  side: const BorderSide(color: AuthShell.border),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Saya menyetujui Ketentuan Layanan dan Kebijakan Privasi dari Koperasi Damos Mart.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AuthShell.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AuthPrimaryButton(
            label: 'Daftar',
            isLoading: isLoading,
            onPressed: (_agreeToTerms && !isLoading) ? _submitRegister : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          PopUpAlert.show(
            context: context,
            title: 'Gagal',
            description: state.error,
            isError: true,
          );
        } else if (state is Authenticated) {
          context.go('/home');
        } else if (state is RegistrationSuccess) {
          setState(() {
            _selectedTab = 0;
            _emailController.text = state.email;
          });
          PopUpAlert.showSuccess(
            context: context,
            title: 'Daftar Berhasil!',
            description: 'Akun kamu sudah dibuat. Silakan login pakai email dan kata sandi kamu.',
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return AuthShell(
          selectedTab: _selectedTab,
          onTabChanged: (index) => setState(() => _selectedTab = index),
          child: _selectedTab == 0 ? _buildLoginForm(isLoading) : _buildRegisterForm(isLoading),
        );
      },
    );
  }
}
