import 'package:guardup_admin/shared/widgets/location-and-phone-code/services/phone_code_picker.services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:go_router/go_router.dart';

import '/core/constants/app_spacing.dart';
import '/core/error/api_exception.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/string.extension.dart';
import '/core/utils/validators.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/navigation/app_tab_bar.dart';
import '/shared/widgets/state/app_state_view.dart';
import '../../data/models/admin_settings.model.dart';
import '../../di/admin_settings.providers.dart';
import '../controllers/admin_settings.controller.dart';
import '../models/settings_section.enum.dart';
import '../widgets/core_settings_card.dart';
import '../widgets/fees_settings_card.dart';
import '../widgets/mobile_apps_settings_card.dart';
import '../widgets/overview_section_card.dart';
import '../widgets/settings_header.dart';
import '../widgets/support_settings_card.dart';

/// Enterprise Admin Settings Screen.
///
/// Compliant with `rules.md` (Rules 2, 8, 11, 18, 21, 25, 27).
class AdminSettingsScreen extends ConsumerStatefulWidget {
  /// Route path of this screen.
  static const route = '/settings';

  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  // ── Provider & Controller Getters (Rule 25) ─────────────────────────────────
  ProviderListenable<AsyncValue<AdminSettingsModel>> get provider =>
      adminSettingsControllerProvider;
  AdminSettingsController get controller =>
      ref.read(adminSettingsControllerProvider.notifier);

  // ── Section State ───────────────────────────────────────────────────────────
  final ValueNotifier<SettingsSection> _currentSectionNotifier = ValueNotifier(
    SettingsSection.overview,
  );

  // ── Local Status Notifiers (Rule 18) ────────────────────────────────────────
  final ValueNotifier<bool> _hasUnsavedChangesNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isSavingNotifier = ValueNotifier(false);

  // ── Form Keys for Validation ────────────────────────────────────────────────
  final GlobalKey<FormState> _coreFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _feesFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _mobileAppsFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _supportFormKey = GlobalKey<FormState>();

  // ── Core & Maintenance Controllers ──────────────────────────────────────────
  final TextEditingController _maintenanceTitleController =
      TextEditingController();
  final TextEditingController _maintenanceMessageController =
      TextEditingController();
  final TextEditingController _bodyguardFeeController = TextEditingController();
  final TextEditingController _companyFeeController = TextEditingController();
  final ValueNotifier<bool> _isUnderMaintenanceNotifier = ValueNotifier(false);

  // ── Mobile Apps Controllers ─────────────────────────────────────────────────
  final TextEditingController _latestIosVersionController =
      TextEditingController();
  final TextEditingController _minimumIosVersionController =
      TextEditingController();
  final TextEditingController _iosUpdateMessageController =
      TextEditingController();
  final TextEditingController _iosAppUrlController = TextEditingController();

  final TextEditingController _latestAndroidVersionController =
      TextEditingController();
  final TextEditingController _minimumAndroidVersionController =
      TextEditingController();
  final TextEditingController _androidUpdateMessageController =
      TextEditingController();
  final TextEditingController _androidAppUrlController =
      TextEditingController();

  // ── Support Controllers ─────────────────────────────────────────────────────
  final TextEditingController _supportEmailController = TextEditingController();
  final TextEditingController _supportCallPhoneController =
      TextEditingController();
  final ValueNotifier<String> _supportCallCountryCodeController = ValueNotifier(
    LocationPhoneCodeServices.defaultPhoneCountry.phoneCode,
  );
  final TextEditingController _supportWhatsappPhoneController =
      TextEditingController();
  final ValueNotifier<String> _supportWhatsappCountryCodeController =
      ValueNotifier(LocationPhoneCodeServices.defaultPhoneCountry.phoneCode);
  final TextEditingController _supportHoursController = TextEditingController();

  bool hasInit = false;

  @override
  void dispose() {
    _currentSectionNotifier.dispose();
    _hasUnsavedChangesNotifier.dispose();
    _isSavingNotifier.dispose();

    _isUnderMaintenanceNotifier.dispose();
    _maintenanceTitleController.dispose();
    _maintenanceMessageController.dispose();
    _bodyguardFeeController.dispose();
    _companyFeeController.dispose();

    _latestIosVersionController.dispose();
    _minimumIosVersionController.dispose();
    _iosUpdateMessageController.dispose();
    _iosAppUrlController.dispose();

    _latestAndroidVersionController.dispose();
    _minimumAndroidVersionController.dispose();
    _androidUpdateMessageController.dispose();
    _androidAppUrlController.dispose();

    _supportEmailController.dispose();
    _supportCallPhoneController.dispose();
    _supportCallCountryCodeController.dispose();
    _supportWhatsappPhoneController.dispose();
    _supportWhatsappCountryCodeController.dispose();
    _supportHoursController.dispose();

    super.dispose();
  }

  // ── Field Synchronization ───────────────────────────────────────────────────

  void _syncControllersWithModel(AdminSettingsModel model) {
    _maintenanceTitleController.text = model.maintenanceTitle ?? '';
    _maintenanceMessageController.text = model.maintenanceMessage ?? '';
    _bodyguardFeeController.text = model.bodyguardFee.toStringAsFixed(2);
    _companyFeeController.text = model.companyFee.toStringAsFixed(2);
    _isUnderMaintenanceNotifier.value = model.isUnderMaintenance;

    _latestIosVersionController.text = model.latestIosVersion;
    _minimumIosVersionController.text = model.minimumIosVersion;
    _iosUpdateMessageController.text = model.updateMessageIos ?? '';
    _iosAppUrlController.text = model.iosAppUrl ?? '';

    _latestAndroidVersionController.text = model.latestAndroidVersion;
    _minimumAndroidVersionController.text = model.minimumAndroidVersion;
    _androidUpdateMessageController.text = model.updateMessageAndroid ?? '';
    _androidAppUrlController.text = model.androidAppUrl ?? '';

    _supportEmailController.text = model.supportEmail;
    final (callCode, callPhone) = _parsePhoneNumber(
      model.supportCallPhoneNumber,
    );
    _supportCallCountryCodeController.value = callCode;
    _supportCallPhoneController.text = callPhone;

    final (waCode, waPhone) = _parsePhoneNumber(
      model.supportWhatsappPhoneNumber,
    );
    _supportWhatsappCountryCodeController.value = waCode;
    _supportWhatsappPhoneController.text = waPhone;
    _supportHoursController.text = model.supportHours ?? '';

    _hasUnsavedChangesNotifier.value = false;
  }

  (String, String) _parsePhoneNumber(String raw) {
    final clean = raw.replaceAll('+', '').trim();
    if (clean.isEmpty) {
      return (LocationPhoneCodeServices.defaultPhoneCountry.phoneCode, '');
    }

    final parsed = raw.parseE164Phone();
    if (parsed.phoneCode.isNotEmpty && parsed.phoneNumber.isNotEmpty) {
      return (parsed.phoneCode, parsed.phoneNumber);
    }

    if (clean.contains(' ')) {
      final parts = clean.split(' ');
      final code = parts.first.trim();
      final number = parts.sublist(1).join('').trim();
      return (
        code.isNotEmpty
            ? code
            : LocationPhoneCodeServices.defaultPhoneCountry.phoneCode,
        number,
      );
    }

    if (clean.length > 10) {
      final regions = LocationPhoneCodeServices.phoneCountries.value.values;
      for (final r in regions) {
        if (clean.startsWith(r.phoneCode)) {
          final number = clean.substring(r.phoneCode.length);
          if (number.length >= 7) {
            return (r.phoneCode, number);
          }
        }
      }
      if (clean.startsWith('91')) {
        return ('91', clean.substring(2));
      }
    }

    return (LocationPhoneCodeServices.defaultPhoneCountry.phoneCode, clean);
  }

  void _markDirty() {
    if (!_hasUnsavedChangesNotifier.value) {
      _hasUnsavedChangesNotifier.value = true;
    }
  }

  // ── Section Switching with Guard ────────────────────────────────────────────

  Future<void> _handleSectionSwitch(SettingsSection targetSection) async {
    if (targetSection == _currentSectionNotifier.value) return;

    if (!_hasUnsavedChangesNotifier.value) {
      _currentSectionNotifier.value = targetSection;
      return;
    }

    final result = await AppPopup.show(
      context: context,
      title: 'Unsaved Changes Detected',
      message: 'You have unsaved changes in settings. Would you like to save them before switching sections, or discard them?',
      variant: PopupVariant.warning,
      icon: Icons.warning_amber_rounded,
      buttons: [
        AppButton(
          text: 'Cancel',
          type: ButtonType.secondaryOff,
          onPressed: () =>
              context.pop(const PopupResult(action: PopupAction.dismiss)),
        ),
        AppButton(
          text: 'Discard & Switch',
          type: ButtonType.danger,
          onPressed: () =>
              context.pop(const PopupResult(action: PopupAction.cancel)),
        ),
        AppButton(
          text: 'Save & Switch',
          type: ButtonType.primary,
          leading: const Icon(Icons.save_rounded, size: AppSpacing.lg),
          onPressed: () =>
              context.pop(const PopupResult(action: PopupAction.confirm)),
        ),
      ],
    );

    if (result == null || result.action == PopupAction.dismiss) {
      return;
    }

    if (result.action == PopupAction.confirm) {
      final success = await _handleSave();
      if (!success) return;
    } else if (result.action == PopupAction.cancel) {
      final current = ref.read(provider).value;
      if (current != null) {
        _syncControllersWithModel(current);
      }
    }

    _currentSectionNotifier.value = targetSection;
  }

  // ── Save Action ─────────────────────────────────────────────────────────────

  Future<bool> _handleSave() async {
    // ── Form & Field Validations ──
    final isCoreValid = _coreFormKey.currentState?.validate() ?? true;
    final isFeesValid = _feesFormKey.currentState?.validate() ?? true;
    final isMobileValid = _mobileAppsFormKey.currentState?.validate() ?? true;
    final isSupportValid = _supportFormKey.currentState?.validate() ?? true;

    if (!isCoreValid || !isFeesValid || !isMobileValid || !isSupportValid) {
      AppSnackbar.show(
        message: 'Please correct the validation errors before saving.',
        type: SnackbarType.error,
      );
      return false;
    }

    final latestAndroid = _latestAndroidVersionController.text.trim();
    final minAndroid = _minimumAndroidVersionController.text.trim();
    if (Validators.compareSemver(minAndroid, latestAndroid) > 0) {
      AppSnackbar.show(
        message:
            'Minimum Android version ($minAndroid) cannot be higher than Latest version ($latestAndroid).',
        type: SnackbarType.error,
      );
      return false;
    }

    final latestIos = _latestIosVersionController.text.trim();
    final minIos = _minimumIosVersionController.text.trim();
    if (Validators.compareSemver(minIos, latestIos) > 0) {
      AppSnackbar.show(
        message:
            'Minimum iOS version ($minIos) cannot be higher than Latest version ($latestIos).',
        type: SnackbarType.error,
      );
      return false;
    }

    _isSavingNotifier.value = true;

    try {
      final payload = <String, dynamic>{
        'is_under_maintenance': _isUnderMaintenanceNotifier.value,
        'maintenance_title': _maintenanceTitleController.text.trim(),
        'maintenance_message': _maintenanceMessageController.text.trim(),
        'bodyguard_fee':
            double.tryParse(_bodyguardFeeController.text.trim()) ?? 0.0,
        'company_fee':
            double.tryParse(_companyFeeController.text.trim()) ?? 0.0,
        'latest_ios_version': _latestIosVersionController.text.trim(),
        'minimum_ios_version': _minimumIosVersionController.text.trim(),
        'update_message_ios': _iosUpdateMessageController.text.trim(),
        'ios_app_url': _iosAppUrlController.text.trim(),
        'latest_android_version': _latestAndroidVersionController.text.trim(),
        'minimum_android_version': _minimumAndroidVersionController.text.trim(),
        'update_message_android': _androidUpdateMessageController.text.trim(),
        'android_app_url': _androidAppUrlController.text.trim(),
        'support_email': _supportEmailController.text.trim(),
        'support_call_phone_number':
            _supportCallPhoneController.text.trim().isNotEmpty
            ? _supportCallPhoneController.text.trim().toE164(
                countryCode: _supportCallCountryCodeController.value.isNotEmpty
                    ? _supportCallCountryCodeController.value
                    : LocationPhoneCodeServices.defaultPhoneCountry.phoneCode,
              )
            : '',
        'support_whatsapp_phone_number':
            _supportWhatsappPhoneController.text.trim().isNotEmpty
            ? _supportWhatsappPhoneController.text.trim().toE164(
                countryCode:
                    _supportWhatsappCountryCodeController.value.isNotEmpty
                    ? _supportWhatsappCountryCodeController.value
                    : LocationPhoneCodeServices.defaultPhoneCountry.phoneCode,
              )
            : '',
        'support_hours': _supportHoursController.text.trim(),
      };

      await controller.updateSettings(payload);

      if (!mounted) return false;
      _isSavingNotifier.value = false;
      _hasUnsavedChangesNotifier.value = false;

      AppSnackbar.show(
        message: 'Settings updated and published successfully',
        type: SnackbarType.success,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      _isSavingNotifier.value = false;

      final message = e is ApiException
          ? e.message
          : 'Failed to save settings: $e';
      AppSnackbar.show(message: message, type: SnackbarType.error);
      return false;
    }
  }

  void _handleDiscard() {
    final current = ref.read(provider).value;
    if (current != null) {
      _syncControllersWithModel(current);
      AppSnackbar.show(
        message: 'Modifications discarded',
        type: SnackbarType.info,
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final asyncSettings = ref.watch(provider);

    return Scaffold(
      backgroundColor: colors.backgroundLight,
      body: SafeArea(
        child: asyncSettings.when(
          loading: () =>
              const Center(child: CircularProgressIndicator.adaptive()),
          error: (err, stack) => Center(
            child: AppStateView.error(
              message: 'Failed to load system settings',
              subtitle: err is ApiException ? err.message : err.toString(),
              actionText: 'Retry',
              onAction: () => controller.refreshSettings(),
            ),
          ),
          data: (settings) {
            if (!hasInit) {
              _syncControllersWithModel(settings);
              hasInit = true;
            }
            return RefreshIndicator(
              onRefresh: () async => controller.refreshSettings(),
              color: colors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.xl,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Top Header with Actions ──
                        SettingsHeader(
                          settings: settings,
                          hasUnsavedChangesNotifier: _hasUnsavedChangesNotifier,
                          isSavingNotifier: _isSavingNotifier,
                          onSave: _handleSave,
                          onDiscard: _handleDiscard,
                          onRefresh: () => controller.refreshSettings(),
                        ),

                        AppSpacing.lg.h,

                        // ── Section Tabs ──
                        ValueListenableBuilder<SettingsSection>(
                          valueListenable: _currentSectionNotifier,
                          builder: (context, currentSection, _) {
                            return AppTabBar.pills(
                              selectedIndex: currentSection.index,
                              items: SettingsSection.values.map((section) {
                                return AppTabItem(
                                  tabName: section.label,
                                  icon: section.icon,
                                  selectedIcon: section.selectedIcon,
                                );
                              }).toList(),
                              onTap: (index) => _handleSectionSwitch(
                                SettingsSection.values[index],
                              ),
                            );
                          },
                        ),

                        AppSpacing.xl.h,

                        // ── Active Section Content ──
                        ValueListenableBuilder<SettingsSection>(
                          valueListenable: _currentSectionNotifier,
                          builder: (context, currentSection, _) {
                            switch (currentSection) {
                              case SettingsSection.overview:
                                return OverviewSectionCard(
                                  settings: settings,
                                  onNavigateToSection: _handleSectionSwitch,
                                );

                              case SettingsSection.fees:
                                return FeesSettingsCard(
                                  formKey: _feesFormKey,
                                  bodyguardFeeController:
                                      _bodyguardFeeController,
                                  companyFeeController: _companyFeeController,
                                  onChanged: _markDirty,
                                );

                              case SettingsSection.core:
                                return CoreSettingsCard(
                                  formKey: _coreFormKey,
                                  titleController: _maintenanceTitleController,
                                  messageController:
                                      _maintenanceMessageController,
                                  isUnderMaintenanceNotifier:
                                      _isUnderMaintenanceNotifier,
                                  onChanged: _markDirty,
                                );

                              case SettingsSection.mobileApps:
                                return MobileAppsSettingsCard(
                                  formKey: _mobileAppsFormKey,
                                  latestIosVersionController:
                                      _latestIosVersionController,
                                  minimumIosVersionController:
                                      _minimumIosVersionController,
                                  iosUpdateMessageController:
                                      _iosUpdateMessageController,
                                  iosAppUrlController: _iosAppUrlController,
                                  latestAndroidVersionController:
                                      _latestAndroidVersionController,
                                  minimumAndroidVersionController:
                                      _minimumAndroidVersionController,
                                  androidUpdateMessageController:
                                      _androidUpdateMessageController,
                                  androidAppUrlController:
                                      _androidAppUrlController,
                                  onChanged: _markDirty,
                                );

                              case SettingsSection.support:
                                return SupportSettingsCard(
                                  formKey: _supportFormKey,
                                  emailController: _supportEmailController,
                                  callPhoneController:
                                      _supportCallPhoneController,
                                  callCountryCodeController:
                                      _supportCallCountryCodeController,
                                  whatsappPhoneController:
                                      _supportWhatsappPhoneController,
                                  whatsappCountryCodeController:
                                      _supportWhatsappCountryCodeController,
                                  hoursController: _supportHoursController,
                                  onChanged: _markDirty,
                                );
                            }
                          },
                        ),

                        AppSpacing.xxxl.h,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
