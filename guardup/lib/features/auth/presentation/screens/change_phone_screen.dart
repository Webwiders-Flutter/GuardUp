import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/app_router.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/utils/ui_feedback.dart';
import 'package:guardup/core/widgets/app_button/app_button.dart';
import 'package:guardup/core/widgets/app_phone_textfield/app_phone_textfield.dart';
import 'package:guardup/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:guardup/features/auth/presentation/widgets/auth_header_widget.dart';

import '../../../../core/widgets/common/custom_app_bar.dart';

class ChangePhoneScreen extends StatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  State<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends State<ChangePhoneScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  CountryWithPhoneCode? _selectedCountry;

  void _onChangePhone() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedCountry == null) return;
      context.read<AuthBloc>().add(
        AuthUpdatePhoneRequested(
          newPhone: phoneController.text.trim(),
          phoneCode: _selectedCountry!.phoneCode,
          countryCode: _selectedCountry!.countryCode,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      phoneController.text = authState.user.phone ?? '';

      // Initialize _selectedCountry from current user data if possible
      final countryCode = authState.user.countryCode ?? 'US';
      _initCountry(countryCode);
    }
  }

  Future<void> _initCountry(String code) async {
    if (PhoneNumberServices.all.value.isEmpty) {
      await PhoneNumberServices.init();
    }
    final country = PhoneNumberServices.all.value.values.firstWhere(
      (c) => c.countryCode == code,
      orElse: () => CountryWithPhoneCode.us(),
    );
    setState(() {
      _selectedCountry = country;
    });
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthErrorState) {
          UIFeedback.showSnackbar(
            context,
            context.translateFailure(state.message),
            isError: true,
          );
        } else if (state is AuthUpdatePhoneOtpSentState) {
          // Navigate to OTP screen
          context.pushNamed(
            AppRouter.enterOtp,
            extra: {
              'routeName': 'change_phone',
              'email': state.phone, // Passing phone number inside 'email' key because of generic identifier
              'phoneCode': state.phoneCode,
              'countryCode': state.countryCode,
            },
          );
        } else if (state is AuthUpdatePhoneSuccessState) {
          UIFeedback.showSnackbar(context, context.l10n.phoneChangedSuccess);
          context.read<AuthBloc>().add(const AuthRefreshEvent());
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.mainBackgroundColor,
        appBar: CustomAppBar(
          backgroundColor: Colors.transparent,
          showBackButton: true,
          titleColor: AppColors.whiteColor,
          title: context.l10n.changePhone,
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: isKeyboardOpen ? 80 : 16,
            ),
            child: AnimatedSlide(
              offset: isKeyboardOpen ? const Offset(0, -0.18) : Offset.zero,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthHeaderWidget(
                      title: context.l10n.changePhone,
                      subtitle: context.l10n.changePhoneSubtitle,
                    ),
                    AppPhoneField(
                      controller: phoneController,
                      headingText: context.l10n.newPhoneLabel,
                      onCountryChanged: (c) {
                        setState(() {
                          _selectedCountry = c;
                        });
                      },
                      textColor: Colors.white,
                      fillColor: AppColors.color132030,
                      initialCountryCode:
                          (context.read<AuthBloc>().state as AuthenticatedState)
                              .user
                              .countryCode ??
                          'US',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(bottom: 40, left: 16, right: 16),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return AppButton(
                height: 50,
                isLoading: state is AuthLoadingState,
                buttonColor: AppColors.secondary,
                textColor: AppColors.blackColor,
                text: context.l10n.save,
                onPressed: _onChangePhone,
              );
            },
          ),
        ),
      ),
    );
  }
}
