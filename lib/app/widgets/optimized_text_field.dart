import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nhac_lich_viet/app/theme/app_colors.dart';

class OptimizedTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final BoxConstraints? prefixIconConstraints;
  final BoxConstraints? suffixIconConstraints;
  final InputDecoration? decoration;
  final EdgeInsetsGeometry? contentPadding;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  final TextAlignVertical? textAlignVertical;
  final TextAlign textAlign;
  final bool expands;
  final bool? showCursor;
  final Color? cursorColor;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final double cursorWidth;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool? enableInteractiveSelection;
  final TextSelectionControls? selectionControls;
  final ScrollPhysics? scrollPhysics;
  final Iterable<String>? autofillHints;
  final bool filled;
  final Color? fillColor;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final InputBorder? disabledBorder;
  final InputBorder? focusedErrorBorder;

  const OptimizedTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.style,
    this.hintStyle,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
    this.decoration,
    this.contentPadding,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.inputFormatters,
    this.validator,
    this.autovalidateMode,
    this.textAlignVertical,
    this.textAlign = TextAlign.start,
    this.expands = false,
    this.showCursor,
    this.cursorColor,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorWidth = 2.0,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.enableInteractiveSelection,
    this.selectionControls,
    this.scrollPhysics,
    this.autofillHints,
    this.filled = false,
    this.fillColor,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.disabledBorder,
    this.focusedErrorBorder,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: style ??
          TextStyle(
            fontSize: 18.sp,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autofocus: autofocus,
      obscureText: obscureText,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      enabled: enabled,
      readOnly: readOnly,
      onChanged: onChanged,
      onTap: onTap,
      onSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
      textAlignVertical: textAlignVertical,
      textAlign: textAlign,
      expands: expands,
      showCursor: showCursor,
      cursorColor: cursorColor ?? AppColors.primary,
      cursorHeight: cursorHeight,
      cursorRadius: cursorRadius,
      cursorWidth: cursorWidth,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      // IMPORTANT: Enable interactive selection for copy/paste/select all
      enableInteractiveSelection: enableInteractiveSelection ?? true,
      // Use Material selection controls for consistent behavior
      selectionControls: selectionControls ?? MaterialTextSelectionControls(),
      scrollPhysics: scrollPhysics,
      autofillHints: autofillHints,
      decoration: decoration ??
          InputDecoration(
            hintText: hintText,
            labelText: labelText,
            hintStyle: hintStyle ??
                TextStyle(
                  color: Colors.grey[500],
                  fontSize: 18.sp,
                ),
            filled: filled,
            fillColor: fillColor,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            prefixIconConstraints: prefixIconConstraints,
            suffixIconConstraints: suffixIconConstraints,
            contentPadding: contentPadding,
            border: border,
            enabledBorder: enabledBorder,
            focusedBorder: focusedBorder,
            errorBorder: errorBorder,
            disabledBorder: disabledBorder,
            focusedErrorBorder: focusedErrorBorder,
            // Ensure consistent selection color
            focusColor: AppColors.primary,
          ),
    );
  }
}

// Enhanced TextField specifically for search with Vietnamese support
class OptimizedSearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool showClearButton;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final Color? cursorColor;

  const OptimizedSearchTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.onSubmitted,
    this.onClear,
    this.showClearButton = true,
    this.textStyle,
    this.hintStyle,
    this.cursorColor,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedTextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      // IMPORTANT: Use sentences for better Vietnamese input
      textCapitalization: TextCapitalization.sentences,
      textAlignVertical: TextAlignVertical.center,
      // Enable all text input features
      autocorrect: false, // Disable autocorrect for search
      enableSuggestions: true,
      enableInteractiveSelection: true,
      // Optimize keyboard for search
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      style: textStyle ??
          TextStyle(
            fontSize: 18.sp,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
      cursorColor: cursorColor,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: hintStyle ??
            TextStyle(
              color: Colors.grey[500],
              fontSize: 18.sp,
            ),
        filled: false,
        isDense: true,
        prefixIconConstraints: BoxConstraints(minWidth: 26.w),
        suffixIconConstraints: BoxConstraints(minWidth: 26.w),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: 3.w, right: 6.w),
          child: Icon(
            Icons.search,
            size: 22.sp,
            color: const Color(0xFF616161),
          ),
        ),
        suffixIcon: SizedBox(
          width: 45.w,
          height: 40.h,
          child: showClearButton && controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.grey[600],
                    size: 20.sp,
                  ),
                  onPressed: onClear,
                  tooltip: 'Xóa',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              : const SizedBox.shrink(),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );
  }
}
