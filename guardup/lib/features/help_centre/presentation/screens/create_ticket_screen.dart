import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/app_types/app_text_type.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/services/injection_container.dart';
import 'package:guardup/core/services/media_picker_service.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/utils/extensions/size_extensions.dart';
import 'package:guardup/core/widgets/app_button/app_button.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';
import 'package:guardup/core/widgets/app_textfield/app_textfield.dart';
import 'package:guardup/core/widgets/common/custom_app_bar.dart';
import 'package:guardup/core/widgets/common/upload_view_widget.dart';
import 'package:guardup/core/widgets/custom_dropdown/custom_dropdown.dart';

import 'package:guardup/core/error/error_keys.dart';
import 'package:guardup/features/auth/presentation/widgets/login_gate_bottom_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:guardup/core/utils/image_picker_dialog.dart';

import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/widgets/common/uploaded_file_item_widget.dart';
import '../bloc/support_cubit.dart';
import '../bloc/support_state.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final ValueNotifier<String?> _selectedCategory = ValueNotifier(null);
  final ValueNotifier<List<File>> _selectedFiles = ValueNotifier([]);

  Future<void> _pickFile() async {
    final file = await showPickFileDialog(context, sl<MediaPickerService>());
    if (file != null) {
      _selectedFiles.value = [..._selectedFiles.value, file];
    }
  }

  void _submit(BuildContext cubitContext) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      LoginGateBottomSheet.show(context);
      return;
    }
    if (_selectedCategory.value == null) {
      UIFeedback.showSnackbar(context, context.l10n.chooseCategory);
      return;
    }
    if (_subjectController.text.trim().isEmpty) {
      UIFeedback.showSnackbar(context, context.l10n.typeSubject);
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      UIFeedback.showSnackbar(context, context.l10n.typeMessage);
      return;
    }

    cubitContext.read<SupportCubit>().createTicket(
      category: _selectedCategory.value!,
      subject: _subjectController.text.trim(),
      message: _messageController.text.trim(),
      attachments: _selectedFiles.value,
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _selectedCategory.dispose();
    _selectedFiles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<SupportCubit>(),
      child: BlocConsumer<SupportCubit, SupportState>(
        listener: (context, state) {
          if (state is SupportSuccess) {
            UIFeedback.showSnackbar(context, state.message ?? '');
            context.pop(state.ticket);
          } else if (state is SupportError) {
            UIFeedback.showSnackbar(
              context,
              context.translateFailure(state.message),
              isError: true,
            );
            if (state.message == ErrorKeys.userNotAuthenticated) {
              LoginGateBottomSheet.show(context);
            }
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color.fromARGB(255, 10, 11, 13),
            appBar: CustomAppBar(
              title: context.l10n.createATicket,
              showBackButton: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppText(
                        type: AppTextType.bodySmall,
                        context.l10n.chooseCategory,
                        color: AppColors.headingTextFieldColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      const Text(
                        ' *',
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ],
                  ),
                  8.height,
                  ValueListenableBuilder<String?>(
                    valueListenable: _selectedCategory,
                    builder: (context, value, child) {
                      return CustomDropdown<String>(
                        value: value,
                        hintText: context.l10n.category,
                        borderSide: BorderSide.none,
                        items: [
                          DropdownMenuItem(
                            value: 'visa',
                            child: Text(context.l10n.visaAssistance),
                          ),
                          DropdownMenuItem(
                            value: 'tech',
                            child: Text(context.l10n.technicalIssue),
                          ),
                          DropdownMenuItem(
                            value: 'billing',
                            child: Text(context.l10n.billing),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text(context.l10n.other),
                          ),
                        ],
                        onChanged: (val) {
                          _selectedCategory.value = val;
                        },
                      );
                    },
                  ),
                  20.height,
                  AppTextField(
                    controller: _subjectController,
                    headingText: context.l10n.subject,
                    subHeadingText: const Text(
                      ' *',
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                    hintText: context.l10n.typeSubject,
                  ),
                  20.height,
                  AppTextField(
                    controller: _messageController,
                    headingText: context.l10n.message,
                    subHeadingText: const Text(
                      ' *',
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                    hintText: context.l10n.typeMessage,
                    maxLines: 5,
                  ),
                  20.height,
                  UploadViewWidget(
                    text: context.l10n.uploadJpgPngPdf,
                    onTap: _pickFile,
                  ),
                  20.height,
                  ValueListenableBuilder<List<File>>(
                    valueListenable: _selectedFiles,
                    builder: (context, files, child) {
                      if (files.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            context.l10n.uploadedDocuments,
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
                            color: AppColors.headingTextFieldColor,
                          ),
                          10.height,
                          ...files.map((file) {
                            return UploadedFileItemWidget(
                              file: file,
                              onRemove: () {
                                _selectedFiles.value = List.from(
                                  _selectedFiles.value,
                                )..remove(file);
                              },
                            );
                          }),
                        ],
                      );
                    },
                  ),
                  32.height,
                  AppButton(
                    height: 50,
                    isLoading: state is SupportActionLoading,
                    buttonColor: AppColors.secondary,
                    text: context.l10n.submit,
                    textColor: AppColors.blackColor,
                    onPressed: () => _submit(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
