import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../config/api_config.dart';
import '../../data/repositories/auth_repository.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/damos_text_field.dart';
import '../../widgets/common/damos_success_banner.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../widgets/common/damos_page_app_bar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const double _avatarSize = 100;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String _initialName = '';
  String _initialPhone = '';

  Uint8List? _localAvatarBytes;
  String? _localAvatarFilename;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _showSuccessBanner = false;

  bool get _hasChanges {
    return _nameController.text.trim() != _initialName ||
        _phoneController.text.trim() != _initialPhone ||
        _localAvatarBytes != null;
  }

  @override
  void initState() {
    super.initState();
    _syncFromAuth(context.read<AuthBloc>().state);
    _nameController.addListener(_onFormChanged);
    _phoneController.addListener(_onFormChanged);
  }

  void _syncFromAuth(AuthState authState) {
    if (authState is! Authenticated) return;

    _initialName = authState.user.fullName;
    _initialPhone = authState.user.phone ?? '';
    _nameController.text = _initialName;
    _phoneController.text = _initialPhone;
    _emailController.text = authState.user.email;
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFormChanged);
    _phoneController.removeListener(_onFormChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
        maxWidth: 400,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _localAvatarBytes = bytes;
          _localAvatarFilename = image.name;
        });
      }
    } catch (_) {
      if (!mounted) return;
      PopUpAlert.show(
        context: context,
        title: 'Gagal Mengambil Foto',
        description: 'Tidak dapat membuka galeri foto. Berikan izin akses ya!',
        isError: true,
      );
    }
  }

  Future<bool> _showSaveConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 6,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Apakah kamu yakin untuk Menyimpan Perubahan?',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: DamosDominanceColors.textPrimary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      _ConfirmDialogButton(
                        label: 'Batalkan',
                        backgroundColor: DamosDominanceColors.error,
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                      ),
                      _ConfirmDialogButton(
                        label: 'Ya, Simpan Perubahan',
                        backgroundColor: DamosDominanceColors.primary,
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return confirmed ?? false;
  }

  void _showProfileUpdatedBanner() {
    setState(() => _showSuccessBanner = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSuccessBanner = false);
    });
  }

  Future<void> _onSavePressed() async {
    if (!_formKey.currentState!.validate()) {
      PopUpAlert.showIncompleteData(context);
      return;
    }

    final confirmed = await _showSaveConfirmation();
    if (!confirmed || !mounted) return;

    await _saveProfile();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repository = AuthRepository();
      final updatedUser = await repository.updateMe(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        localAvatarBytes: _localAvatarBytes,
        localAvatarFilename: _localAvatarFilename,
      );

      if (mounted) {
        context.read<AuthBloc>().add(UserUpdated(updatedUser));

        setState(() {
          _initialName = _nameController.text.trim();
          _initialPhone = _phoneController.text.trim();
          _localAvatarBytes = null;
          _localAvatarFilename = null;
        });
        _showProfileUpdatedBanner();
      }
    } catch (e) {
      if (mounted) {
        PopUpAlert.show(
          context: context,
          title: 'Gagal Menyimpan',
          description: 'Penyimpanan gagal: ${e.toString()}. Coba sesaat lagi!',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String? currentAvatarUrl;
    if (authState is Authenticated) {
      currentAvatarUrl = authState.user.avatarUrl;
    }

    return Scaffold(
      backgroundColor: DamosDominanceColors.screenBackground,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DamosPageHeader(
                  title: 'Edit Profil',
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
                          _buildAvatarSection(currentAvatarUrl),
                          const SizedBox(height: 28),
                          DamosTextField(
                            controller: _nameController,
                            labelText: 'Nama Lengkap',
                            hintText: 'Masukkan nama lengkap',
                            fillColor: Colors.white,
                            borderColor: DamosDominanceColors.fieldBorder,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama lengkap tidak boleh kosong.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildReadOnlyEmailField(),
                          const SizedBox(height: 20),
                          DamosTextField(
                            controller: _phoneController,
                            labelText: 'Nomor Telepon',
                            hintText: 'Masukkan nomor telepon',
                            keyboardType: TextInputType.phone,
                            fillColor: Colors.white,
                            borderColor: DamosDominanceColors.fieldBorder,
                          ),
                          if (_hasChanges) ...[
                            const SizedBox(height: 32),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _onSavePressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DamosDominanceColors.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      DamosDominanceColors.primary.withValues(alpha: 0.6),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Simpan Perubahan',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showSuccessBanner)
            const DamosSuccessBanner(
              title: 'Notifikasi Berhasil',
              message: 'Profil berhasil diperbaharui!',
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(String? currentAvatarUrl) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: _avatarSize,
                  height: _avatarSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: DamosDominanceColors.primary, width: 2),
                  ),
                  child: ClipOval(
                    child: _localAvatarBytes != null
                        ? Image.memory(
                            _localAvatarBytes!,
                            width: _avatarSize,
                            height: _avatarSize,
                            fit: BoxFit.cover,
                          )
                        : currentAvatarUrl != null && currentAvatarUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: ApiConfig.imageUrl(currentAvatarUrl),
                                width: _avatarSize,
                                height: _avatarSize,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                errorWidget: (_, __, ___) => _buildAvatarPlaceholder(),
                              )
                            : _buildAvatarPlaceholder(),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9CA3AF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickAvatar,
            child: const Text(
              'Ganti Foto Profil',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DamosDominanceColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: const Color(0xFFFFF8E1),
      alignment: Alignment.center,
      child: const Text('✨', style: TextStyle(fontSize: 36)),
    );
  }

  Widget _buildReadOnlyEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: AppTextStyles.labelMedium.copyWith(
            color: DamosDominanceColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          enabled: false,
          style: AppTextStyles.bodyMedium.copyWith(color: DamosDominanceColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: DamosDominanceColors.fieldBorder),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfirmDialogButton extends StatelessWidget {
  const _ConfirmDialogButton({
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
