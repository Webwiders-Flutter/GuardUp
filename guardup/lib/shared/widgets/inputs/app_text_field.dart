import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/functionalities/location-and-phone-code/presentation/phone_code_picker.widget.dart';
import '/shared/functionalities/location-and-phone-code/services/phone_code_picker.services.dart';

// =============================================================================
// ENUMS & SPECIFICATIONS
// =============================================================================

/// Semantic types supported by [AppTextField].
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
typedef _AppTextFieldTypeSpec = ({
  TextInputType keyboardType,
  TextInputAction textInputAction,
  List<String>? autofillHints,
  IconData? prefixIcon,
  bool isPassword,
  bool isPhone,
  bool isCard,
  bool isSearch,
  bool isDate,
  bool isDropdown,
});

/// Resolved layout specification for an [AppInputSize].
typedef _AppInputSizeSpec = ({
  EdgeInsetsGeometry contentPadding,
  double fontSize,
  double iconSize,
  bool isDense,
});

// =============================================================================
// FORMATTERS
// =============================================================================

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

// =============================================================================
// MAIN WIDGET: AppTextField
// =============================================================================

/// A flexible, well-structured, and production-ready text input field.
///
/// Designed with centralized specs, lightweight factory constructors,
/// and uses [InputDecoration] directly for field decoration customization.
class AppTextField extends StatefulWidget {
  // ── Core Configuration ─────────────────────────────────────────────────────
  final AppTextFieldType type;
  final AppInputSize size;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? initialValue;

  // ── Decoration & Styling ───────────────────────────────────────────────────
  final InputDecoration? decoration;
  final TextStyle? style;
  final StrutStyle? strutStyle;

  // ── Input & Formatting ─────────────────────────────────────────────────────
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;

  // ── State & Behavior Flags ─────────────────────────────────────────────────
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final bool expands;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool enableInteractiveSelection;
  final bool showCursor;
  final bool clearable;

  // ── Phone-specific Configuration ───────────────────────────────────────────
  final String phoneCountryCode;
  final String? initialCountryCode;
  final ValueChanged<String>? onCountryCodeChanged;
  final ValueChanged<CountryWithPhoneCode>? onCountryChanged;

  // ── Callbacks ──────────────────────────────────────────────────────────────
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onFocus;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final FormFieldSetter<String>? onSaved;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onEditingComplete;
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
    this.style,
    this.strutStyle,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.sentences,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.autofillHints,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.expands = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.enableInteractiveSelection = true,
    this.showCursor = true,
    this.clearable = false,
    this.phoneCountryCode = '+91',
    this.initialCountryCode,
    this.onCountryCodeChanged,
    this.onCountryChanged,
    this.onChanged,
    this.onTap,
    this.onFocus,
    this.validator,
    this.autovalidateMode,
    this.onSaved,
    this.onFieldSubmitted,
    this.onEditingComplete,
    this.onSuffixTap,
    this.onOutsideTap,
  });

  // ── Lightweight Convenience Factories ──────────────────────────────────────

  /// Password field with visibility toggle and secured defaults.
  factory AppTextField.password({
    Key? key,
    AppInputSize size = AppInputSize.medium,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? initialValue,
    InputDecoration? decoration,
    TextInputAction? textInputAction,
    TextAlign textAlign = TextAlign.start,
    TextStyle? style,
    StrutStyle? strutStyle,
    bool readOnly = false,
    bool enabled = true,
    bool autofocus = false,
    ValueChanged<String>? onChanged,
    VoidCallback? onFocus,
    VoidCallback? onTap,
    FormFieldValidator<String>? validator,
    AutovalidateMode? autovalidateMode,
    FormFieldSetter<String>? onSaved,
    ValueChanged<String>? onFieldSubmitted,
    VoidCallback? onEditingComplete,
    VoidCallback? onSuffixTap,
    GestureTapCallback? onOutsideTap,
  }) => AppTextField(
    key: key,
    type: AppTextFieldType.password,
    size: size,
    controller: controller,
    focusNode: focusNode,
    initialValue: initialValue,
    decoration: decoration,
    textInputAction: textInputAction,
    textAlign: textAlign,
    style: style,
    strutStyle: strutStyle,
    readOnly: readOnly,
    enabled: enabled,
    autofocus: autofocus,
    onChanged: onChanged,
    onFocus: onFocus,
    onTap: onTap,
    validator: validator,
    autovalidateMode: autovalidateMode,
    onSaved: onSaved,
    onFieldSubmitted: onFieldSubmitted,
    onEditingComplete: onEditingComplete,
    onSuffixTap: onSuffixTap,
    onOutsideTap: onOutsideTap,
  );

  /// Search field with search prefix icon and clear button.
  factory AppTextField.search({
    Key? key,
    AppInputSize size = AppInputSize.medium,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? initialValue,
    InputDecoration? decoration,
    bool clearable = true,
    TextInputAction textInputAction = TextInputAction.search,
    TextAlign textAlign = TextAlign.start,
    TextStyle? style,
    StrutStyle? strutStyle,
    bool enabled = true,
    bool autofocus = false,
    ValueChanged<String>? onChanged,
    VoidCallback? onFocus,
    VoidCallback? onTap,
    ValueChanged<String>? onFieldSubmitted,
    GestureTapCallback? onOutsideTap,
  }) => AppTextField(
    key: key,
    type: AppTextFieldType.search,
    size: size,
    controller: controller,
    focusNode: focusNode,
    initialValue: initialValue,
    decoration: decoration,
    clearable: clearable,
    textInputAction: textInputAction,
    textAlign: textAlign,
    style: style,
    strutStyle: strutStyle,
    enabled: enabled,
    autofocus: autofocus,
    onChanged: onChanged,
    onFocus: onFocus,
    onTap: onTap,
    onFieldSubmitted: onFieldSubmitted,
    onOutsideTap: onOutsideTap,
  );

  /// Email field with email keyboard and mail icon.
  factory AppTextField.email({
    Key? key,
    AppInputSize size = AppInputSize.medium,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? initialValue,
    InputDecoration? decoration,
    bool clearable = false,
    TextInputAction? textInputAction,
    TextAlign textAlign = TextAlign.start,
    TextStyle? style,
    StrutStyle? strutStyle,
    bool readOnly = false,
    bool enabled = true,
    bool autofocus = false,
    ValueChanged<String>? onChanged,
    VoidCallback? onFocus,
    VoidCallback? onTap,
    FormFieldValidator<String>? validator,
    AutovalidateMode? autovalidateMode,
    FormFieldSetter<String>? onSaved,
    ValueChanged<String>? onFieldSubmitted,
    VoidCallback? onEditingComplete,
    VoidCallback? onSuffixTap,
    GestureTapCallback? onOutsideTap,
  }) => AppTextField(
    key: key,
    type: AppTextFieldType.email,
    size: size,
    controller: controller,
    focusNode: focusNode,
    initialValue: initialValue,
    decoration: decoration,
    clearable: clearable,
    textInputAction: textInputAction,
    textAlign: textAlign,
    style: style,
    strutStyle: strutStyle,
    readOnly: readOnly,
    enabled: enabled,
    autofocus: autofocus,
    onChanged: onChanged,
    onFocus: onFocus,
    onTap: onTap,
    validator: validator,
    autovalidateMode: autovalidateMode,
    onSaved: onSaved,
    onFieldSubmitted: onFieldSubmitted,
    onEditingComplete: onEditingComplete,
    onSuffixTap: onSuffixTap,
    onOutsideTap: onOutsideTap,
  );

  /// Phone number field with country code selection and flag.
  factory AppTextField.phone({
    Key? key,
    AppInputSize size = AppInputSize.medium,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? initialValue,
    String phoneCountryCode = '+91',
    String? initialCountryCode,
    ValueChanged<String>? onCountryCodeChanged,
    ValueChanged<CountryWithPhoneCode>? onCountryChanged,
    InputDecoration? decoration,
    bool clearable = false,
    TextInputAction? textInputAction,
    TextAlign textAlign = TextAlign.start,
    TextStyle? style,
    StrutStyle? strutStyle,
    bool readOnly = false,
    bool enabled = true,
    bool autofocus = false,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    VoidCallback? onFocus,
    VoidCallback? onTap,
    FormFieldValidator<String>? validator,
    AutovalidateMode? autovalidateMode,
    FormFieldSetter<String>? onSaved,
    ValueChanged<String>? onFieldSubmitted,
    VoidCallback? onEditingComplete,
    VoidCallback? onSuffixTap,
    GestureTapCallback? onOutsideTap,
  }) => AppTextField(
    key: key,
    type: AppTextFieldType.phone,
    size: size,
    controller: controller,
    focusNode: focusNode,
    initialValue: initialValue,
    phoneCountryCode: phoneCountryCode,
    initialCountryCode: initialCountryCode,
    onCountryCodeChanged: onCountryCodeChanged,
    onCountryChanged: onCountryChanged,
    decoration: decoration,
    clearable: clearable,
    textInputAction: textInputAction,
    textAlign: textAlign,
    style: style,
    strutStyle: strutStyle,
    readOnly: readOnly,
    enabled: enabled,
    autofocus: autofocus,
    maxLength: maxLength,
    inputFormatters: inputFormatters,
    onChanged: onChanged,
    onFocus: onFocus,
    onTap: onTap,
    validator: validator,
    autovalidateMode: autovalidateMode,
    onSaved: onSaved,
    onFieldSubmitted: onFieldSubmitted,
    onEditingComplete: onEditingComplete,
    onSuffixTap: onSuffixTap,
    onOutsideTap: onOutsideTap,
  );

  /// Multiline textarea field.
  factory AppTextField.multiline({
    Key? key,
    AppInputSize size = AppInputSize.medium,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? initialValue,
    InputDecoration? decoration,
    int maxLines = 5,
    int minLines = 3,
    int? maxLength,
    TextAlign textAlign = TextAlign.start,
    TextStyle? style,
    StrutStyle? strutStyle,
    bool readOnly = false,
    bool enabled = true,
    bool autofocus = false,
    ValueChanged<String>? onChanged,
    VoidCallback? onFocus,
    VoidCallback? onTap,
    FormFieldValidator<String>? validator,
    AutovalidateMode? autovalidateMode,
    FormFieldSetter<String>? onSaved,
    ValueChanged<String>? onFieldSubmitted,
    VoidCallback? onEditingComplete,
    GestureTapCallback? onOutsideTap,
  }) => AppTextField(
    key: key,
    type: AppTextFieldType.normal,
    size: size,
    controller: controller,
    focusNode: focusNode,
    initialValue: initialValue,
    decoration: decoration,
    maxLines: maxLines,
    minLines: minLines,
    maxLength: maxLength,
    keyboardType: TextInputType.multiline,
    textInputAction: TextInputAction.newline,
    textAlign: textAlign,
    style: style,
    strutStyle: strutStyle,
    readOnly: readOnly,
    enabled: enabled,
    autofocus: autofocus,
    onChanged: onChanged,
    onFocus: onFocus,
    onTap: onTap,
    validator: validator,
    autovalidateMode: autovalidateMode,
    onSaved: onSaved,
    onFieldSubmitted: onFieldSubmitted,
    onEditingComplete: onEditingComplete,
    onOutsideTap: onOutsideTap,
  );

  // ── Centralized Specifications ─────────────────────────────────────────────

  static const Map<AppTextFieldType, _AppTextFieldTypeSpec> _typeSpecs = {
    AppTextFieldType.normal: (
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      autofillHints: null,
      prefixIcon: null,
      isPassword: false,
      isPhone: false,
      isCard: false,
      isSearch: false,
      isDate: false,
      isDropdown: false,
    ),
    AppTextFieldType.password: (
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.next,
      autofillHints: [AutofillHints.password],
      prefixIcon: null,
      isPassword: true,
      isPhone: false,
      isCard: false,
      isSearch: false,
      isDate: false,
      isDropdown: false,
    ),
    AppTextFieldType.email: (
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: [AutofillHints.email],
      prefixIcon: null,
      isPassword: false,
      isPhone: false,
      isCard: false,
      isSearch: false,
      isDate: false,
      isDropdown: false,
    ),
    AppTextFieldType.phone: (
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      autofillHints: [AutofillHints.telephoneNumber],
      prefixIcon: null,
      isPassword: false,
      isPhone: true,
      isCard: false,
      isSearch: false,
      isDate: false,
      isDropdown: false,
    ),
    AppTextFieldType.search: (
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      autofillHints: null,
      prefixIcon: CupertinoIcons.search,
      isPassword: false,
      isPhone: false,
      isCard: false,
      isSearch: true,
      isDate: false,
      isDropdown: false,
    ),
    AppTextFieldType.card: (
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      autofillHints: [AutofillHints.creditCardNumber],
      prefixIcon: CupertinoIcons.creditcard,
      isPassword: false,
      isPhone: false,
      isCard: true,
      isSearch: false,
      isDate: false,
      isDropdown: false,
    ),
    AppTextFieldType.date: (
      keyboardType: TextInputType.datetime,
      textInputAction: TextInputAction.next,
      autofillHints: null,
      prefixIcon: CupertinoIcons.calendar,
      isPassword: false,
      isPhone: false,
      isCard: false,
      isSearch: false,
      isDate: true,
      isDropdown: false,
    ),
    AppTextFieldType.dropDown: (
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      autofillHints: null,
      prefixIcon: null,
      isPassword: false,
      isPhone: false,
      isCard: false,
      isSearch: false,
      isDate: false,
      isDropdown: true,
    ),
  };

  static final Map<AppInputSize, _AppInputSizeSpec> _sizeSpecs = {
    AppInputSize.small: (
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.smd,
        vertical: AppSpacing.sm,
      ),
      fontSize: 13,
      iconSize: AppSizes.iconSmd,
      isDense: true,
    ),
    AppInputSize.medium: (
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.mlg,
      ),
      fontSize: 15,
      iconSize: AppSizes.iconMd,
      isDense: false,
    ),
    AppInputSize.large: (
      contentPadding: AppSpacing.lg.allPadding,
      fontSize: 16,
      iconSize: AppSizes.iconLg,
      isDense: false,
    ),
  };

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

// =============================================================================
// STATE & RENDERING
// =============================================================================

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;
  late final ValueNotifier<CountryWithPhoneCode> _selectedCountryNotifier;
  TextEditingController? _internalController;
  bool _hasText = false;

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
  bool get _effectiveReadOnly =>
      widget.readOnly || _typeSpec.isDate || _typeSpec.isDropdown;

  @override
  void initState() {
    super.initState();
    _obscureText = _isPassword || _isCard;
    _hasText = _effectiveController.text.isNotEmpty;
    _effectiveController.addListener(_onTextChanged);

    final initialCountry = _findInitialCountry();
    _selectedCountryNotifier = ValueNotifier<CountryWithPhoneCode>(
      initialCountry,
    );

    if (_isPhone) {
      LocationPhoneCodeServices.init().then((_) {
        if (mounted) {
          _selectedCountryNotifier.value = _findInitialCountry();
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
      _hasText = _effectiveController.text.isNotEmpty;
    }

    if (_isPhone &&
        (widget.initialCountryCode != oldWidget.initialCountryCode ||
            widget.phoneCountryCode != oldWidget.phoneCountryCode)) {
      _selectedCountryNotifier.value = _findInitialCountry();
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onTextChanged);
    _internalController?.dispose();
    widget.focusNode?.removeListener(_onFocusChanged);
    _selectedCountryNotifier.dispose();
    super.dispose();
  }

  CountryWithPhoneCode _findInitialCountry() {
    if (widget.initialCountryCode != null &&
        widget.initialCountryCode!.isNotEmpty) {
      final country = LocationPhoneCodeServices.findCountryByCode(
        widget.initialCountryCode!,
      );
      if (country != null) return country;
    }

    final countryByDial = LocationPhoneCodeServices.findCountryByCode(
      widget.phoneCountryCode,
    );
    if (countryByDial != null) return countryByDial;

    return LocationPhoneCodeServices.findCountryByCode('IN') ??
        LocationPhoneCodeServices.defaultPhoneCountry;
  }

  void _onFocusChanged() {
    if (widget.focusNode?.hasFocus ?? false) {
      widget.onFocus?.call();
    }
  }

  void _onTextChanged() {
    final nowHasText = _effectiveController.text.isNotEmpty;
    if (_hasText != nowHasText) {
      setState(() => _hasText = nowHasText);
    }
  }

  void _togglePasswordVisibility() {
    if (!_isPassword) return;
    setState(() => _obscureText = !_obscureText);
  }

  // ── Prefix & Suffix Icon Composition ───────────────────────────────────────

  Widget? _buildPrefixIcon({CountryWithPhoneCode? country}) {
    if (widget.decoration?.prefixIcon != null) {
      return widget.decoration!.prefixIcon;
    }

    if (_isPhone && country != null) {
      return _PhonePrefixSelector(
        country: country,
        enabled: widget.enabled && !_effectiveReadOnly,
        fontSize: _sizeSpec.fontSize,
        iconSize: _sizeSpec.iconSize,
        onSelected: (selected) {
          _selectedCountryNotifier.value = selected;
          widget.onCountryCodeChanged?.call('+${selected.phoneCode}');
          widget.onCountryChanged?.call(selected);
        },
      );
    }

    if (_typeSpec.prefixIcon != null) {
      return Icon(
        _typeSpec.prefixIcon,
        size: _sizeSpec.iconSize,
        color: context.colors.onSurfaceVariant,
      );
    }

    return null;
  }

  Widget? _buildSuffixIcon() {
    final customSuffix = widget.decoration?.suffixIcon;

    if (_isPassword) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?customSuffix,
          IconButton(
            onPressed: _togglePasswordVisibility,
            splashRadius: AppRadius.lg,
            icon: Icon(
              _obscureText
                  ? CupertinoIcons.eye_slash_fill
                  : CupertinoIcons.eye_fill,
              size: AppSizes.iconMd,
              color: context.colors.outline,
            ),
            tooltip: _obscureText ? 'Show password' : 'Hide password',
          ),
        ],
      );
    }

    if ((widget.clearable || _isSearch) && _hasText) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?customSuffix,
          IconButton(
            onPressed: () {
              _effectiveController.clear();
              widget.onChanged?.call('');
            },
            splashRadius: AppRadius.lg,
            icon: Icon(
              Icons.cancel_rounded,
              size: _sizeSpec.iconSize,
              color: context.colors.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            tooltip: 'Clear',
          ),
        ],
      );
    }

    if (customSuffix != null) {
      return widget.onSuffixTap != null
          ? GestureDetector(
              onTap: widget.onSuffixTap,
              behavior: HitTestBehavior.opaque,
              child: customSuffix,
            )
          : customSuffix;
    }

    if (_typeSpec.isDropdown) {
      return Icon(
        Icons.keyboard_arrow_down_rounded,
        size: AppSizes.iconMd,
        color: context.colors.onSurfaceVariant,
      );
    }

    return null;
  }

  // ── Resolution Helpers ─────────────────────────────────────────────────────

  TextInputType? _resolveKeyboardType() {
    if (widget.keyboardType != null) return widget.keyboardType;
    if (widget.minLines != null && widget.minLines! > 1) {
      return TextInputType.multiline;
    }
    return _typeSpec.keyboardType;
  }

  TextInputAction? _resolveTextInputAction() {
    if (widget.textInputAction != null) return widget.textInputAction;
    if (widget.minLines != null && widget.minLines! > 1) {
      return TextInputAction.newline;
    }
    return _typeSpec.textInputAction;
  }

  List<TextInputFormatter>? _resolveInputFormatters() {
    final formatters = <TextInputFormatter>[];

    if (_isPhone) {
      formatters.add(FilteringTextInputFormatter.digitsOnly);
      formatters.add(LengthLimitingTextInputFormatter(widget.maxLength ?? 10));
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

  // ── Decoration Construction ────────────────────────────────────────────────

  InputDecoration _buildDecoration(
    BuildContext context, {
    CountryWithPhoneCode? country,
  }) {
    final baseDecoration = (widget.decoration ?? const InputDecoration())
        .applyDefaults(Theme.of(context).inputDecorationTheme);

    final resolvedPrefixIcon = _buildPrefixIcon(country: country);
    final resolvedSuffixIcon = _buildSuffixIcon();
    final isPhonePrefix = _isPhone && country != null;

    return baseDecoration.copyWith(
      prefixIcon: resolvedPrefixIcon,
      suffixIcon: resolvedSuffixIcon,
      prefixIconConstraints: isPhonePrefix
          ? const BoxConstraints(minWidth: 0, minHeight: 0)
          : (widget.decoration?.prefixIconConstraints ??
              baseDecoration.prefixIconConstraints),
      suffixIconConstraints: widget.decoration?.suffixIconConstraints ??
          baseDecoration.suffixIconConstraints,
      contentPadding: widget.decoration?.contentPadding ??
          baseDecoration.contentPadding ??
          _sizeSpec.contentPadding,
      isDense: widget.decoration?.isDense ??
          baseDecoration.isDense ??
          _sizeSpec.isDense,
      hintStyle: widget.decoration?.hintStyle ??
          baseDecoration.hintStyle?.size(_sizeSpec.fontSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isPhone) {
      return ValueListenableBuilder<CountryWithPhoneCode>(
        valueListenable: _selectedCountryNotifier,
        builder: (context, country, _) =>
            _buildTextFormField(context, country: country),
      );
    }
    return _buildTextFormField(context);
  }

  Widget _buildTextFormField(
    BuildContext context, {
    CountryWithPhoneCode? country,
  }) {
    final defaultColor = context.colors.surface;
    final effectiveStyle = (widget.style ?? context.textTheme.bodyMedium)
        ?.size(_sizeSpec.fontSize)
        .colour(
          widget.style?.color ??
              (widget.enabled
                  ? defaultColor
                  : defaultColor.withValues(alpha: 0.6)),
        );

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
      obscureText: _obscureText,
      readOnly: _effectiveReadOnly,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      expands: widget.expands,
      autocorrect: _isPassword ? false : widget.autocorrect,
      enableSuggestions: _isPassword ? false : widget.enableSuggestions,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      showCursor: widget.showCursor,
      maxLines: _isPassword ? 1 : (widget.expands ? null : widget.maxLines),
      minLines: widget.expands ? null : widget.minLines,
      maxLength: widget.maxLength,
      inputFormatters: _resolveInputFormatters(),
      autofillHints: widget.autofillHints ?? _typeSpec.autofillHints,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      onSaved: widget.onSaved,
      onFieldSubmitted: widget.onFieldSubmitted,
      onEditingComplete: widget.onEditingComplete,
      decoration: _buildDecoration(context, country: country),
      onTapOutside: (_) => widget.onOutsideTap != null
          ? widget.onOutsideTap!()
          : FocusManager.instance.primaryFocus?.unfocus(),
    );
  }
}

// =============================================================================
// SUBCOMPONENT: Phone Prefix Selector
// =============================================================================

class _PhonePrefixSelector extends StatelessWidget {
  final CountryWithPhoneCode country;
  final bool enabled;
  final double fontSize;
  final double iconSize;
  final ValueChanged<CountryWithPhoneCode> onSelected;

  const _PhonePrefixSelector({
    required this.country,
    required this.enabled,
    required this.fontSize,
    required this.iconSize,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.sm.xPadding,
      child: Material(
        color: context.colors.transparent,
        borderRadius: AppRadius.sm.toBorderRadius,
        child: InkWell(
          borderRadius: AppRadius.sm.toBorderRadius,
          onTap: enabled
              ? () async {
                  final picked = await PhoneCodePickerContent.showSheet(
                    country.countryCode,
                    context: context,
                  );
                  if (picked != null) {
                    onSelected(picked);
                  }
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              // horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  LocationPhoneCodeServices.countryFlagEmoji(
                    country.countryCode,
                  ),
                  style: TextStyle(fontSize: fontSize),
                ),
                AppSpacing.xs.w,
                Text(
                  '+${country.phoneCode}',
                  style: context.textTheme.bodySmall
                      ?.size(fontSize)
                      .colour(
                        enabled
                            ? context.colors.surface
                            : context.colors.onSurfaceVariant,
                      ),
                ),
                AppSpacing.xxs.w,
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: iconSize - 2,
                  color: enabled
                      ? context.colors.surface
                      : context.colors.onSurfaceVariant,
                ),
                AppSpacing.xs.w,
                QuickContainer(
                  w: 1,
                  h: iconSize,
                  color: context.colors.outlineVariant.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
