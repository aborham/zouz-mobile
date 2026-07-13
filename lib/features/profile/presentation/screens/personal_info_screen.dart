import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:zouz_mobile/core/utils/image_utils.dart';
import 'package:zouz_mobile/features/auth/providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _isSaving = false;

  Future<void> _handleSave() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      String? uploadedUrl;
      if (_imageFile != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading image...'), duration: Duration(seconds: 1)),
        );
        uploadedUrl = await ref.read(authNotifierProvider.notifier).uploadAvatar(_imageFile!);
      }

      final repository = ref.read(profileRepositoryProvider);
      final updates = <String, dynamic>{
        'name': _nameController.text,
        'email': _emailController.text,
      };
      if (uploadedUrl != null) {
        updates['avatarUrl'] = uploadedUrl;
      }

      await repository.updateProfile(updates);

      ref.invalidate(profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('common.success'.tr())),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _checkAndPickImage() async {
    final status = await Permission.camera.status;
    final galleryStatus = await Permission.photos.status;

    if (!status.isGranted || !galleryStatus.isGranted) {
      final bool? proceed = await _showPermissionDialog();
      if (proceed != true) return;
    }

    _showPickerOptions();
  }

  Future<bool?> _showPermissionDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('auth.permission_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text('auth.permission_camera_msg'.tr(), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('auth.permission_gallery_msg'.tr(), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('auth.permission_cancel'.tr(), style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('auth.permission_enable'.tr()),
          ),
        ],
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'profile.personal_info'.tr(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (_nameController.text.isEmpty) {
            _nameController.text = profile.name ?? '';
            _emailController.text = profile.email ?? '';
            _phoneController.text = profile.phoneNumber ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.1),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 3),
                        ),
                        child: ClipOval(
                          child: _imageFile != null
                              ? Image.file(_imageFile!, fit: BoxFit.cover)
                              : profile.avatarUrl != null
                                  ? Image.network(ImageUtils.getFullUrl(profile.avatarUrl)!, fit: BoxFit.cover)
                                  : const Icon(Icons.person, size: 50, color: AppColors.primary),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _checkAndPickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                _buildFieldLabel('profile.customer_name'.tr()),
                const SizedBox(height: 8),
                _buildTextField(_nameController, 'profile.customer_name_placeholder'.tr()),
                const SizedBox(height: 24),
                _buildFieldLabel('profile.email'.tr()),
                const SizedBox(height: 8),
                _buildTextField(_emailController, "john@example.com", keyboardType: TextInputType.emailAddress, enabled: false),
                const SizedBox(height: 24),
                _buildFieldLabel('profile.phone_number'.tr()),
                _buildTextField(_phoneController, "+966 50 000 0000", keyboardType: TextInputType.phone),
                const SizedBox(height: 40),
                const Text(
                  "Note: Changing your email or phone number will require verification.",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('common.save'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 48),
                
                // Delete Account
                ListTile(
                  onTap: () => _showDeleteAccountDialog(context),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  tileColor: AppColors.error.withValues(alpha: 0.05),
                  leading: const Icon(Icons.delete_forever, color: AppColors.error),
                  title: Text(
                    "profile.delete_account".tr(),
                    style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "profile.delete_account_desc".tr(),
                    style: const TextStyle(fontSize: 12, color: AppColors.error),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('common.error'.tr())),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4FB)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        style: TextStyle(
          fontWeight: FontWeight.w600, 
          color: enabled ? AppColors.textPrimary : Colors.grey,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    int secondsRemaining = 10;
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (secondsRemaining > 0) {
                setState(() {
                  secondsRemaining--;
                });
              } else {
                t.cancel();
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("profile.delete_confirm".tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("profile.delete_confirm_desc".tr()),
                  const SizedBox(height: 16),
                  if (secondsRemaining > 0)
                    Text(
                      "profile.wait_seconds".tr().replaceFirst('{}', secondsRemaining.toString()),
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.pop(context);
                  },
                  child: Text("common.cancel".tr()),
                ),
                TextButton(
                  onPressed: secondsRemaining > 0
                      ? null
                      : () {
                          timer?.cancel();
                          Navigator.pop(context);
                          // Implement delete logic
                        },
                  child: Text(
                    "profile.delete_btn".tr(),
                    style: TextStyle(
                      color: secondsRemaining > 0 ? Colors.grey : AppColors.error,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => timer?.cancel());
  }
}
