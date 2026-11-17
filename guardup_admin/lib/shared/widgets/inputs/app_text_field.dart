import 'package:guardup_admin/shared/widgets/location-and-phone-code/presentation/phone_code_picker.widget.dart';
import 'package:guardup_admin/shared/widgets/location-and-phone-code/services/phone_code_picker.services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';

enum AppTextFieldType {
  normal,
  password,
  search,
  date,
  dropDown,
  card,
  phone,
  email,
}

/// Sizing variants for [AppTextField].
enum AppInputSize { small, medium, large }

/// Resolved configuration specification for an [AppTextFieldType].
/// Uses a record typedef to keep semantic field configuration centralized and clean.
typedef _AppTextFieldTypeSpec = ({
  TextInputType defaultKeyboardType,
  TextInputAction defaultTextInputAction,
  List<String>? defaultAutofillHints,
  IconData? defaultPrefixIcon,
  bool isPassword,
  bool isPhone,
  bool isCard,
  bool isSearch,
  bool isDate,
  bool isDropdown,
  bool isEmail,
});

/// Resolved layout specification for an [AppInputSize].
/// Uses a record typedef to keep input sizing and typography centralized.
typedef _AppInputSizeSpec = ({
  EdgeInsetsGeometry contentPadding,
  double fontSize,
  double iconSize,
  bool isDense,
});

/// Credit card number grouping formatter (4-digit spacing).
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// An enterprise-grade, clean, and flexible text input field.
///
/// Features:
/// - Strictly follows project design guidelines in `rules.md`
/// - Semantic field types (password, email, phone, card, search, date)
/// - Sizing variants: [AppInputSize.small], [AppInputSize.medium], [AppInputSize.large]
/// - Standardized phone number country code selection with search modal dialog / sheet
/// - Dynamic clear button when text is present (built-in for search or via [clearable])
/// - Automated input formatting and keyboard actions per type
/// - Named convenience constructors for clean DX
/// - Standard [decoration] for all styling and text configurations
class AppTextField extends StatefulWidget {
  // ================= CORE =================
  final AppTextFieldType type;
  final AppInputSize size;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? initialValue;

  // ================= DECORATION =================
  final InputDecoration? decoration;

  // ================= BEHAVIOR =================
  final bool clearable;
  final String phoneCountryCode;
  final String? initialCountryCode;
  final ValueChanged<String>? onCountryCodeChanged;
  final ValueChanged<CountryWithPhoneCode>? onCountryChanged;

  // ================= TEXT INPUT =================
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final TextStyle? style;
  final StrutStyle? strutStyle;

  // ================= STATE =================
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final bool expands;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool enableInteractiveSelection;
  final bool showCursor;

  final int? maxLines;
  final int? minLines;
  final int? maxLength;

  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;

  // ================= CALLBACKS =================
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onFocus;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onEditingComplete;

  final Widget? customSuffixIcon;
  final Widget? customPrefixIcon;
  final VoidCallback? onSuffixTap;
  final GestureTapCallback? onOutsideTap;

  const AppTextField({
    super.key,
    this.type = AppTextFieldType.normal,
    this.size = AppInputSize.medium,
    this.controller,
    this.focusNode,
    this.initialValue,
    this.decoration,
    this.clearable = false,
    this.phoneCountryCode = '+91',
    this.initialCountryCode,
    this.onCountryCodeChanged,
    this.onCountryChanged,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.style,
    this.strutStyle,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.expands = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.enableInteractiveSelection = true,
    this.showCursor = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.autofillHints,
    this.onChanged,
    this.onFocus,
    this.onTap,
    this.validator,
    this.onSaved,
    this.onFieldSubmitted,
    this.onEditingComplete,
    this.customSuffixIcon,
    this.customPrefixIcon,
    this.onSuffixTap,
    this.onOutsideTap,
  });

  /// Password field with visibility toggle
  const AppTextField.password({
    super.key,
    this.size = AppInputSize.medium,
    this.controller,
    this.focusNode,
    this.initialValue,
    this.decoration,
    this.textInputAction,
    this.textAlign = TextAlign.start,
    this.style,
    this.strutStyle,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onFocus,
    this.onTap,
    this.validator,
    this.onSaved,
    this.onFieldSubmitted,
    this.onEditingComplete,
    this.customSuffixIcon,
    this.customPrefixIcon,
    this.onSuffixTap,
    this.onOutsideTap,
  }) : type = AppTextFieldType.password,
       clearable = false,
       phoneCountryCode = '+91',
       initialCountryCode = null,
       onCountryCodeChanged = null,
       onCountryChanged = null,
       keyboardType = TextInputType.visiblePassword,
       textCapitalization = TextCapitalization.none,
       expands = false,
       autocorrect = false,
       enableSuggestions = false,
       enableInteractiveSelection = true,
       showCursor = true,
       maxLines = 1,
       minLines = null,
       maxLength = null,
       inputFormatters = null,
       autofillHints = const [AutofillHints.password];

  /// Search field with prefix search icon and clear button
  const AppTextField.search({
    super.key,
    this.size = AppInputSize.medium,
    this.controller,
    this.focusNode,
    this.initialValue,
    this.decoration,
    this.clearable = true,
    this.textInputAction = TextInputAction.search,
    this.textAlign = TextAlign.start,
    this.style,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onFocus,
    this.onTap,
    this.onFieldSubmitted,
    this.onOutsideTap,
  }) : type = AppTextFieldType.search,
       phoneCountryCode = '+91',
       initialCountryCode = null,
       onCountryCodeChanged = null,
       onCountryChanged = null,
       keyboardType = TextInputType.text,
       textCapitalization = TextCapitalization.none,
       strutStyle = null,
       readOnly = false,
       expands = false,
       autocorrect = false,
       enableSuggestions = true,
       enableInteractiveSelection = true,
       showCursor = true,
       maxLines = 1,
       minLines = null,
       maxLength = null,
       inputFormatters = null,
       autofillHints = null,
       validator = null,
       onSaved = null,
       onEditingComplete = null,
       customSuffixIcon = null,
       customPrefixIcon = null,
       onSuffixTap = null;

  /// Email field with email keyboard and mail icon
  const AppTextField.email({
    super.key,
    this.size = AppInputSize.medium,
    this.controller,
    this.focusNode,
    this.initialValue,
    this.decoration,
    this.clearable = false,
    this.textInputAction,
    this.textAlign = TextAlign.start,
    this.style,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onFocus,
    this.onTap,
    this.validator,
    this.onSaved,
    this.onFieldSubmitted,
    this.onEditingComplete,
    this.customSuffixIcon,
    this.customPrefixIcon,
    this.onSuffixTap,
    this.onOutsideTap,
  }) : type = AppTextFieldType.email,
       phoneCountryCode = '+91',
       initialCountryCode = null,
       onCountryCodeChanged = null,
       onCountryChanged = null,
       keyboardType = TextInputType.emailAddress,
       textCapitalization = TextCapitalization.none,
       strutStyle = null,
       expands = false,
       autocorrect = false,
       enableSuggestions = true,
       enableInteractiveSelection = true,
       showCursor = true,
       maxLines = 1,
       minLines = null,
       maxLength = null,
       inputFormatters = null,
       autofillHints = const [AutofillHints.email];

  /// Phone number field with standardized country code selection, flag, and formatting
  const AppTextField.phone({
    super.key,
    this.size = AppInputSize.medium,
    this.controller,
    this.focusNode,
    this.initialValue,
    this.phoneCountryCode = '+91',
    this.initialCountryCode,
    this.onCountryCodeChanged,
    this.onCountryChanged,
    this.decoration,
    this.clearable = false,
    this.textInputAction,
    this.textAlign = TextAlign.start,
    this.style,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.onFocus,
    this.onTap,
    this.validator,
    this.onSaved,
    this.onFieldSubmitted,
    this.onEditingComplete,
    this.customSuffixIcon,
    this.customPrefixIcon,
    this.onSuffixTap,
    this.onOutsideTap,
  }) : type = AppTextFieldType.phone,
       keyboardType = TextInputType.phone,
       textCapitalization = TextCapitalization.none,
       strutStyle = null,
       expands = false,
       autocorrect = false,
       enableSuggestions = true,
       enableInteractiveSelection = true,
       showCursor = true,
       maxLines = 1,
       minLines = null,
       autofillHints = const [AutofillHints.telephoneNumber];

  /// Multiline textarea field
  const AppTextField.multiline({
    super.key,
    this.size = AppInputSize.medium,
    this.controller,
    this.focusNode,
    this.initialValue,
    this.decoration,
    this.maxLines = 5,
    this.minLines = 3,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.style,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onFocus,
    this.onTap,
    this.validator,
    this.onSaved,
    this.onFieldSubmitted,
    this.onEditingComplete,
    this.onOutsideTap,
  }) : type = AppTextFieldType.normal,
       clearable = false,
       phoneCountryCode = '+91',
       initialCountryCode = null,
       onCountryCodeChanged = null,
       onCountryChanged = null,
       keyboardType = TextInputType.multiline,
       textInputAction = TextInputAction.newline,
       textCapitalization = TextCapitalization.sentences,
       strutStyle = null,
       expands = false,
       autocorrect = true,
       enableSuggestions = true,
       enableInteractiveSelection = true,
       showCursor = true,
       inputFormatters = null,
       autofillHints = null,
       customSuffixIcon = null,
       customPrefixIcon = null,
       onSuffixTap = null;

  // ---------------------------------------------------------------------
  // Type configuration mapping — uses record typedef _AppTextFieldTypeSpec
  // ---------------------------------------------------------------------
  static const Map<AppTextFieldType, _AppTextFieldTypeSpec> _typeSpecs = {
    AppTextFieldType.normal: (
      defaultKeyboardType: TextInputType.text,
      defaultTextInputAction: TextInputAction.next,
      defaultAutofillHints: null,
      defaultPrefixIcon: null,
      isPassword: false,
      isPhone: false,
      isCard: false,
      isSearch: false,
      isDate: false,
      isDropdown: false,
      isEmail: false,
    ),
    AppTextFieldType.password: (
      defaultKeyboardType: TextInputType.visiblePassword,
      defaultTextInputAction: TextInputAction.next,
      defaultAutofillHints: [AutofillHints.password],
      defaultPrefixIcon: null,
      isPassword: true,
      isPhone: false,
      isCard: false,
      isSearch: false,
      isDate: false,
      isDropdown: false,
      isEmail: false,
    ),
    AppTextFieldType.email: (
      defaultKeyboardType: TextInputType.emailAddress,
      defaultTextInputAction: TextInputAction.next,
      defaultAutofillHints: [AutofillHints.email],
      defaultPrefixIcon: Icons.mail_outline_rounded,
      isPassword: false,
      isPhone: false,
      isCard: false,
      isSearch: false,
      isDate: false,
      isDropdown: false,
      isEmail: true,
    ),
    AppTextFieldType.phone: (
      defaultKeyboardType: TextInputType.phone,
      defaultTextInputAction: TextInputAction.next,
      defaultAutofillHints: [AutofillHints.telephoneNumber],
      defaultPrefixIcon: null,
      isPassword: false,
      isPhone: true,
      isCard: false,
      isSearch: false,
      isDate: false,
      isDropdown: false,
      isEmail: false,
    ),
    AppTextFieldType.search: (
      defaultKeyboardType: TextInputType.text,
      defaultTextInputAction: TextInputAction.search,
      defaultAutofillHints: null,
      defaultPrefixIcon: CupertinoIcons.search,
      isPassword: false,
      isPhone: false,
      isCard: false,
      isSearch: true,
      isDate: false,
      isDropdown: false,
      isEmail: false,
    ),
    AppTextFieldType.card: (
      defaultKeyboardType: TextInputType.number,
      defaultTextInputAction: TextInputAction.next,
      defaultAutofillHints: [AutofillHints.creditCardNumber],
      defaultPrefixIcon: CupertinoIcons.creditcard,
      isPassword: false,
      isPhone: false,
      isCard: true,
      isSearch: false,
      isDate: false,
      isDropdown: false,
      isEmail: false,
    ),
    AppTextFieldType.date: (
      defaultKeyboardType: TextInputType.datetime,
      defaultTextInputAction: TextInputAction.next,
      defaultAutofillHints: null,
      defaultPrefixIcon: CupertinoIcons.calendar,
      isPassword: false,
      isPhone: false,
      isCard: false,
      isSearch: false,
      isDate: true,
      isDropdown: false,
      isEmail: false,
    ),
    AppTextFieldType.dropDown: (
      defaultKeyboardType: TextInputType.text,
      defaultTextInputAction: TextInputAction.next,
      defaultAutofillHints: null,
      defaultPrefixIcon: null,
      isPassword: false,
      isPhone: false,
      isCard: false,
      isSearch: false,
      isDate: false,
      isDropdown: true,
      isEmail: false,
    ),
  };

  // ---------------------------------------------------------------------
  // Size configuration mapping — uses record typedef _AppInputSizeSpec
  // ---------------------------------------------------------------------
  static const Map<AppInputSize, _AppInputSizeSpec> _sizeSpecs = {
    AppInputSize.small: (
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.sm,
      ),
      fontSize: AppSpacing.md + 1,
      iconSize: AppSpacing.lg,
      isDense: true,
    ),
    AppInputSize.medium: (
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md + 2,
        vertical: AppSpacing.md,
      ),
      fontSize: AppSpacing.md + 2,
      iconSize: AppSpacing.lg + 2,
      isDense: true,
    ),
    AppInputSize.large: (
      contentPadding: EdgeInsets.all(AppSpacing.lg),
      fontSize: AppSpacing.lg - 1,
      iconSize: AppSpacing.lg + 2,
      isDense: false,
    ),
  };

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final ValueNotifier<bool> _obscureTextNotifier;
  late final ValueNotifier<bool> _hasTextNotifier;
  late final ValueNotifier<CountryWithPhoneCode> _selectedCountryNotifier;
  TextEditingController? _internalController;

  TextEditingController get _effectiveController =>
      widget.controller ??
      (_internalController ??= TextEditingController(
        text: widget.initialValue,
      ));

  _AppTextFieldTypeSpec get _typeSpec =>
      AppTextField._typeSpecs[widget.type] ??
      AppTextField._typeSpecs[AppTextFieldType.normal]!;

  _AppInputSizeSpec get _sizeSpec =>
      AppTextField._sizeSpecs[widget.size] ??
      AppTextField._sizeSpecs[AppInputSize.medium]!;

  bool get _isPassword => _typeSpec.isPassword;
  bool get _isPhone => _typeSpec.isPhone;
  bool get _isCard => _typeSpec.isCard;
  bool get _isSearch => _typeSpec.isSearch;
  bool get _isDate => _typeSpec.isDate;
  bool get _isDropdown => _typeSpec.isDropdown;

  @override
  void initState() {
    super.initState();
    _obscureTextNotifier = ValueNotifier<bool>(_isPassword || _isCard);
    _hasTextNotifier = ValueNotifier<bool>(
      _effectiveController.text.isNotEmpty,
    );
    _effectiveController.addListener(_onTextChanged);

    final initialCountry = _findInitialCountry();
    _selectedCountryNotifier = ValueNotifier<CountryWithPhoneCode>(
      initialCountry,
    );

    if (_isPhone) {
      LocationPhoneCodeServices.init().then((_) {
        if (mounted) {
          final updated = _findInitialCountry();
          _selectedCountryNotifier.value = updated;
        }
      });
    }

    if (widget.onFocus != null && widget.focusNode != null) {
      widget.focusNode!.addListener(_onFocusChanged);
    }
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onTextChanged);
      widget.controller?.addListener(_onTextChanged);
      _hasTextNotifier.value = _effectiveController.text.isNotEmpty;
    }

    if (_isPhone &&
        (widget.initialCountryCode != oldWidget.initialCountryCode ||
            widget.phoneCountryCode != oldWidget.phoneCountryCode)) {
      final dial = widget.phoneCountryCode.replaceAll('+', '').trim();
      if (_selectedCountryNotifier.value.phoneCode != dial) {
        final updated = _findInitialCountry();
        _selectedCountryNotifier.value = updated;
      }
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onTextChanged);
    _internalController?.dispose();
    widget.focusNode?.removeListener(_onFocusChanged);
    _selectedCountryNotifier.dispose();
    _obscureTextNotifier.dispose();
    _hasTextNotifier.dispose();
    super.dispose();
  }

  CountryWithPhoneCode _findInitialCountry() {
    final map = LocationPhoneCodeServices.phoneCountries.value;
    if (map.isNotEmpty) {
      // 1. Try matching initialCountryCode (ISO alpha-2 code e.g. 'IN', 'US')
      if (widget.initialCountryCode != null &&
          widget.initialCountryCode!.isNotEmpty) {
        final code = widget.initialCountryCode!.toUpperCase().trim();
        final match = map.values.where(
          (c) => c.countryCode.toUpperCase() == code,
        );
        if (match.isNotEmpty) return match.first;
      }

      // 2. Try matching phoneCountryCode (e.g. '+91' or '+91')
      final dial = widget.phoneCountryCode.replaceAll('+', '').trim();
      if (dial.isNotEmpty) {
        final match = map.values.where((c) => c.phoneCode == dial);
        if (match.isNotEmpty) return match.first;
      }

      // 3. Fallback to India if present
      final inMatch = map.values.where(
        (c) => c.countryCode.toUpperCase() == 'IN',
      );
      if (inMatch.isNotEmpty) return inMatch.first;

      return map.values.first;
    }

    // Static default if map is not yet loaded
    if (widget.phoneCountryCode == '+1' ||
        widget.initialCountryCode?.toUpperCase() == 'US') {
      return const CountryWithPhoneCode.us();
    }
    if (widget.phoneCountryCode == '+44' ||
        widget.initialCountryCode?.toUpperCase() == 'GB') {
      return const CountryWithPhoneCode.gb();
    }
    return LocationPhoneCodeServices.defaultPhoneCountry;
  }

  // int _resolveMaxPhoneLength(CountryWithPhoneCode country) {
  //   if (widget.maxLength != null) return widget.maxLength!;
  //   String example = country.exampleNumberMobileNational.replaceAll(
  //     RegExp(r'\D'),
  //     '',
  //   );
  //   if (example.startsWith('0')) {
  //     example = example.substring(1);
  //   }
  //   return example.isNotEmpty ? example.length : 10;
  // }

  // void _onCountrySelected(CountryWithPhoneCode country) {
  //   _selectedCountryNotifier.value = country;
  //   widget.onCountryCodeChanged?.call("+${country.phoneCode}");
  //   widget.onCountryChanged?.call(country);

  //   final maxLen = _resolveMaxPhoneLength(country);
  //   if (_effectiveController.text.length > maxLen) {
  //     _effectiveController.text = _effectiveController.text.substring(
  //       0,
  //       maxLen,
  //     );
  //   }
  // }

  void _onFocusChanged() {
    if (widget.focusNode?.hasFocus ?? false) {
      widget.onFocus?.call();
    }
  }

  void _onTextChanged() {
    final nowHasText = _effectiveController.text.isNotEmpty;
    if (_hasTextNotifier.value != nowHasText) {
      _hasTextNotifier.value = nowHasText;
    }
  }

  void _togglePasswordVisibility() {
    if (!_isPassword) return;
    _obscureTextNotifier.value = !_obscureTextNotifier.value;
  }

  Widget? _buildPrefixIcon({CountryWithPhoneCode? country}) {
    if (widget.customPrefixIcon != null) {
      return widget.customPrefixIcon;
    }

    if (_isPhone && country != null) {
      return Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.sm,
          right: AppSpacing.sm,
        ),
        child: Material(
          color: context.colors.transparent,
          borderRadius: AppRadius.smRadius,
          child: InkWell(
            borderRadius: AppRadius.smRadius,
            onTap: widget.enabled && !_effectiveReadOnly
                ? () async {
                    final selected = await CountryPickerContent.showSheet(
                      _selectedCountryNotifier.value.countryCode,
                      context: context,
                    );
                    if (selected != null) {
                      _selectedCountryNotifier.value = selected;
                      widget.onCountryCodeChanged?.call(
                        "+${selected.phoneCode}",
                      );
                      widget.onCountryChanged?.call(selected);
                    }
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs + 2,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    LocationPhoneCodeServices.countryFlagEmoji(
                      country.countryCode,
                    ),
                    style: TextStyle(fontSize: _sizeSpec.fontSize + 2),
                  ),
                  AppSpacing.xs.w,
                  Text(
                    '+${country.phoneCode}',
                    style: context.textTheme.bodyMedium
                        ?.size(_sizeSpec.fontSize)
                        .semiBold()
                        .colour(
                          widget.enabled
                              ? context.colors.onSurface
                              : context.colors.onSurfaceSecondary,
                        ),
                  ),
                  (AppSpacing.xs / 2).w,
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: _sizeSpec.iconSize - 2,
                    color: context.colors.onSurfaceSecondary,
                  ),
                  AppSpacing.xs.w,
                  QuickContainer(
                    w: 1,
                    h: _sizeSpec.iconSize,
                    color: context.colors.borderLight.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_typeSpec.defaultPrefixIcon != null) {
      return Icon(
        _typeSpec.defaultPrefixIcon,
        size: _sizeSpec.iconSize,
        color: context.colors.onSurfaceSecondary,
      );
    }

    return widget.decoration?.prefixIcon;
  }

  Widget? _buildSuffixIcon() {
    final userSuffix = widget.customSuffixIcon ?? widget.decoration?.suffixIcon;

    if (_isPassword) {
      return ValueListenableBuilder<bool>(
        valueListenable: _obscureTextNotifier,
        builder: (context, obscureText, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ?userSuffix,
              IconButton(
                onPressed: _togglePasswordVisibility,
                splashRadius: AppRadius.lg,
                hoverColor: context.colors.onSurface.withValues(alpha: 0.06),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    obscureText ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                    key: ValueKey<bool>(obscureText),
                    size: 20,
                    color: context.colors.onSurfaceSecondary,
                  ),
                ),
                tooltip: obscureText ? 'Show password' : 'Hide password',
              ),
            ],
          );
        },
      );
    }

    if (widget.clearable || _isSearch) {
      return ValueListenableBuilder<bool>(
        valueListenable: _hasTextNotifier,
        builder: (context, hasText, _) {
          if (!hasText) {
            return userSuffix ?? const SizedBox.shrink();
          }
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ?userSuffix,
              IconButton(
                onPressed: () {
                  _effectiveController.clear();
                  widget.onChanged?.call('');
                },
                splashRadius: AppRadius.lg,
                hoverColor: context.colors.onSurface.withValues(alpha: 0.06),
                icon: Icon(
                  Icons.cancel_rounded,
                  size: _sizeSpec.iconSize,
                  color: context.colors.onSurfaceSecondary.withValues(alpha: 0.7),
                ),
                tooltip: 'Clear',
              ),
            ],
          );
        },
      );
    }

    if (userSuffix != null) {
      return widget.onSuffixTap != null
          ? GestureDetector(
              onTap: widget.onSuffixTap,
              behavior: HitTestBehavior.opaque,
              child: userSuffix,
            )
          : userSuffix;
    }

    if (_isDropdown) {
      return Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 20,
        color: context.colors.onSurfaceSecondary,
      );
    }

    return null;
  }

  TextInputType? _resolveKeyboardType() {
    if (widget.keyboardType != null) return widget.keyboardType;
    if (widget.minLines != null && widget.minLines! > 1) {
      return TextInputType.multiline;
    }
    return _typeSpec.defaultKeyboardType;
  }

  TextInputAction? _resolveTextInputAction() {
    if (widget.textInputAction != null) return widget.textInputAction;
    if (widget.minLines != null && widget.minLines! > 1) {
      return TextInputAction.newline;
    }
    return _typeSpec.defaultTextInputAction;
  }

  List<TextInputFormatter>? _resolveInputFormatters({
    CountryWithPhoneCode? country,
  }) {
    final formatters = <TextInputFormatter>[];

    if (_isPhone) {
      // final maxLen = country != null
      //     ? _resolveMaxPhoneLength(country)
      //     : (widget.maxLength ?? 10);
      final maxLen = (widget.maxLength ?? 10);
      formatters.add(FilteringTextInputFormatter.digitsOnly);
      formatters.add(LengthLimitingTextInputFormatter(maxLen));
    } else if (_isCard) {
      formatters.add(FilteringTextInputFormatter.digitsOnly);
      formatters.add(LengthLimitingTextInputFormatter(19));
      formatters.add(_CardNumberFormatter());
    }

    if (widget.inputFormatters != null) {
      formatters.addAll(widget.inputFormatters!);
    }

    return formatters.isNotEmpty ? formatters : null;
  }

  Iterable<String>? _resolveAutofillHints() =>
      widget.autofillHints ?? _typeSpec.defaultAutofillHints;

  bool get _effectiveReadOnly => widget.readOnly || _isDate || _isDropdown;

  int? get _effectiveMaxLines {
    if (_isPassword) return 1;
    return widget.expands ? null : widget.maxLines;
  }

  EdgeInsetsGeometry? _resolveContentPadding() =>
      widget.decoration?.contentPadding ?? _sizeSpec.contentPadding;

  double _resolveFontSize() => _sizeSpec.fontSize;

  InputDecoration _buildDecoration(
    BuildContext context, {
    CountryWithPhoneCode? country,
  }) {
    final themeDecoration = const InputDecoration().applyDefaults(
      Theme.of(context).inputDecorationTheme,
    );

    final userDecoration = widget.decoration;

    return themeDecoration.copyWith(
      hintText: userDecoration?.hintText,
      hintStyle:
          userDecoration?.hintStyle ??
          themeDecoration.hintStyle?.size(_resolveFontSize()),
      labelText: userDecoration?.labelText,
      labelStyle: userDecoration?.labelStyle,
      helperText: userDecoration?.helperText,
      helperStyle: userDecoration?.helperStyle,
      errorText: userDecoration?.errorText,
      errorStyle: userDecoration?.errorStyle,
      counterText: userDecoration?.counterText,
      prefixIcon: _buildPrefixIcon(country: country),
      prefix: userDecoration?.prefix,
      suffix: userDecoration?.suffix,
      suffixIcon: _buildSuffixIcon(),
      prefixText: userDecoration?.prefixText,
      prefixIconConstraints: _isPhone && country != null
          ? const BoxConstraints(minWidth: 0, minHeight: 0)
          : (widget.decoration?.prefixIconConstraints ??
                userDecoration?.prefixIconConstraints),
      suffixIconConstraints: userDecoration?.suffixIconConstraints,
      suffixText: userDecoration?.suffixText,
      filled: userDecoration?.filled ?? themeDecoration.filled,
      fillColor: userDecoration?.fillColor ?? themeDecoration.fillColor,
      border: userDecoration?.border,
      enabledBorder: userDecoration?.enabledBorder,
      focusedBorder: userDecoration?.focusedBorder,
      disabledBorder: userDecoration?.disabledBorder,
      errorBorder: userDecoration?.errorBorder,
      focusedErrorBorder: userDecoration?.focusedErrorBorder,
      contentPadding: _resolveContentPadding(),
      isDense: _sizeSpec.isDense ? true : userDecoration?.isDense,
      alignLabelWithHint: userDecoration?.alignLabelWithHint,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isPhone) {
      return ValueListenableBuilder<CountryWithPhoneCode>(
        valueListenable: _selectedCountryNotifier,
        builder: (context, country, _) {
          return _buildTextFormField(context, country: country);
        },
      );
    }
    return _buildTextFormField(context);
  }

  Widget _buildTextFormField(
    BuildContext context, {
    CountryWithPhoneCode? country,
  }) {
    final effectiveStyle = (widget.style ?? context.textTheme.bodyMedium)
        ?.size(_resolveFontSize())
        .colour(
          widget.enabled
              ? context.colors.onSurface
              : context.colors.onSurfaceSecondary,
        );

    final effectiveValidator = widget.validator;
    // final effectiveValidator =
    //     widget.validator ??
    //     (_isPhone && country != null
    //         ? (v) {
    //             final maxLen = _resolveMaxPhoneLength(country);
    //             if (v == null || v.isEmpty) {
    //               return 'Please enter mobile number';
    //             }
    //             if (v.length < maxLen) {
    //               return 'Please enter a valid mobile number';
    //             }
    //             return null;
    //           }
    //         : null);

    return ValueListenableBuilder<bool>(
      valueListenable: _obscureTextNotifier,
      builder: (context, obscureText, _) {
        return TextFormField(
          controller: _effectiveController,
          focusNode: widget.focusNode,
          keyboardType: _resolveKeyboardType(),
          textInputAction: _resolveTextInputAction(),
          textCapitalization: widget.textCapitalization,
          textAlign: widget.textAlign,
          textAlignVertical: widget.maxLines != 1
              ? TextAlignVertical.top
              : TextAlignVertical.center,
          style: effectiveStyle,
          strutStyle: widget.strutStyle,
          obscureText: obscureText,
          readOnly: _effectiveReadOnly,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          expands: widget.expands,
          autocorrect: _isPassword ? false : widget.autocorrect,
          enableSuggestions: _isPassword ? false : widget.enableSuggestions,
          enableInteractiveSelection: widget.enableInteractiveSelection,
          showCursor: widget.showCursor,
          maxLines: _effectiveMaxLines,
          minLines: widget.expands ? null : widget.minLines,
          maxLength: widget.maxLength,
          inputFormatters: _resolveInputFormatters(country: country),
          autofillHints: _resolveAutofillHints(),
          onChanged: widget.onChanged,
          onTap: widget.onTap,
          validator: effectiveValidator,
          onSaved: widget.onSaved,
          onFieldSubmitted: widget.onFieldSubmitted,
          onEditingComplete: widget.onEditingComplete,
          decoration: _buildDecoration(context, country: country),
          onTapOutside: (_) => widget.onOutsideTap != null
              ? widget.onOutsideTap!()
              : FocusManager.instance.primaryFocus?.unfocus(),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Standardized Country Picker Dialog & Sheet
// -----------------------------------------------------------------------------
