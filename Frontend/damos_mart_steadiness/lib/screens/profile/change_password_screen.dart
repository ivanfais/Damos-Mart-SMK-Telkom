import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_constants.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/auth/auth_shell.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../theme/app_text_styles.dart';

enum _ChangePasswordStep { form, success }

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE0E0E0);
  static const Color bg = Color(0xFFF5F5F5);
  static const Color red = Color(0xFFD42427);
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _authRepository = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _ChangePasswordStep _step = _ChangePasswordStep.form;
  bool _isSubmitting = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (_step == _ChangePasswordStep.success) {
      context.go('/profile');
      return;
    }
    context.pop();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      PopUpAlert.showIncompleteData(context);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _authRepository.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _step = _ChangePasswordStep.success;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final message = e.message.toLowerCase();
      final isWrongPassword = message.contains('incorrect') ||
          message.contains('current password') ||
          message.contains('password lama');
      PopUpAlert.show(
        context: context,
        title: isWrongPassword ? 'Password Lama Salah' : 'Gagal',
        description: isWrongPassword
            ? 'Password lama yang Anda masukkan tidak sesuai. Coba lagi ya.'
            : e.message,
        isError: true,
      );
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

  Widget _buildHeader() {
    if (_step == _ChangePasswordStep.success) return const SizedBox.shrink();

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
              const Expanded(
                child: Text(
                  'Ubah Kata Sandi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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

  Widget _labeledField({required String label, required Widget field}) {
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

  Widget _buildFormStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Ubah Kata Sandi',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _Ds.textPrimary,
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Masukkan password lama Anda, lalu buat password baru untuk keamanan akun.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: _Ds.textSecondary,
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
        const SizedBox(height: 24),
        _labeledField(
          label: 'Password Lama',
          field: AuthInputField(
            controller: _currentPasswordController,
            hintText: 'Masukkan Kata Sandi',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            obscureText: _obscureCurrent,
            onToggleVisibility: () => setState(() => _obscureCurrent = !_obscureCurrent),
            validator: (value) => Validators.required(value, fieldName: 'Password lama'),
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 16),
        _labeledField(
          label: 'Password Baru',
          field: AuthInputField(
            controller: _newPasswordController,
            hintText: 'Masukkan Kata Sandi',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            obscureText: _obscureNew,
            onToggleVisibility: () => setState(() => _obscureNew = !_obscureNew),
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
            obscureText: _obscureConfirm,
            onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
            validator: (value) => Validators.confirmPassword(value, _newPasswordController.text),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: 28),
        _greenActionButton(
          label: 'Simpan Password',
          icon: Icons.check_circle_outline,
          onPressed: _isSubmitting ? null : _submit,
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
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF5F0E8),
                  ),
                ),
                Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEDE8DF),
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
          'Selamat, password Anda sudah diperbarui. Anda dapat melanjutkan menggunakan aplikasi.',
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
          label: 'Kembali ke Profil',
          icon: Icons.arrow_forward,
          onPressed: () => context.go('/profile'),
        ),
      ],
    );
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
                  child: _step == _ChangePasswordStep.form ? _buildFormStep() : _buildSuccessStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
