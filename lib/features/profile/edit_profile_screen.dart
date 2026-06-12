import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_dialog.dart';
import 'package:provider/provider.dart';
import 'viewmodels/profile_viewmodel.dart';
import '../../services/image_upload_service.dart';
import '../../features/authentication/models/user_model.dart';
import '../authentication/widgets/auth_button.dart';
import '../authentication/widgets/auth_text_field.dart';
import 'package:barter/l10n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  XFile? _imageFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  bool _is2faEnabled = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: UserModel.currentUser?.name);
    _is2faEnabled = UserModel.currentUser?.is2faEnabled ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile != null && mounted) {
        // Add a small delay to prevent Android activity race condition
        await Future.delayed(const Duration(milliseconds: 200));

        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Theme.of(context).primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Crop Image',
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _imageFile = XFile(croppedFile.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    final locale = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(locale.chooseGallery),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(locale.takePhoto),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = UserModel.currentUser!;
      String? profileImageUrl;

      if (_imageFile != null) {
        profileImageUrl = await ImageUploadService.uploadImageToImgBB(
          _imageFile!,
        );
      }

      await context.read<ProfileViewModel>().updateProfile(
        userId: user.id,
        name: _nameController.text.trim(),
        profileImageUrl: profileImageUrl,
        is2faEnabled: _is2faEnabled,
      );

      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Success',
          message: AppLocalizations.of(context)!.profileUpdated,
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        showInfoDialog(
          context: context,
          title: 'Error',
          message: 'Failed to update profile: $e',
          icon: Icons.error_outline,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final user = UserModel.currentUser;

    return Scaffold(
      appBar: CustomAppBar(
        title: locale.editProfile,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Photo
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120.w,
                      height: 120.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).cardColor,
                        border: Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                        image: _imageFile != null
                            ? (kIsWeb
                                ? DecorationImage(
                                    image: NetworkImage(_imageFile!.path),
                                    fit: BoxFit.cover,
                                  )
                                : DecorationImage(
                                    image: FileImage(File(_imageFile!.path)),
                                    fit: BoxFit.cover,
                                  ))
                            : (user?.profileImageUrl != null
                                ? DecorationImage(
                                    image: CachedNetworkImageProvider(
                                      user!.profileImageUrl!,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null),
                      ),
                      child:
                          (_imageFile == null && user?.profileImageUrl == null)
                              ? Icon(
                                  Icons.person,
                                  size: 60.w,
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.5),
                                )
                              : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 20.w,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              TextButton(
                onPressed: _showImagePickerOptions,
                child: Text(locale.changePhoto),
              ),

              SizedBox(height: 32.h),

              // Name Field
              AuthTextFieldWithIcon(
                label: locale.nameLabel,
                hint: locale.nameHint,
                controller: _nameController,
                icon: Icons.person_outline,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return locale.nameRequired;
                  }
                  return null;
                },
              ),

              SizedBox(height: 24.h),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Two-Factor Authentication',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text('Require an email code to log in.'),
                value: _is2faEnabled,
                onChanged: (val) {
                  setState(() {
                    _is2faEnabled = val;
                  });
                },
                activeColor: Theme.of(context).primaryColor,
              ),

              SizedBox(height: 48.h),

              AuthButton(
                text: locale.saveProfile,
                onPressed: _saveProfile,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
