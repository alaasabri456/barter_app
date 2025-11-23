import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmColor;
  final Color? cancelColor;
  final Widget? icon;
  final bool barrierDismissible;

  const CustomDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.confirmColor,
    this.cancelColor,
    this.icon,
    this.barrierDismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            icon!,
            SizedBox(width: 12.w),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        content,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actions: [
        if (cancelText != null)
          TextButton(
            onPressed: onCancel ?? () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: cancelColor ?? Theme.of(context).textTheme.bodyMedium?.color,
            ),
            child: Text(cancelText!),
          ),
        if (confirmText != null)
          ElevatedButton(
            onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? Theme.of(context).primaryColor,
            ),
            child: Text(confirmText!),
          ),
      ],
    );
  }
}

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmColor;
  final IconData? icon;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.confirmColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: title,
      content: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
      confirmColor: confirmColor ?? Theme.of(context).colorScheme.error,
      icon: icon != null ? Icon(icon!, color: confirmColor) : null,
    );
  }
}

class InfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? iconColor;

  const InfoDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'OK',
    this.onPressed,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: title,
      content: message,
      confirmText: buttonText,
      onConfirm: onPressed,
      icon: icon != null
          ? Icon(icon!, color: iconColor ?? Theme.of(context).primaryColor)
          : null,
    );
  }
}

class LoadingDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool barrierDismissible;

  const LoadingDialog({
    super.key,
    this.title = 'Loading',
    this.message = 'Please wait...',
    this.barrierDismissible = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
          SizedBox(height: 24.h),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class CustomBottomSheet extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;
  final bool isScrollable;
  final double? height;

  const CustomBottomSheet({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.isScrollable = true,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          if (title != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Divider(height: 1.h),
          ],

          Expanded(
            child: isScrollable
                ? SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: content,
            )
                : Padding(
              padding: EdgeInsets.all(20.w),
              child: content,
            ),
          ),

          if (actions != null) ...[
            Divider(height: 1.h),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: actions!
                    .expand((widget) => [widget, SizedBox(width: 12.w)])
                    .toList()
                  ..removeLast(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Helper functions
Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  Color? confirmColor,
  IconData? icon,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ConfirmationDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      confirmColor: confirmColor,
      icon: icon,
    ),
  );
}

Future<void> showInfoDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = 'OK',
  IconData? icon,
  Color? iconColor,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => InfoDialog(
      title: title,
      message: message,
      buttonText: buttonText,
      icon: icon,
      iconColor: iconColor,
    ),
  );
}

Future<void> showLoadingDialog({
  required BuildContext context,
  String title = 'Loading',
  String message = 'Please wait...',
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => LoadingDialog(
      title: title,
      message: message,
    ),
  );
}

Future<T?> showCustomBottomSheet<T>({
  required BuildContext context,
  String? title,
  required Widget content,
  List<Widget>? actions,
  bool isScrollable = true,
  double? height,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CustomBottomSheet(
      title: title,
      content: content,
      actions: actions,
      isScrollable: isScrollable,
      height: height,
    ),
  );
}