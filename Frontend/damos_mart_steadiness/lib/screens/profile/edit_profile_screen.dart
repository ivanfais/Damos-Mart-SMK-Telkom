import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../config/api_config.dart';
import '../../data/repositories/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/damos_button.dart';
import '../../widgets/common/damos_text_field.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../widgets/common/damos_page_app_bar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController; // disabled
  
  Uint8List? _localAvatarBytes;
  String? _localAvatarFilename;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    String initialName = '';
    String initialPhone = '';
    String initialEmail = '';

    if (authState is Authenticated) {
      initialName = authState.user.fullName;
      initialPhone = authState.user.phone ?? '';
      initialEmail = authState.user.email;
    }

    _nameController = TextEditingController(text: initialName);
    _phoneController = TextEditingController(text: initialPhone);
    _emailController = TextEditingController(text: initialEmail);
  }

  @override
  void dispose() {
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      PopUpAlert.showIncompleteData(context);
      return;
    }

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
        // Dispatch to AuthBloc to update state globally
        context.read<AuthBloc>().add(UserUpdated(updatedUser));
        
        PopUpAlert.showSuccess(
          context: context,
          title: 'Profil Diperbarui!',
          description: 'Perubahan data profil kamu berhasil disimpan.',
          onConfirm: () {
            context.pop();
          },
        );
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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
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
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Avatar Edit Section
                      Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          // Avatar circle
                          Container(
                            width: AppDimensions.avatarLarge,
                            height: AppDimensions.avatarLarge,
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 2.5),
                            ),
                            child: ClipOval(
                              child: _localAvatarBytes != null
                                  ? Image.memory(
                                      _localAvatarBytes!,
                                      width: AppDimensions.avatarLarge,
                                      height: AppDimensions.avatarLarge,
                                      fit: BoxFit.cover,
                                    )
                                  : currentAvatarUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: ApiConfig.imageUrl(currentAvatarUrl),
                                          width: AppDimensions.avatarLarge,
                                          height: AppDimensions.avatarLarge,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => const Center(
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                          errorWidget: (context, url, error) => const Center(
                                            child: Text('✨🤩', style: TextStyle(fontSize: 36)),
                                          ),
                                        )
                                      : const Center(
                                          child: Text('✨🤩', style: TextStyle(fontSize: 36)),
                                        ),
                            ),
                          ),

                          // Camera overlay notch
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickAvatar,
                              child: const CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primary,
                                child: Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _pickAvatar,
                        child: Text(
                          'Ganti Foto Profil',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Full Name Input
                DamosTextField(
                  controller: _nameController,
                  labelText: 'Nama Lengkap',
                  hintText: 'Masukkan nama lengkap kamu...',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama lengkap tidak boleh kosong.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Phone Input
                DamosTextField(
                  controller: _phoneController,
                  labelText: 'Nomor WhatsApp / HP',
                  hintText: 'Masukkan nomor WhatsApp aktif...',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),

                // Email (Read-only)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email Sekolah / Akun (Tidak Bisa Diubah)',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      enabled: false,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                      decoration: const InputDecoration(
                        fillColor: AppColors.surface,
                        filled: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Save button
                DamosButton(
                  text: 'Simpan Perubahan',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _saveProfile,
                ),
                const SizedBox(height: 10),
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
