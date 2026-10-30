import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:guardup/core/app_types/app_text_type.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';

import '../app_text/app_text.dart';

enum AppTextFieldBorderType { outline, underline }

class AppTextField extends StatefulWidget {
  /// REQUIRED
  final TextEditingController controller;
  final String hintText;

  /// OPTIONAL
  final String? headingText;
  final Widget? subHeadingText;
  final Widget? prefix;
  final Widget? suffix;

  /// PASSWORD FIELD
  final bool isPasswordField;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool readOnly;
  final bool showCursor;
  final bool autocorrect;
  final bool enableSuggestions;
  final Brightness? keyboardAppearance;
  final EdgeInsets? scrollPadding;
  final bool enableInteractiveSelection;
  final TextCapitalization textCapitalization;
  final StrutStyle? strutStyle;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final TextDirection? textDirection;
  final bool toolbarOptions;
  final UndoHistoryController? undoController;
  final int? maxLength;
  final ContentInsertionConfiguration? contentInsertionConfiguration;

  /// CALLBACKS
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final TapRegionCallback? onTapOutside;
  final ValueChanged<bool>? onFocusChange;

  /// VALIDATION
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;

  /// FORMATTING
  final List<TextInputFormatter>? inputFormatters;

  /// CUSTOMIZATION
  final Color? borderColor;
  final Color? fillColor;
  final Color? hintColor;
  final Color? textColor;
  final Color? focusedBorderColor;
  final Color? focusedErrorBorderColor;
  final Color? disabledBorderColor;
  final Color? errorBorderColor;
  final Color? cursorColor;
  final Color? selectionColor;
  final Color? selectionHandleColor;
  final double? cursorWidth;
  final double? hintFontSize;
  final Radius? cursorRadius;
  final double? borderRadius;
  final double? contentPaddingHorizontal;
  final double? contentPaddingVertical;
  final EdgeInsetsGeometry? contentPadding;
  final bool expands;
  final bool? isCollapsed;
  final bool? isDense;
  final InputCounterWidgetBuilder? buildCounter;
  final AppTextFieldBorderType borderType;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.headingText,
    this.subHeadingText,
    this.prefix,
    this.suffix,
    this.isPasswordField = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.focusNode,
    this.autofocus = false,
    this.readOnly = false,
    this.showCursor = true,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.keyboardAppearance,
    this.scrollPadding,
    this.enableInteractiveSelection = true,
    this.textCapitalization = TextCapitalization.none,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.textDirection,
    this.toolbarOptions = false,
    this.undoController,
    this.onChanged,
    this.onTap,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.onTapOutside,
    this.onFocusChange,
    this.validator,
    this.autovalidateMode,
    this.inputFormatters,
    this.borderColor,
    this.fillColor,
    this.focusedBorderColor,
    this.focusedErrorBorderColor,
    this.disabledBorderColor,
    this.errorBorderColor,
    this.cursorColor,
    this.hintColor,
    this.textColor,
    this.selectionColor,
    this.selectionHandleColor,
    this.hintFontSize,
    this.cursorWidth,
    this.cursorRadius,
    this.borderRadius,
    this.contentPaddingHorizontal,
    this.contentPaddingVertical,
    this.contentPadding,
    this.expands = false,
    this.isCollapsed,
    this.isDense,
    this.buildCounter,
    this.maxLength,
    this.contentInsertionConfiguration,
    this.borderType = AppTextFieldBorderType.outline,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  static const double _defaultRadius = 10;
  static const double _defaultHorizontalPadding = 18;
  static const double _defaultVerticalPadding = 15;

  late final ValueNotifier<bool> _obscureNotifier;
  late final ValueNotifier<TextDirection?> _directionNotifier;

  @override
  void initState() {
    super.initState();

    _obscureNotifier = ValueNotifier(widget.isPasswordField);

    TextDirection? initialDirection;
    final text = widget.controller.text;
    if (text.trim().isNotEmpty) {
      if (intl.Bidi.startsWithRtl(text)) {
        initialDirection = TextDirection.rtl;
      } else if (intl.Bidi.startsWithLtr(text)) {
        initialDirection = TextDirection.ltr;
      }
    }

    _directionNotifier = ValueNotifier(
      widget.textDirection ?? initialDirection,
    );
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (widget.textDirection != null) return;
    final text = widget.controller.text;

    TextDirection? newDirection = _directionNotifier.value;

    if (text.trim().isEmpty) {
      newDirection = null;
    } else if (intl.Bidi.startsWithRtl(text)) {
      newDirection = TextDirection.rtl;
    } else if (intl.Bidi.startsWithLtr(text)) {
      newDirection = TextDirection.ltr;
    }

    if (_directionNotifier.value != newDirection) {
      _directionNotifier.value = newDirection;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _directionNotifier.dispose();
    _obscureNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              if (widget.subHeadingText != null) ...[widget.subHeadingText!],
            ],
          ),
          const SizedBox(height: 8),
        ],

        ValueListenableBuilder<bool>(
          valueListenable: _obscureNotifier,
          builder: (context, obscureText, child) {
            return ValueListenableBuilder<TextDirection?>(
              valueListenable: _directionNotifier,
              builder: (context, textDirection, child) {
                return TextFormField(
                  controller: widget.controller,
                  validator: widget.validator,
                  autovalidateMode: widget.autovalidateMode,
                  onChanged: widget.onChanged,
                  onTap: widget.onTap,
                  maxLength: widget.maxLength,
                  onEditingComplete: widget.onEditingComplete,
                  onFieldSubmitted: widget.onFieldSubmitted,
                  onTapOutside:
                      widget.onTapOutside ??
                      (event) => FocusManager.instance.primaryFocus?.unfocus(),
                  inputFormatters: widget.inputFormatters,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  focusNode: widget.focusNode,
                  autofocus: widget.autofocus,
                  readOnly: widget.readOnly,
                  showCursor: widget.showCursor,
                  obscureText: widget.isPasswordField
                      ? obscureText
                      : widget.obscureText,
                  maxLines: widget.isPasswordField ? 1 : widget.maxLines,
                  minLines: widget.minLines,
                  expands: widget.expands,
                  enabled: widget.enabled,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: widget.textColor ?? AppColors.blackColor,
                  ),
                  cursorColor: widget.cursorColor ?? AppColors.primary,
                  cursorWidth: widget.cursorWidth ?? 2.0,
                  cursorRadius: widget.cursorRadius,
                  autocorrect: widget.autocorrect,
                  enableSuggestions: widget.enableSuggestions,
                  keyboardAppearance: widget.keyboardAppearance,
                  scrollPadding:
                      widget.scrollPadding ?? const EdgeInsets.all(20.0),
                  enableInteractiveSelection: widget.enableInteractiveSelection,
                  textCapitalization: widget.textCapitalization,
                  strutStyle: widget.strutStyle,
                  textAlign: widget.textAlign,
                  textAlignVertical: widget.textAlignVertical,
                  textDirection: textDirection,
                  undoController: widget.undoController,
                  contentInsertionConfiguration:
                      widget.contentInsertionConfiguration,

                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: context.textTheme.bodySmall?.copyWith(
                      fontSize: widget.hintFontSize,
                      color: widget.hintColor ?? AppColors.hintTextFieldColor,
                      fontWeight: FontWeight.w400,
                    ),
                    filled: true,
                    fillColor:
                        widget.fillColor?.withValues(alpha: 0.4) ??
                        AppColors.fillColor,

                    prefixIcon: widget.prefix,

                    suffixIcon: widget.isPasswordField
                        ? IconButton(
                            onPressed: () {
                              _obscureNotifier.value = !_obscureNotifier.value;
                            },
                            icon: Icon(
                              color: AppColors.secondary,
                              size: 19,
                              obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          )
                        : widget.suffix,

                    contentPadding:
                        widget.contentPadding ??
                        EdgeInsets.symmetric(
                          horizontal:
                              widget.contentPaddingHorizontal ??
                              _defaultHorizontalPadding,
                          vertical:
                              widget.contentPaddingVertical ??
                              _defaultVerticalPadding,
                        ),

                    isCollapsed: widget.isCollapsed,
                    isDense: widget.isDense,
                    enabled: widget.enabled,

                    border: _buildBorder(),
                    enabledBorder: _buildBorder(
                      color: widget.enabled
                          ? (widget.borderColor ?? Colors.grey.shade300)
                          : (widget.disabledBorderColor ??
                                Colors.grey.shade300),
                    ),
                    focusedBorder: _buildBorder(
                      color: widget.focusedBorderColor ?? AppColors.secondary,
                    ),
                    errorBorder: _buildBorder(
                      color: widget.errorBorderColor ?? Colors.red,
                    ),
                    focusedErrorBorder: _buildBorder(
                      color: widget.focusedErrorBorderColor ?? Colors.red,
                    ),
                    disabledBorder: widget.enabled
                        ? null
                        : _buildBorder(
                            color:
                                widget.disabledBorderColor ??
                                Colors.grey.shade300,
                          ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  InputBorder _buildBorder({Color? color}) {
    final borderSide = BorderSide(
      color: color ?? widget.borderColor ?? Colors.grey.shade300,
    );

    if (widget.borderType == AppTextFieldBorderType.underline) {
      return UnderlineInputBorder(borderSide: borderSide);
    }

    return OutlineInputBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(widget.borderRadius ?? _defaultRadius),
      ),
      borderSide: borderSide,
    );
  }
}
