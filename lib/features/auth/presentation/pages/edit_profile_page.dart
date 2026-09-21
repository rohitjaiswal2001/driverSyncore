import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/validators.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/top_snack_bar.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../domain/entities/user.dart';
import '../../../../core/widgets/tinted_page_header.dart';
import '../../../../core/widgets/app_button.dart';

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

  static const String _defaultCountryIso = 'IN';

  /// ISO code the picker opens on, resolved once from the saved profile.
  late final String _initialCountryIso;

  /// Country currently picked in the phone field; drives the dial code,
  /// the hint and the length error message.
  late Country _phoneCountry;

  /// Dial code sent as `phone_country_code`, e.g. '+91'.
  String get _phoneCountryCode => '+${_phoneCountry.fullCountryCode}';

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    String initialFirstName = '';
    String initialLastName = '';
    String initialPhone = '';
    String initialCompanyName = '';
    String initialCountryCode = '';

    if (authState is AuthSuccess) {
      _cachedUser = authState.user;
      initialFirstName = authState.user.firstName;
      initialLastName = authState.user.lastName ?? '';
      initialPhone = authState.user.phone;
      initialCountryCode = authState.user.phoneCountryCode;
      initialCompanyName = authState.user.companyName;
    }

    _firstNameController = TextEditingController(text: initialFirstName);
    _lastNameController = TextEditingController(text: initialLastName);
    final country = _resolveCountry(initialCountryCode);
    _initialCountryIso = country.code;
    _phoneCountry = country;
    _phoneController = TextEditingController(
      text: _stripDialCode(initialPhone, country),
    );
    _companyNameController = TextEditingController(text: initialCompanyName);
  }

  /// Accepts the stored value as a dial code ('+91', '91') or an ISO code
  /// ('IN'). Falls back to the default country when empty or unknown.
  Country _resolveCountry(String stored) {
    final value = stored.trim();
    Country? match;
    if (value.isNotEmpty) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isNotEmpty) {
        // Several countries share a dial code (e.g. +1); prefer the default
        // country when it matches, otherwise the first exact match.
        final byDial = countries
            .where((c) => c.fullCountryCode == digits)
            .toList();
        if (byDial.isNotEmpty) {
          match = byDial.firstWhere(
            (c) => c.code == _defaultCountryIso,
            orElse: () => byDial.first,
          );
        }
      } else {
        final upper = value.toUpperCase();
        for (final c in countries) {
          if (c.code == upper) {
            match = c;
            break;
          }
        }
      }
    }
    return match ?? countries.firstWhere((c) => c.code == _defaultCountryIso);
  }

  /// Digit count the selected country accepts, e.g. '10' or '8-10'.
  String get _phoneDigitsLabel {
    final min = _phoneCountry.minLength;
    final max = _phoneCountry.maxLength;
    return min == max ? '$max' : '$min-$max';
  }

  /// Older profiles may have the dial code baked into `phone`; the field
  /// shows it in the picker, so only the national number goes in the input.
  String _stripDialCode(String phone, Country country) {
    final value = phone.trim().replaceAll(RegExp(r'[\s-]'), '');
    final withPlus = '+${country.fullCountryCode}';
    if (value.startsWith(withPlus)) {
      return value.substring(withPlus.length);
    }
    return value;
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
          appBar: const TintedPageHeader(
            title: 'Edit Profile',
            subtitle: 'Your name, photo and contact details',
          ),
          body: LoadingOverlay(
            isLoading: isLoading,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: AdaptiveContainer.form(
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
                      IntlPhoneField(
                        controller: _phoneController,
                        initialCountryCode: _initialCountryIso,
                        invalidNumberMessage:
                            'Phone number must be $_phoneDigitsLabel digits for '
                            '${_phoneCountry.name}',
                        dropdownIconPosition: IconPosition.trailing,
                        flagsButtonPadding: const EdgeInsets.only(left: 12),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        dropdownTextStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter $_phoneDigitsLabel digit number',
                          counterText: '',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onCountryChanged: (country) {
                          setState(() {
                            _phoneCountry = country;
                          });
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
                      AppButton(
                        label: 'Save Changes',
                        onPressed: () {
                          final isValid =
                              _formKey.currentState?.validate() ?? false;
                          // IntlPhoneField lets an empty number through its
                          // own validator, so the required check lives here.
                          if (isValid && _phoneController.text.trim().isEmpty) {
                            TopSnackBar.show(
                              context,
                              message: 'Phone number is required',
                              backgroundColor: Colors.redAccent,
                              icon: Icons.error_outline,
                            );
                            return;
                          }
                          if (isValid) {
                            context.read<AuthBloc>().add(
                              UpdateProfileSubmitted(
                                firstName: _firstNameController.text.trim(),
                                lastName: _lastNameController.text.trim(),
                                phone: _phoneController.text.trim(),
                                phoneCountryCode: _phoneCountryCode,
                                companyName: _companyNameController.text.trim(),
                                profileImagePath: _localImagePath,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
