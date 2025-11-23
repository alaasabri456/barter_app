import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int maxLines;
  final TextInputAction textInputAction;
  final void Function()? onEditingComplete;
  final bool autofocus;

  const AuthTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.textInputAction = TextInputAction.next,
    this.onEditingComplete,
    this.autofocus = false,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = true;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _obscureText = widget.isPassword;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: widget.maxLines > 1
              ? TextInputType.multiline
              : widget.keyboardType,
          obscureText: widget.isPassword ? _obscureText : false,
          validator: widget.validator,
          onChanged: widget.onChanged,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          textInputAction: widget.textInputAction,
          onEditingComplete: widget.onEditingComplete,
          autofocus: widget.autofocus,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 16.sp,
          ),
          decoration: InputDecoration(
            hintText: widget.hint ?? widget.label,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.isPassword
                ? IconButton(
              onPressed: _togglePasswordVisibility,
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
              ),
            )
                : widget.suffixIcon,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
        ),
      ],
    );
  }
}

class AuthTextFieldWithIcon extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final IconData icon;
  final bool enabled;
  final Future<void> Function()? onEditingComplete;

  const AuthTextFieldWithIcon({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.validator,
    this.onChanged,
    required this.icon,
    this.enabled = true, required TextInputAction textInputAction, this.onEditingComplete ,
  });

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      label: label,
      hint: hint,
      controller: controller,
      keyboardType: keyboardType,
      isPassword: isPassword,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      prefixIcon: Icon(
        icon,
        color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
        size: 20.w,
      ),
    );
  }
}

class SearchTextField extends StatefulWidget {
  final String hint;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final void Function()? onClear;
  final Widget? prefixIcon;
  final bool enabled;
  final bool autofocus;

  const SearchTextField({
    super.key,
    this.hint = 'Search...',
    this.controller,
    this.onChanged,
    this.onClear,
    this.prefixIcon,
    this.enabled = true,
    this.autofocus = false,
  });

  @override
  State<SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    widget.onChanged?.call(_controller.text);
  }

  void _clearText() {
    _controller.clear();
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(25.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: widget.prefixIcon ??
              Icon(
                Icons.search,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
              ),
          suffixIcon: _hasText
              ? IconButton(
            onPressed: _clearText,
            icon: Icon(
              Icons.clear,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
            ),
          )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 16.h,
          ),
        ),
      ),
    );
  }
}