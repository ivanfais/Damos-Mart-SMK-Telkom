import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../config/api_config.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../widgets/common/steadiness_app_header.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color hint = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE0E0E0);
  static const Color fieldBg = Color(0xFFF3F4F6);
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _nicknameController;
  late TextEditingController _phoneController;

  Uint8List? _localAvatarBytes;
  String? _localAvatarFilename;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initFromAuth(context.read<AuthBloc>().state);
  }

  void _initFromAuth(AuthState authState) {
    var fullName = '';
    var phoneLocal = '';

    if (authState is Authenticated) {
      final user = authState.user;
      fullName = user.fullName;
      phoneLocal = _localPhoneNumber(user.phone);
    }

    _fullNameController = TextEditingController(text: fullName);
    _nicknameController = TextEditingController(text: _nicknameFromFullName(fullName));
    _phoneController = TextEditingController(text: phoneLocal);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _nicknameFromFullName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : fullName;
  }

  String _mergeFullName(String fullName, String nickname) {
    final trimmedNickname = nickname.trim();
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return trimmedNickname;
    return '$trimmedNickname ${parts.sublist(1).join(' ')}';
  }

  String _resolvedFullName() {
    final fullName = _fullNameController.text.trim();
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return fullName;
    if (nickname == _nicknameFromFullName(fullName)) return fullName;
    return _mergeFullName(fullName, nickname);
  }

  String _localPhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) return '';
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('62')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits;
  }

  String? _phoneForApi(String localDigits) {
    final digits = localDigits.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return '0$digits';
  }

  Future<void> _pickAvatar() async {
    try {
      final image = await _picker.pickImage(
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      PopUpAlert.showIncompleteData(context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fullName = _resolvedFullName();

      final repository = AuthRepository();
      final updatedUser = await repository.updateMe(
        fullName: fullName,
        phone: _phoneForApi(_phoneController.text.trim()),
        localAvatarBytes: _localAvatarBytes,
        localAvatarFilename: _localAvatarFilename,
      );

      if (!mounted) return;
      context.read<AuthBloc>().add(UserUpdated(updatedUser));

      await PopUpAlert.showSuccess(
        context: context,
        title: 'Profil Diperbarui!',
        description: 'Perubahan data profil kamu berhasil disimpan.',
        onConfirm: () {
          if (context.canPop()) context.pop();
        },
      );
    } catch (e) {
      if (!mounted) return;
      PopUpAlert.show(
        context: context,
        title: 'Gagal Menyimpan',
        description: 'Penyimpanan gagal: ${e.toString()}. Coba sesaat lagi!',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SteadinessAppHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAvatarSection(currentAvatarUrl),
                    const SizedBox(height: 28),
                    _buildTextField(
                      label: 'Nama Lengkap',
                      controller: _fullNameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama lengkap tidak boleh kosong.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    _buildTextField(
                      label: 'Nama Panggilan',
                      controller: _nicknameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama panggilan tidak boleh kosong.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    _buildPhoneField(),
                    const SizedBox(height: 32),
                    _buildPrimaryButton(
                      label: 'Simpan Perubahan',
                      onPressed: _isLoading ? null : _saveProfile,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 12),
                    _buildSecondaryButton(
                      label: 'Batal',
                      onPressed: _isLoading ? null : () => context.pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(String? currentAvatarUrl) {
    const size = 108.0;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _Ds.border, width: 2),
              ),
              child: ClipOval(
                child: _localAvatarBytes != null
                    ? Image.memory(
                        _localAvatarBytes!,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                      )
                    : currentAvatarUrl != null && currentAvatarUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: ApiConfig.imageUrl(currentAvatarUrl),
                            width: size,
                            height: size,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const ColoredBox(
                              color: _Ds.fieldBg,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _Ds.primary,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => const ColoredBox(
                              color: _Ds.fieldBg,
                              child: Icon(Icons.person, size: 48, color: _Ds.hint),
                            ),
                          )
                        : const ColoredBox(
                            color: _Ds.fieldBg,
                            child: Icon(Icons.person, size: 48, color: _Ds.hint),
                          ),
              ),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: _Ds.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_outlined, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickAvatar,
          child: const Text(
            'Ubah Foto',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _Ds.primary,
              decoration: TextDecoration.underline,
              decorationColor: _Ds.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _Ds.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _Ds.textPrimary,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _Ds.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _Ds.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _Ds.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nomor Telepon',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _Ds.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _Ds.fieldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _Ds.border),
              ),
              child: const Text(
                '+62',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _Ds.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _Ds.textPrimary,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _Ds.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _Ds.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _Ds.primary, width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _Ds.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _Ds.primary.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            : Text(
                label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _Ds.fieldBg,
          foregroundColor: _Ds.textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
