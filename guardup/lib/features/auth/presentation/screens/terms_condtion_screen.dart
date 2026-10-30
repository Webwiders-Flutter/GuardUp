import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/features/auth/presentation/bloc/content_cubit/content_cubit.dart';

import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/common/custom_app_bar.dart';

class TermsAndConditionScreen extends StatefulWidget {
  const TermsAndConditionScreen({super.key});

  @override
  State<TermsAndConditionScreen> createState() =>
      _TermsAndConditionScreenState();
}

class _TermsAndConditionScreenState extends State<TermsAndConditionScreen> {
  late ContentCubit _contentCubit;

  @override
  void initState() {
    super.initState();
    _contentCubit = ContentCubit();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final langCode = Localizations.localeOf(context).languageCode;
    _contentCubit.fetchContent('termsAndConditions', langCode);
  }

  @override
  void dispose() {
    _contentCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        showBackButton: true,
        title: context.l10n.termsAndConditions,
      ),
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      body: BlocProvider.value(
        value: _contentCubit,
        child: BlocBuilder<ContentCubit, ContentState>(
          builder: (context, state) {
            if (state is ContentLoading || state is ContentInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.secondary),
              );
            }

            String htmlData = "";
            if (state is ContentLoaded) {
              htmlData = state.htmlData;
            } else if (state is ContentError) {
              htmlData = "<p>${context.translateFailure(state.message)}</p>";
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 90,
                bottom: 20,
              ),
              child: Html(
                data: htmlData,
                // style: {
                //   "body": Style(
                //     margin: Margins.zero,
                //     padding: HtmlPaddings.zero,
                //     fontSize: FontSize(14),
                //     lineHeight: const LineHeight(1.6),
                //     color: AppColors.whiteColor,
                //   ),
                // "h2": Style(
                //   fontSize: FontSize(18),
                //   fontWeight: FontWeight.w600,
                //   color: AppColors.warning,
                //   margin: Margins.only(top: 20, bottom: 10),
                // ),
                // "p": Style(
                //   fontSize: FontSize(13),
                //   lineHeight: const LineHeight(1.6),
                //   color: AppColors.whiteColor,
                //   margin: Margins.only(bottom: 12),
                // ),
                // "ul": Style(margin: Margins.only(left: 10, bottom: 12)),
                // "li": Style(
                //   fontSize: FontSize(14),
                //   color: AppColors.whiteColor,
                //   lineHeight: const LineHeight(1.6),
                // ),
                // "strong": Style(
                //   fontWeight: FontWeight.bold,
                //   color: AppColors.whiteColor,
                // ),
                // },
              ),
            );
          },
        ),
      ),
    );
  }
}
