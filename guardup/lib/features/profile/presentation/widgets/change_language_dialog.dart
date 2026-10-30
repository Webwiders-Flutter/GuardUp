import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/localization/locale_bloc.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';

class ChangeLanguageDialog extends StatefulWidget {
  const ChangeLanguageDialog({super.key});

  @override
  State<ChangeLanguageDialog> createState() => _ChangeLanguageDialogState();
}

class _ChangeLanguageDialogState extends State<ChangeLanguageDialog> {
  String? _selectedLanguageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLanguageCode ??= context
        .read<LocaleBloc>()
        .state
        .locale
        .languageCode;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(
        0xFF13192B,
      ), // Dark background matching the screenshot
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: CloseButton(
                    color: Colors.grey,
                    style: ButtonStyle(visualDensity: VisualDensity.compact),

                    // onTap: () => Navigator.pop(context),
                    // child: const Icon(
                    //   Icons.close,
                    //   color: Colors.grey,
                    //   size: 24,
                    // ),
                  ),
                ),
                Text(
                  context.l10n.chooseLanguage,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: AppColors.surfaceLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // English Option
            _buildLanguageOption(context.l10n.english, 'en'),
            const SizedBox(height: 20),

            // Arabic Option
            _buildLanguageOption(context.l10n.arabic, 'ar'),
            const SizedBox(height: 40),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<LocaleBloc>().add(
                    ChangeLocale(Locale(_selectedLanguageCode!)),
                  );
                  Navigator.pop(context, _selectedLanguageCode);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary, // Yellow/Gold color
                  foregroundColor: Colors.black, // Black text
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  context.l10n.apply,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String title, String languageCode) {
    final bool isSelected = _selectedLanguageCode == languageCode;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _selectedLanguageCode = languageCode;
        });
      },
      child: Row(
        children: [
          // Custom Radio Button
          Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.secondary : Colors.grey,
                width: 1.5,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      height: 12,
                      width: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondary,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          // Language Text
          Text(
            title,
            style: context.textTheme.bodyLarge?.copyWith(
              color: isSelected ? AppColors.secondary : AppColors.surfaceLight,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
