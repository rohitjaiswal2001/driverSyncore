import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/validators.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/top_snack_bar.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../domain/entities/user.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _companyNameController;
  String? _localImagePath;
  User? _cachedUser;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    String initialFirstName = '';
    String initialLastName = '';
    String initialPhone = '';
    String initialCompanyName = '';

    if (authState is AuthSuccess) {
      _cachedUser = authState.user;
      initialFirstName = authState.user.firstName;
      initialLastName = authState.user.lastName ?? '';
      initialPhone = authState.user.phone;
      initialCompanyName = authState.user.companyName;
    }

    _firstNameController = TextEditingController(text: initialFirstName);
    _lastNameController = TextEditingController(text: initialLastName);
    _phoneController = TextEditingController(text: initialPhone);
    _companyNameController = TextEditingController(text: initialCompanyName);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _localImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourcePicker(bool hasExistingImage) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (pickerCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(pickerCtx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primary,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(pickerCtx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_localImagePath != null || hasExistingImage)
                ListTile(
                  leading: const Icon(Icons.delete, color: Color(0xFFDC2626)),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: Color(0xFFDC2626)),
                  ),
                  onTap: () {
                    Navigator.pop(pickerCtx);
                    if (_localImagePath != null) {
                      setState(() {
                        _localImagePath = null;
                      });
                    } else {
                      // Trigger direct remove API
                      context.read<AuthBloc>().add(
                        const RemoveProfileImageSubmitted(),
                      );
                    }
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          TopSnackBar.show(
            context,
            message: 'Profile updated successfully!',
            backgroundColor: AppColors.accentGreen,
            icon: Icons.check_circle_outline,
          );
          Navigator.pop(context);
        } else if (state is AuthFailure) {
          TopSnackBar.show(
            context,
            message: state.errorMessage,
            backgroundColor: Colors.redAccent,
            icon: Icons.error_outline,
          );
        }
      },
      builder: (context, state) {
        if (state is AuthSuccess) {
          _cachedUser = state.user;
        }
        final isLoading = state is AuthLoading;
        final user = _cachedUser;
        final hasImage =
            user != null &&
            user.profileImage != null &&
            user.profileImage!.isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Edit Profile',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          body: LoadingOverlay(
            isLoading: isLoading,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Image picker avatar
                    GestureDetector(
                      onTap: () => _showImageSourcePicker(hasImage),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 56,
                            backgroundColor: AppColors.primary.withAlpha(26),
                            backgroundImage: _localImagePath != null
                                ? FileImage(File(_localImagePath!))
                                      as ImageProvider
                                : (hasImage
                                      ? NetworkImage(user.profileImage!)
                                      : null),
                            child: _localImagePath == null && !hasImage
                                ? const Icon(
                                    Icons.person,
                                    size: 56,
                                    color: AppColors.primary,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
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
                    const SizedBox(height: 32),

                    // First name field
                    TextFormField(
                      controller: _firstNameController,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        hintText: 'First Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: Validators.validateFirstName,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z\s]'),
                        ),
                        LengthLimitingTextInputFormatter(50),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Last name field
                    TextFormField(
                      controller: _lastNameController,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        hintText: 'Last Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: Validators.validateLastName,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z\s]'),
                        ),
                        LengthLimitingTextInputFormatter(50),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Phone field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        if (val.trim().length < 8) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Company Name field
                    TextFormField(
                      controller: _companyNameController,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Company Name',
                        hintText: 'Company Name',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Save Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          context.read<AuthBloc>().add(
                            UpdateProfileSubmitted(
                              firstName: _firstNameController.text.trim(),
                              lastName: _lastNameController.text.trim(),
                              phone: _phoneController.text.trim(),
                              companyName: _companyNameController.text.trim(),
                              profileImagePath: _localImagePath,
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
