import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/password_rules.dart';
import '../../data/repositories/auth_repository.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/auth/damos_auth_text_field.dart';
import '../../widgets/auth/password_requirements.dart';
import '../../widgets/common/damos_page_app_bar.dart';
import '../../widgets/common/damos_success_banner.dart';
import '../../widgets/common/pop_up_alert.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  static const Duration _errorDismissDelay = Duration(seconds: 3);

  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _repository = AuthRepository();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  String? _currentPasswordError;
  String? _newPasswordRulesError;
  String? _confirmMismatchError;
  Timer? _errorDismissTimer;

  bool get _canSubmit {
    final current = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    return current.isNotEmpty && newPassword.isNotEmpty && confirm.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(_onFieldsChanged);
    _newPasswordController.addListener(_onFieldsChanged);
    _confirmPasswordController.addListener(_onFieldsChanged);
  }

  void _onFieldsChanged() {
    if (mounted) setState(() {});
  }

  void _clearInlineErrors() {
    _currentPasswordError = null;
    _newPasswordRulesError = null;
    _confirmMismatchError = null;
  }

  void _showInlineErrors({
    String? currentPasswordError,
    String? newPasswordRulesError,
    String? confirmMismatchError,
  }) {
    _errorDismissTimer?.cancel();
    setState(() {
      _clearInlineErrors();
      _currentPasswordError = currentPasswordError;
      _newPasswordRulesError = newPasswordRulesError;
      _confirmMismatchError = confirmMismatchError;
    });
    _errorDismissTimer = Timer(_errorDismissDelay, () {
      if (!mounted) return;
      setState(_clearInlineErrors);
    });
  }

  bool _isIncorrectPasswordError(ApiException error) {
    if (error.code == 'INCORRECT_PASSWORD') return true;
    if (error.statusCode == 400) {
      final message = error.message.toLowerCase();
      return message.contains('incorrect') ||
          message.contains('current password') ||
          message.contains('password lama');
    }
    return false;
  }

  @override
  void dispose() {
    _errorDismissTimer?.cancel();
    _currentPasswordController.removeListener(_onFieldsChanged);
    _newPasswordController.removeListener(_onFieldsChanged);
    _confirmPasswordController.removeListener(_onFieldsChanged);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearPasswordFields() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  Future<void> _submit() async {
    _errorDismissTimer?.cancel();
    setState(_clearInlineErrors);

    if (!_formKey.currentState!.validate()) return;

    if (!PasswordRules.isValid(_newPasswordController.text)) {
      _showInlineErrors(
        newPasswordRulesError: 'Password belum memenuhi persyaratan',
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showInlineErrors(
        confirmMismatchError: 'Password baru yang anda masukkan tidak sesuai',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _repository.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;

      _errorDismissTimer?.cancel();
      setState(_clearInlineErrors);
      _clearPasswordFields();

      context.go('/profile');
      DamosSuccessBanner.show(
        title: 'Notifikasi Berhasil',
        message: 'Password berhasil diperbarui!',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_isIncorrectPasswordError(e)) {
        _showInlineErrors(
          currentPasswordError: 'Password lama yang anda masukkan salah',
        );
        return;
      }
      PopUpAlert.show(
        context: context,
        title: 'Gagal Mengubah Password',
        description: e.message,
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;
      PopUpAlert.show(
        context: context,
        title: 'Gagal Mengubah Password',
        description: e.toString(),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _inlineError(String? message) {
    if (message == null || message.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 12,
          color: DamosDominanceColors.error,
          height: 1.35,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DamosDominanceColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DamosPageHeader(
              title: 'Ubah Password',
              showBackButton: true,
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DamosAuthTextField(
                        controller: _currentPasswordController,
                        hintText: 'Password Lama',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscureCurrent,
                        showErrorState: _currentPasswordError != null,
                        onChanged: (_) => _onFieldsChanged(),
                        onToggleVisibility: () {
                          setState(() => _obscureCurrent = !_obscureCurrent);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password lama wajib diisi';
                          }
                          return null;
                        },
                      ),
                      _inlineError(_currentPasswordError),
                      const SizedBox(height: 16),
                      DamosAuthTextField(
                        controller: _newPasswordController,
                        hintText: 'Password Baru',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscureNew,
                        showErrorState: _newPasswordRulesError != null,
                        onChanged: (_) => _onFieldsChanged(),
                        onToggleVisibility: () {
                          setState(() => _obscureNew = !_obscureNew);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password baru wajib diisi';
                          }
                          return null;
                        },
                      ),
                      _inlineError(_newPasswordRulesError),
                      const SizedBox(height: 12),
                      PasswordRequirements(password: _newPasswordController.text),
                      _inlineError(_confirmMismatchError),
                      const SizedBox(height: 16),
                      DamosAuthTextField(
                        controller: _confirmPasswordController,
                        hintText: 'Konfirmasi Password Baru',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscureConfirm,
                        showErrorState: _confirmMismatchError != null,
                        onChanged: (_) => _onFieldsChanged(),
                        onToggleVisibility: () {
                          setState(() => _obscureConfirm = !_obscureConfirm);
                        },
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Konfirmasi password wajib diisi';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) {
                          if (_canSubmit && !_isSubmitting) _submit();
                        },
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _canSubmit && !_isSubmitting ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DamosDominanceColors.primary,
                            foregroundColor: DamosDominanceColors.textOnPrimary,
                            disabledBackgroundColor: DamosDominanceColors.buttonDisabledFill,
                            disabledForegroundColor: DamosDominanceColors.buttonDisabledText,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: _canSubmit && !_isSubmitting
                                    ? DamosDominanceColors.primary
                                    : DamosDominanceColors.buttonDisabledBorder,
                              ),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                )
                              : const Text(
                                  'Simpan Perubahan',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
