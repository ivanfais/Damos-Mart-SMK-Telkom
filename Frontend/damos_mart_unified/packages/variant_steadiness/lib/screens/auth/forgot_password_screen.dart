import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_constants.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/auth/auth_shell.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../theme/app_text_styles.dart';

enum _ForgotStep { contact, verify, newPassword, success }

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE0E0E0);
  static const Color bg = Color(0xFFF5F5F5);
  static const Color red = Color(0xFFD42427);
  static const Color verifyTeal = Color(0xFF00838F);
  static const String dummyCode = '1234';
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.prefillContact});

  final String? prefillContact;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authRepository = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpControllers = List.generate(4, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(4, (_) => FocusNode());

  _ForgotStep _step = _ForgotStep.contact;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.prefillContact != null && widget.prefillContact!.isNotEmpty) {
      _contactController.text = widget.prefillContact!;
    }
  }

  @override
  void dispose() {
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _contact => _contactController.text.trim();

  bool get _isEmailContact => _contact.contains('@');

  String get _headerTitle {
    switch (_step) {
      case _ForgotStep.contact:
        return 'Lupa Kata Sandi';
      case _ForgotStep.verify:
        return 'Verifikasi Kode';
      case _ForgotStep.newPassword:
        return 'Password Baru';
      case _ForgotStep.success:
        return '';
    }
  }

  void _handleBack() {
    switch (_step) {
      case _ForgotStep.verify:
        setState(() => _step = _ForgotStep.contact);
        return;
      case _ForgotStep.newPassword:
        setState(() => _step = _ForgotStep.verify);
        return;
      case _ForgotStep.contact:
      case _ForgotStep.success:
        context.pop();
    }
  }

  Future<void> _submitContact() async {
    if (!_formKey.currentState!.validate()) {
      PopUpAlert.showIncompleteData(context);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (_isEmailContact) {
        await _authRepository.requestPasswordReset(_contact);
      }
      if (!mounted) return;
      for (final c in _otpControllers) {
        c.clear();
      }
      setState(() {
        _isSubmitting = false;
        _step = _ForgotStep.verify;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _otpFocusNodes.first.requestFocus();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      PopUpAlert.show(context: context, title: 'Gagal', description: e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      PopUpAlert.show(
        context: context,
        title: 'Gagal',
        description: 'Terjadi kesalahan. Coba lagi ya.',
        isError: true,
      );
    }
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  void _submitVerify() {
    if (_otpCode.length != 4) {
      PopUpAlert.show(
        context: context,
        title: 'Kode Belum Lengkap',
        description: 'Masukkan kode verifikasi 4 digit ya.',
        isError: true,
      );
      return;
    }

    if (_otpCode != _Ds.dummyCode) {
      PopUpAlert.show(
        context: context,
        title: 'Kode Salah',
        description: 'Kode verifikasi tidak valid. Coba lagi ya.',
        isError: true,
      );
      return;
    }

    setState(() {
      _step = _ForgotStep.newPassword;
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  Future<void> _submitNewPassword() async {
    if (!_formKey.currentState!.validate()) {
      PopUpAlert.showIncompleteData(context);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (_isEmailContact) {
        await _authRepository.resetPassword(
          email: _contact,
          code: _otpCode,
          newPassword: _passwordController.text,
        );
      }
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _step = _ForgotStep.success;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      PopUpAlert.show(context: context, title: 'Gagal', description: e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      PopUpAlert.show(
        context: context,
        title: 'Gagal',
        description: 'Terjadi kesalahan. Coba lagi ya.',
        isError: true,
      );
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < 4; i++) {
        _otpControllers[i].text = i < digits.length ? digits[i] : '';
      }
      final next = digits.length.clamp(0, 4) - 1;
      if (next < 3) {
        _otpFocusNodes[next + 1].requestFocus();
      } else {
        _otpFocusNodes[3].unfocus();
      }
      setState(() {});
      return;
    }

    if (value.isNotEmpty && index < 3) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  Widget _buildHeader() {
    if (_step == _ForgotStep.success) return const SizedBox.shrink();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
          child: Row(
            children: [
              IconButton(
                onPressed: _handleBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                icon: const Icon(Icons.arrow_back, color: _Ds.primary, size: 26),
              ),
              Expanded(
                child: Text(
                  _headerTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _Ds.textPrimary,
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: _Ds.border),
      ],
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
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _Ds.textPrimary,
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  Widget _buildContactStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Lupa Kata Sandi',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _Ds.textPrimary,
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Masukkan Email atau Nomor Telepon Anda untuk mengatur ulang kata sandi. Kami akan mengirimkan kode verifikasi.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: _Ds.textSecondary,
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
        const SizedBox(height: 24),
        _labeledField(
          label: 'Email atau Nomor Telepon',
          field: AuthInputField(
            controller: _contactController,
            hintText: 'Masukkan Email atau Nomor Telepon',
            prefixIcon: Icons.badge_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.emailOrPhone,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitContact(),
          ),
        ),
        const SizedBox(height: 28),
        _greenActionButton(
          label: 'Kirim Kode Verifikasi',
          icon: Icons.send_outlined,
          onPressed: _isSubmitting ? null : _submitContact,
          isLoading: _isSubmitting,
        ),
        const SizedBox(height: 20),
        _loginFooterLink(),
      ],
    );
  }

  Widget _buildVerifyStep() {
    final contactLabel = _isEmailContact ? 'Email' : 'Nomor Telepon';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _Ds.verifyTeal.withValues(alpha: 0.12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: _Ds.verifyTeal.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.smartphone_outlined, color: _Ds.verifyTeal, size: 42),
                ),
                Positioned(
                  top: 28,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.verified_user_outlined, color: _Ds.primary, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isEmailContact ? 'Cek Email Anda' : 'Cek Nomor Telepon Anda',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _Ds.textPrimary,
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Masukkan kode verifikasi yang telah dikirimkan ke $contactLabel Anda\n$_contact',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: _Ds.textSecondary,
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return Padding(
              padding: EdgeInsets.only(right: index < 3 ? 12 : 0),
              child: SizedBox(
                width: 56,
                height: 56,
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _Ds.textPrimary,
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) => _onOtpChanged(index, value),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '-',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 22),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _Ds.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _Ds.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        const Text(
          'Demo: gunakan kode 1234',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: _Ds.textSecondary, fontFamily: AppTextStyles.fontFamily),
        ),
        const SizedBox(height: 28),
        _greenActionButton(
          label: 'Verifikasi',
          icon: Icons.verified_user_outlined,
          onPressed: _submitVerify,
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Buat Password Baru',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _Ds.textPrimary,
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Buat password baru untuk akun $_contact.',
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: _Ds.textSecondary,
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
        const SizedBox(height: 24),
        _labeledField(
          label: 'Password Baru',
          field: AuthInputField(
            controller: _passwordController,
            hintText: 'Masukkan Kata Sandi',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            obscureText: _obscurePassword,
            onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
            validator: Validators.password,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 16),
        _labeledField(
          label: 'Konfirmasi Password Baru',
          field: AuthInputField(
            controller: _confirmPasswordController,
            hintText: 'Masukkan Kata Sandi',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            obscureText: _obscureConfirmPassword,
            onToggleVisibility: () =>
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            validator: (value) => Validators.confirmPassword(value, _passwordController.text),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitNewPassword(),
          ),
        ),
        const SizedBox(height: 28),
        _greenActionButton(
          label: 'Simpan Password',
          icon: Icons.check_circle_outline,
          onPressed: _isSubmitting ? null : _submitNewPassword,
          isLoading: _isSubmitting,
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const Text(
          AppConstants.appName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _Ds.primary,
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
        const SizedBox(height: 36),
        Center(
          child: SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF5F0E8),
                  ),
                ),
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEDE8DF),
                  ),
                ),
                Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(
                    color: _Ds.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 48),
                ),
                Positioned(
                  top: 24,
                  right: 28,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCC00),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school_outlined, color: _Ds.textPrimary, size: 24),
                  ),
                ),
                Positioned(
                  bottom: 28,
                  left: 24,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF8A80),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_cart_outlined, color: _Ds.red, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Ganti Password Berhasil!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _Ds.textPrimary,
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Selamat, akun Password anda sudah diganti. Silakan masuk untuk mulai belanja di koperasi sekolah.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.55,
            color: _Ds.textSecondary,
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
        const SizedBox(height: 32),
        _greenActionButton(
          label: 'Masuk Sekarang',
          icon: Icons.arrow_forward,
          onPressed: () => context.go('/login', extra: {'email': _isEmailContact ? _contact : null}),
        ),
      ],
    );
  }

  Widget _greenActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _Ds.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _Ds.primary.withValues(alpha: 0.55),
          elevation: 0,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: AppTextStyles.fontFamily,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _loginFooterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Ingat kata sandi? ',
          style: TextStyle(fontSize: 14, color: _Ds.textSecondary, fontFamily: AppTextStyles.fontFamily),
        ),
        GestureDetector(
          onTap: () => context.go('/login'),
          child: const Text(
            'Masuk',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _Ds.primary,
              fontFamily: AppTextStyles.fontFamily,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case _ForgotStep.contact:
        return _buildContactStep();
      case _ForgotStep.verify:
        return _buildVerifyStep();
      case _ForgotStep.newPassword:
        return _buildNewPasswordStep();
      case _ForgotStep.success:
        return _buildSuccessStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Form(
                  key: _formKey,
                  child: _buildStepContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
