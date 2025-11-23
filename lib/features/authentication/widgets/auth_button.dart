import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final Widget? icon;
  final bool isOutlined;

  const AuthButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 50.0,
    this.icon,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = !enabled || isLoading;

    if (isOutlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height.h,
        child: OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor ?? Theme.of(context).primaryColor,
            side: BorderSide(
              color: backgroundColor ?? Theme.of(context).primaryColor,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: isLoading
              ? _buildLoadingIndicator(context)
              : _buildButtonContent(context),
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height.h,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: textColor ?? Colors.white,
          disabledBackgroundColor: Theme.of(context).disabledColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: isDisabled ? 0 : 2,
        ),
        child: isLoading
            ? _buildLoadingIndicator(context)
            : _buildButtonContent(context),
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return SizedBox(
      height: 20.h,
      width: 20.w,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          isOutlined
              ? Theme.of(context).primaryColor
              : Colors.white,
        ),
      ),
    );
  }

  Widget _buildButtonContent(BuildContext context) {
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          SizedBox(width: 8.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class SocialAuthButton extends StatelessWidget {
  final String text;
  final String iconAsset;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  const SocialAuthButton({
    super.key,
    required this.text,
    required this.iconAsset,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).cardColor,
          foregroundColor: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
          side: BorderSide(
            color: borderColor ?? Theme.of(context).dividerColor,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
          height: 20.h,
          width: 20.w,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconAsset,
              width: 20.w,
              height: 20.h,
            ),
            SizedBox(width: 12.w),
            Text(
              text,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LinkButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final bool underlined;
  final double? fontSize;

  const LinkButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.underlined = true,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: color ?? Theme.of(context).primaryColor,
          fontSize: fontSize ?? 14.sp,
          fontWeight: FontWeight.w500,
          decoration: underlined ? TextDecoration.underline : null,
        ),
      ),
    );
  }
}

class IconTextButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final double? width;
  final double height;
  final bool isOutlined;

  const IconTextButton({
    super.key,
    required this.text,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.width,
    this.height = 45.0,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return AuthButton(
      text: text,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      textColor: textColor,
      width: width,
      height: height,
      isOutlined: isOutlined,
      icon: Icon(
        icon,
        size: 18.w,
        color: iconColor ?? (isOutlined
            ? textColor ?? Theme.of(context).primaryColor
            : textColor ?? Colors.white),
      ),
    );
  }
}

class FloatingAuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const FloatingAuthButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: AuthButton(
        text: text,
        onPressed: onPressed,
        isLoading: isLoading,
        icon: icon != null ? Icon(icon!, size: 18.w) : null,
      ),
    );
  }
}