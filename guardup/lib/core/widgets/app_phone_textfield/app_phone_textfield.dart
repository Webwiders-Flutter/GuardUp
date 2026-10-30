import 'dart:ui';

import 'package:country_picker/country_picker.dart' as cp;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:guardup/core/app_types/app_text_type.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/constants/app_constants.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';
import 'package:guardup/core/utils/country_search_utils.dart';

// ---------------- SERVICES ----------------

class PhoneNumberServices {
  static final ValueNotifier<Map<String, CountryWithPhoneCode>> all =
      ValueNotifier({});

  static Future<void> init() async {
    all.value = await getAllSupportedRegions();
  }

  static String getCountryCodeFromPhoneCode(
    String phoneCode, {
    String fallback = AppConstants.defaultCountryCode,
  }) {
    if (all.value.isEmpty) return fallback;
    final cleanCode = phoneCode.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanCode.isEmpty) return fallback;
    final match = all.value.values.firstWhere(
      (c) => c.phoneCode.replaceAll(RegExp(r'[^\d]'), '') == cleanCode,
      orElse: () => CountryWithPhoneCode.us(),
    );
    return match.countryCode;
  }

  static List<CountryWithPhoneCode> filter(String q, [BuildContext? context]) {
    if (q.trim().isEmpty) return all.value.values.toList();

    final countryLocalizations = context != null
        ? cp.CountryLocalizations.of(context)
        : null;

    return all.value.values.where((c) {
      final nameEn = c.countryName;
      final nameTranslated = countryLocalizations?.countryName(
        countryCode: c.countryCode,
      );

      return CountrySearchUtils.matchesQuery(
        q,
        nameEn: nameEn,
        nameAr: nameTranslated, // In Arabic mode, this will be the Arabic name
        countryCode: c.countryCode,
        phoneCode: c.phoneCode,
      );
    }).toList();
  }

  static String countryFlagEmoji(String countryCode) {
    final code = countryCode.toUpperCase();
    return String.fromCharCodes(code.codeUnits.map((c) => 0x1F1E6 + c - 65));
  }
}

// ---------------- BORDER TYPE ----------------

enum AppPhoneFieldBorderType { outline, underline }

// ---------------- WIDGET ----------------

class AppPhoneField extends StatefulWidget {
  /// REQUIRED
  final TextEditingController controller;

  /// COUNTRY
  final String initialCountryCode;
  final String keyValue;
  final bool showDialog;
  final Function(CountryWithPhoneCode)? onCountryChanged;

  /// VALIDATOR & CALLBACKS
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final Function(String?)? onSaved;
  final Function(PointerDownEvent)? onTapOutside;

  /// LAYOUT
  final double? width;
  final bool isCollapsed;
  final double horizontalPadding;
  final double verticalPadding;
  final double? contentPaddingVertical;
  final double? contentPaddingHorizontal;

  /// BORDER
  final bool isUnderLine;
  final Color? focusedBorderColor;
  final BoxBorder? border;
  final Color? borderColor;
  final double borderRadius;
  final AppPhoneFieldBorderType borderType;

  /// TEXT & HINT
  final String hintText;
  final TextAlign textAlign;
  final Color? textColor;
  final Color? hintColor;
  final double? fontSize;
  final double? hintTextFontSize;
  final double? cursorHeight;

  /// HEADING
  final String? headingText;
  final String? subHeadingText;
  final double? headingFontSize;
  final FontWeight? headingFontWeight;
  final Color? headingColor;

  /// FILL & BACKGROUND
  final bool filled;
  final Color? fillColor;
  final Color? bgColor;

  /// INPUT BEHAVIOR
  final bool obscureText;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool readOnly;
  final bool enableInteractiveSelection;
  final bool? autofocus;
  final TextCapitalization textCapitalization;
  final void Function(String)? onFieldSubmitted;
  final VoidCallback? onEditingComplete;
  final TextInputAction? textInputAction;
  final bool showIosDoneButton;
  final String? doneButtonText;

  /// FOCUS
  final FocusNode? focusNode;

  /// SHADOW
  final bool? showShadow;

  /// AFFIX
  final String? suffixText;
  final Widget? suffix;
  final Widget? subHeadWidget;
  final String? prefixText;

  const AppPhoneField({
    super.key,
    required this.controller,
    this.initialCountryCode = AppConstants.defaultCountryCode,
    this.keyValue = AppConstants.defaultCountryCode,
    this.showDialog = true,
    this.onCountryChanged,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.onTapOutside,
    this.width,
    this.isCollapsed = false,
    this.horizontalPadding = 0,
    this.verticalPadding = 0,
    this.contentPaddingVertical,
    this.contentPaddingHorizontal,
    this.isUnderLine = false,
    this.focusedBorderColor,
    this.border,
    this.borderColor,
    this.borderRadius = 10,
    this.borderType = AppPhoneFieldBorderType.outline,
    this.hintText = 'Enter phone number',
    this.textAlign = TextAlign.left,
    this.textColor,
    this.hintColor,
    this.fontSize,
    this.hintTextFontSize,
    this.cursorHeight,
    this.headingText,
    this.subHeadingText,
    this.headingFontSize,
    this.headingFontWeight,
    this.headingColor,
    this.filled = true,
    this.fillColor,
    this.bgColor,
    this.onFieldSubmitted,
    this.onEditingComplete,
    this.textInputAction = TextInputAction.done,
    this.showIosDoneButton = true,
    this.doneButtonText,
    this.obscureText = false,
    this.maxLines,
    this.maxLength,
    this.keyboardType = TextInputType.phone,
    this.enabled = true,
    this.readOnly = false,
    this.enableInteractiveSelection = true,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.showShadow = false,
    this.suffixText,
    this.suffix,
    this.prefixText,
    this.subHeadWidget,
  });

  @override
  State<AppPhoneField> createState() => _AppPhoneFieldState();
}

class _AppPhoneFieldState extends State<AppPhoneField> {
  late ValueNotifier<CountryWithPhoneCode> selected;
  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());
  OverlayEntry? _keyboardDoneOverlayEntry;

  @override
  void initState() {
    super.initState();
    selected = ValueNotifier(CountryWithPhoneCode.us());
    _effectiveFocusNode.addListener(_handleFocusChange);
    _init();
  }

  @override
  void didUpdateWidget(covariant AppPhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCountryCode != widget.initialCountryCode) {
      _updateCountryFromParent();
    }
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(
        _handleFocusChange,
      );
      if (oldWidget.focusNode == null && widget.focusNode != null) {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }
      _effectiveFocusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void deactivate() {
    _removeKeyboardOverlay();
    super.deactivate();
  }

  @override
  void dispose() {
    _removeKeyboardOverlay();
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  bool get _isIOS =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          Theme.of(context).platform == TargetPlatform.iOS);

  void _handleFocusChange() {
    if (!mounted) return;
    if (_isIOS && widget.showIosDoneButton && _effectiveFocusNode.hasFocus) {
      _showKeyboardOverlay();
    } else {
      _removeKeyboardOverlay();
    }
  }

  void _showKeyboardOverlay() {
    if (_keyboardDoneOverlayEntry != null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_isIOS ||
          !widget.showIosDoneButton ||
          !_effectiveFocusNode.hasFocus ||
          _keyboardDoneOverlayEntry != null) {
        return;
      }

      final overlayState = Overlay.maybeOf(context, rootOverlay: true);
      if (overlayState == null) return;

      _keyboardDoneOverlayEntry = OverlayEntry(
        builder: (BuildContext overlayContext) {
          final bottomInset = MediaQuery.of(overlayContext).viewInsets.bottom;
          if (bottomInset == 0) {
            return const SizedBox.shrink();
          }

          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset,
            child: Material(
              type: MaterialType.transparency,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E1E).withValues(alpha: 0.88)
                          : const Color(0xFFF7F7F8).withValues(alpha: 0.92),
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.08),
                          width: 0.5,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Quick keyboard dismiss icon
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: () {
                            _effectiveFocusNode.unfocus();
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.04),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                        // Sleek Done button
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          pressedOpacity: 0.75,
                          onPressed: () {
                            _effectiveFocusNode.unfocus();
                            widget.onEditingComplete?.call();
                            widget.onFieldSubmitted?.call(
                              widget.controller.text,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.28,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  widget.doneButtonText ?? context.l10n.done,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

      overlayState.insert(_keyboardDoneOverlayEntry!);
    });
  }

  void _removeKeyboardOverlay() {
    _keyboardDoneOverlayEntry?.remove();
    _keyboardDoneOverlayEntry = null;
  }

  void _updateCountryFromParent() {
    final service = PhoneNumberServices.all.value;
    if (service.isEmpty) return;
    final updated = service.values.firstWhere(
      (c) => c.countryCode == widget.initialCountryCode,
      orElse: () => selected.value,
    );
    selected.value = updated;
  }

  Future<void> _init() async {
    if (PhoneNumberServices.all.value.isEmpty) {
      await PhoneNumberServices.init();
    }
    _updateCountryFromParent();
  }

  InputBorder _buildBorder(BuildContext context, {Color? color}) {
    final effectiveBorderType = widget.isUnderLine
        ? AppPhoneFieldBorderType.underline
        : widget.borderType;

    if (effectiveBorderType == AppPhoneFieldBorderType.underline) {
      return UnderlineInputBorder(
        borderSide: BorderSide(
          color: color ?? widget.borderColor ?? AppColors.greyColor,
        ),
      );
    }

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(
        color: color ?? widget.borderColor ?? AppColors.greyColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CountryWithPhoneCode>(
      valueListenable: selected,
      builder: (_, c, kk) {
        // Compute max length from example number (strips trunk prefix like 0)
        final int calculatedMaxLen = () {
          String example = c.exampleNumberMobileNational.replaceAll(
            RegExp(r'\D'),
            '',
          );
          if (example.startsWith('0')) example = example.substring(1);
          return example.length;
        }();

        final int effectiveMaxLen = widget.maxLength ?? calculatedMaxLen;

        return Container(
          width: widget.isCollapsed
              ? null
              : widget.width ?? MediaQuery.of(context).size.width,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: widget.bgColor,
            border: widget.border,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: widget.showShadow == true
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: widget.horizontalPadding,
            vertical: widget.verticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              /// HEADING
              if (widget.headingText != null) ...[
                Row(
                  children: [
                    AppText(
                      type: AppTextType.bodySmall,
                      widget.headingText!,
                      color: AppColors.headingTextFieldColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    const SizedBox(width: 4),
                    if (widget.subHeadWidget != null) ...[
                      widget.subHeadWidget!,
                    ],
                    if (widget.subHeadingText != null) ...[
                      const SizedBox(width: 8),
                      AppText(
                        widget.subHeadingText!,
                        type: AppTextType.bodySmall,
                        color: AppColors.greyColor,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 1.h),
              ],

              /// TEXT FIELD WITH CUSTOM COUNTRY PREFIX
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextFormField(
                  key: ValueKey('${widget.keyValue}_${c.countryCode}'),
                  controller: widget.controller,
                  enabled: widget.enabled,
                  readOnly: widget.readOnly,
                  textAlign: widget.textAlign,
                  keyboardType: widget.keyboardType,
                  textInputAction:
                      widget.textInputAction ?? TextInputAction.done,
                  obscureText: widget.obscureText,
                  maxLines: widget.maxLines ?? 1,
                  autofocus: widget.autofocus ?? false,
                  focusNode: _effectiveFocusNode,
                  textCapitalization: widget.textCapitalization,
                  enableInteractiveSelection: widget.enableInteractiveSelection,
                  cursorHeight: widget.cursorHeight,
                  onTapOutside:
                      widget.onTapOutside ??
                      (event) => _effectiveFocusNode.unfocus(),
                  onEditingComplete:
                      widget.onEditingComplete ??
                      () {
                        _effectiveFocusNode.unfocus();
                        widget.onFieldSubmitted?.call(widget.controller.text);
                      },
                  onFieldSubmitted: widget.onFieldSubmitted,
                  onChanged: widget.onChanged,
                  onSaved: widget.onSaved,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: widget.textColor ?? AppColors.blackColor,
                    fontSize: widget.fontSize,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(effectiveMaxLen),
                  ],
                  validator:
                      widget.validator ??
                      (v) {
                        if (v == null || v.isEmpty) {
                          return context.l10n.validationPhoneRequired;
                        }
                        if (v.length < effectiveMaxLen) {
                          return context.l10n.validationPhoneLength;
                        }
                        return null;
                      },
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: context.textTheme.bodySmall?.copyWith(
                      color: widget.hintColor ?? AppColors.greyColor,
                      fontSize: widget.hintTextFontSize,
                    ),
                    filled: widget.filled,
                    fillColor:
                        widget.fillColor?.withValues(alpha: 0.4) ??
                        AppColors.fillColor,
                    suffixIcon: widget.suffix,
                    suffixText: widget.suffixText,
                    prefixText: widget.prefixText,
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.contentPaddingHorizontal ?? 18.px,
                      vertical: widget.contentPaddingVertical ?? 15.px,
                    ),
                    border: _buildBorder(context),
                    enabledBorder: _buildBorder(context),
                    disabledBorder: _buildBorder(
                      context,
                      color:
                          widget.borderColor ??
                          AppColors.greyColor.withValues(alpha: 0.15),
                    ),
                    focusedBorder: _buildBorder(
                      context,
                      color: widget.focusedBorderColor ?? AppColors.secondary,
                    ),
                    errorBorder: _buildBorder(context, color: Colors.red),
                    focusedErrorBorder: _buildBorder(
                      context,
                      color: Colors.red,
                    ),

                    /// COUNTRY SELECTOR PREFIX
                    prefixIcon: InkWell(
                      onTap: widget.readOnly
                          ? null
                          : () async {
                              final res = await _showCountryPicker(context);
                              if (res != null) {
                                selected.value = res;
                                widget.onCountryChanged?.call(res);

                                // Calculate max length for truncation
                                String example = res.exampleNumberMobileNational
                                    .replaceAll(RegExp(r'\D'), '');
                                if (example.startsWith('0')) {
                                  example = example.substring(1);
                                }
                                final currentMaxLen =
                                    widget.maxLength ?? example.length;

                                if (widget.controller.text.length >
                                    currentMaxLen) {
                                  widget.controller.text = widget
                                      .controller
                                      .text
                                      .substring(0, currentMaxLen);
                                }
                                setState(() {});
                              }
                            },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 8),
                          AppText(
                            PhoneNumberServices.countryFlagEmoji(c.countryCode),
                            fontSize: widget.fontSize,
                          ),
                          const SizedBox(width: 2),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(2, 0, 3, 3),
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: AppText(
                                '+${c.phoneCode}',
                                fontSize: widget.fontSize ?? 12,
                                color: widget.textColor ?? AppColors.blackColor,
                              ),
                            ),
                          ),
                          if (!widget.readOnly && widget.showDialog) ...[
                            const Icon(Icons.keyboard_arrow_down, size: 18),
                            const SizedBox(width: 6),
                          ] else ...[
                            const SizedBox(width: 12),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<CountryWithPhoneCode?> _showCountryPicker(BuildContext context) {
    if (widget.showDialog) {
      return showDialog<CountryWithPhoneCode>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(16),
          child: const SizedBox(
            width: 350,
            height: 500,
            child: _CountryPicker(),
          ),
        ),
      );
    }

    return showModalBottomSheet<CountryWithPhoneCode>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxHeight: 700),
      builder: (_) => const _CountryPicker(),
    );
  }
}

// ---------------- PICKER ----------------

class _CountryPicker extends StatefulWidget {
  const _CountryPicker();

  @override
  State<_CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<_CountryPicker> {
  final search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: AppText(
              type: AppTextType.bodyMedium,
              'Select Country',
              color: AppColors.blackColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TextField(
              controller: search,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: AppColors.greyColor),
                hintText: context.l10n.search,
                hintStyle: TextStyle(color: AppColors.greyColor),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<Map<String, CountryWithPhoneCode>>(
              valueListenable: PhoneNumberServices.all,
              builder: (_, hh, pp) {
                final list = PhoneNumberServices.filter(search.text, context);
                final countryLocalizations = cp.CountryLocalizations.of(
                  context,
                );

                // Sort the list alphabetically by localized country name
                list.sort((a, b) {
                  final nameA =
                      countryLocalizations?.countryName(
                        countryCode: a.countryCode,
                      ) ??
                      a.countryName ??
                      '';
                  final nameB =
                      countryLocalizations?.countryName(
                        countryCode: b.countryCode,
                      ) ??
                      b.countryName ??
                      '';
                  return nameA.compareTo(nameB);
                });

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final c = list[i];
                    final countryName =
                        countryLocalizations?.countryName(
                          countryCode: c.countryCode,
                        ) ??
                        c.countryName ??
                        '';
                    return ListTile(
                      leading: AppText(
                        PhoneNumberServices.countryFlagEmoji(c.countryCode),
                      ),
                      title: AppText(
                        countryName,
                        type: AppTextType.bodyMedium,
                        color: AppColors.blackColor,
                      ),
                      trailing: Text('+${c.phoneCode}'),
                      onTap: () => Navigator.pop(context, c),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
