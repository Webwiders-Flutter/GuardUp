import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/app_types/app_text_type.dart';
import 'package:guardup/core/app_types/image_types.dart';
import 'package:guardup/core/constants/app_assets.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/constants/app_fonts.dart';
import 'package:guardup/core/utils/app_router.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/widgets/app_button/app_button.dart';
import 'package:guardup/core/widgets/app_image/app_image.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';
import 'package:guardup/core/widgets/common/custom_app_bar.dart';

class AdminApprovedScreen extends StatefulWidget {
  const AdminApprovedScreen({super.key});

  @override
  State<AdminApprovedScreen> createState() => _AdminApprovedScreenState();
}

class _AdminApprovedScreenState extends State<AdminApprovedScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  late final TextEditingController pinController;

  @override
  void initState() {
    super.initState();
    pinController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        backgroundColor: AppColors.primary,
        showBackButton: true,
        title: '',
        titleWidget: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              height: 40,
              width: 40,
              fit: BoxFit.contain,
              AppAssets.appLogo,
            ),
            SizedBox(width: 10),
            Text(
              context.l10n.adminApprovalTitle,
              style: context.textTheme.headlineMedium?.copyWith(
                color: AppColors.whiteColor,
                fontSize: 20,
                fontWeight: FontWeight.w500,
                fontFamily: AppFonts.defultFont,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  context.pushReplacement(AppRouter.login);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Image.asset(
                      height: 20,
                      width: 20,
                      fit: BoxFit.contain,
                      AppAssets.logoutIcon,
                    ),
                    SizedBox(width: 10),
                    AppText(
                      textAlign: TextAlign.center,
                      type: AppTextType.headlineLarge,
                      context.l10n.logout,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
              Center(
                child: AppImage(
                  imageUrl: AppAssets.appLogo,
                  height: 120,
                  width: 165,
                  backgroundColor: Colors.transparent,
                  fit: BoxFit.contain,
                  appFileType: AppImageTypes.asset,
                  borderRadius: 0,
                ),
              ),
              SizedBox(height: 35),
              AppText(
                textAlign: TextAlign.center,
                type: AppTextType.headlineLarge,
                context.l10n.adminApprovalSubtitle,
                fontSize: 25,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
              SizedBox(height: 15),
              Center(
                child: AppText(
                  textAlign: TextAlign.center,
                  type: AppTextType.bodyMedium,
                  context.l10n.adminApprovalDesc,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.whiteColor,
                ),
              ),
              SizedBox(height: 35),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 100),
                child: AppButton(
                  text: context.l10n.okButton,
                  onPressed: () {
                    context.pushReplacement(AppRouter.login);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
