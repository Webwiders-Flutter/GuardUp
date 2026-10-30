import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/app_types/image_types.dart';
import 'package:guardup/core/constants/app_assets.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/constants/app_constants.dart';
import 'package:guardup/core/services/injection_container.dart';
import 'package:guardup/core/services/media_picker_service.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/utils/image_picker_dialog.dart';
import 'package:guardup/core/utils/ui_feedback.dart';
import 'package:guardup/core/utils/validator/validation_functions.dart';
import 'package:guardup/core/widgets/app_button/app_button.dart';
import 'package:guardup/core/widgets/app_dialog_popup/app_dialog_popup.dart';
import 'package:guardup/core/widgets/app_image/app_image.dart';
import 'package:guardup/core/widgets/app_phone_textfield/app_phone_textfield.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';
import 'package:guardup/core/widgets/app_textfield/app_textfield.dart';
import 'package:guardup/core/widgets/common/app_circle_avatar.dart';
import 'package:guardup/core/widgets/common/custom_loader.dart';
import 'package:guardup/features/auth/domain/entities/user_entity.dart';
import 'package:guardup/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:guardup/features/profile/presentation/bloc/profile_bloc.dart';

import '../../../../core/widgets/common/custom_app_bar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  late final ProfileBloc _profileBloc;
  late final MediaPickerService _mediaPickerService;
  UserEntity? _currentUser;
  File? _selectedImage;

  String _selectedCountryCode = kDebugMode
      ? 'IN'
      : AppConstants.defaultCountryCode;
  String _selectedPhoneCode = kDebugMode ? '91' : AppConstants.defaultPhoneCode;

  final ValueNotifier<bool> isFormValid = ValueNotifier(false);

  void validateForm() {
    isFormValid.value =
        nameController.text.trim().isNotEmpty &&
        phoneController.text.trim().isNotEmpty &&
        emailController.text.trim().isNotEmpty &&
        aboutController.text.trim().isNotEmpty;
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_currentUser != null) {
        final updatedUser = UserEntity(
          id: _currentUser!.id,
          email: _currentUser!.email,
          name: nameController.text,
          phone: phoneController.text,
          phoneCode: _selectedPhoneCode,
          countryCode: _selectedCountryCode,
          bio: aboutController.text,
          profileImage: _currentUser!.profileImage,
          isVerified: _currentUser!.isVerified,
        );
        _profileBloc.add(
          UpdateProfileEvent(user: updatedUser, imageFile: _selectedImage),
        );
      }
    }
  }

  void _showImagePickerOptions(BuildContext context) async {
    final file = await showImagePickerDialog(
      context,
      _mediaPickerService,
      title: context.l10n.profilePhoto,
    );
    if (file != null) {
      setState(() {
        _selectedImage = file;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _profileBloc = sl<ProfileBloc>();
    _mediaPickerService = sl<MediaPickerService>();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      _profileBloc.add(GetProfileEvent(userId: authState.user.id));
    }
    nameController.addListener(validateForm);
    phoneController.addListener(validateForm);
    emailController.addListener(validateForm);
    aboutController.addListener(validateForm);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    aboutController.dispose();
    isFormValid.dispose();
    _profileBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackgroundColor,
      appBar: CustomAppBar(
        backgroundColor: Colors.transparent,
        showBackButton: true,
        titleColor: AppColors.whiteColor,
        title: context.l10n.editProfile,
      ),
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      body: BlocConsumer<ProfileBloc, ProfileState>(
        bloc: _profileBloc,
        listener: (context, state) {
          if (state is ProfileLoaded) {
            _currentUser = state.user;
            nameController.text = state.user.name ?? '';
            phoneController.text = state.user.phone ?? '';
            emailController.text = state.user.email;
            aboutController.text = state.user.bio ?? '';
            setState(() {
              _selectedCountryCode =
                  state.user.countryCode ??
                  (kDebugMode ? 'IN' : AppConstants.defaultCountryCode);
              _selectedPhoneCode =
                  state.user.phoneCode ??
                  (kDebugMode ? '91' : AppConstants.defaultPhoneCode);
            });
            validateForm();
          } else if (state is ProfileUpdateSuccess) {
            context.read<AuthBloc>().add(const AuthRefreshEvent());
            AppConfirmationPopup.showSuccessPopup(
              context: context,
              title: context.l10n.profileUpdated,
              message: context.l10n.profileUpdatedMessage,
              onOk: () {
                context.pop();
              },
            );
          } else if (state is ProfileError) {
            UIFeedback.showSnackbar(
              context,
              context.translateFailure(state.message),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading && _currentUser == null) {
            return const CustomLoader();
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 100),
                  GestureDetector(
                    onTap: () => _showImagePickerOptions(context),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 110,
                          width: 110,
                          child: AppCircleAvatar(
                            radius: 50, // width 100 / 2
                            showBorder: false,
                            imageFile: _selectedImage,
                            imageUrl: _currentUser?.profileImage,
                          ),
                        ),

                        Positioned(
                          right: -60,
                          bottom: 4,
                          left: 0,
                          child: Container(
                            height: 28,
                            width: 28,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.whiteColor,
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Name Field
                  AppTextField(
                    controller: nameController,
                    hintText: context.l10n.enterYourName,
                    headingText: context.l10n.nameLabel,
                    keyboardType: TextInputType.text,
                    subHeadingText: const AppText(' *', color: Colors.red),
                    borderType: AppTextFieldBorderType.outline,
                    validator: (name) =>
                        AppValidators.name(name, context: context),
                    prefix: const Padding(
                      padding: EdgeInsets.all(14.0),
                      child: AppImage(
                        imageUrl: AppAssets.userIcon,
                        appFileType: AppImageTypes.asset,
                        height: 20,
                        width: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Phone Field
                  AppPhoneField(
                    controller: phoneController,
                    initialCountryCode: _selectedCountryCode,
                    onCountryChanged: (country) {
                      _selectedCountryCode = country.countryCode;
                      _selectedPhoneCode = country.phoneCode;
                    },
                    hintText: context.l10n.enterPhoneNumber,
                    headingText: context.l10n.phoneNumber,
                    keyboardType: TextInputType.phone,
                    readOnly: true,
                    showDialog: false,
                    enableInteractiveSelection: false,
                    subHeadWidget: const AppText(' *', color: Colors.red),
                  ),
                  const SizedBox(height: 20),

                  // Email Field
                  AppTextField(
                    controller: emailController,
                    hintText: context.l10n.emailHint,
                    headingText: context.l10n.emailLabel,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: true,
                    showCursor: false,
                    enableInteractiveSelection: false,
                    subHeadingText: const AppText(' *', color: Colors.red),
                    borderType: AppTextFieldBorderType.outline,
                    validator: (email) =>
                        AppValidators.email(email.toString(), context: context),
                    prefix: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Image.asset(
                        AppAssets.emailIcon,
                        height: 20,
                        width: 20,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // About you Field
                  AppTextField(
                    controller: aboutController,
                    hintText: context.l10n.enterAboutYou,
                    headingText: context.l10n.aboutYou,
                    keyboardType: TextInputType.multiline,
                    maxLines: 5,
                    // subHeadingText: const AppText(' *', color: Colors.red),
                    borderType: AppTextFieldBorderType.outline,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _onSubmit(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 40, left: 16, right: 16),
        child: BlocBuilder<ProfileBloc, ProfileState>(
          bloc: _profileBloc,
          builder: (context, state) {
            return AppButton(
              height: 50,
              isLoading: state is ProfileLoading,
              buttonColor: AppColors.secondary,
              textColor: AppColors.blackColor,
              text: context.l10n.save,
              onPressed: _onSubmit,
            );
          },
        ),
      ),
    );
  }
}
