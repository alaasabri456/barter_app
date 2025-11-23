import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final Color? color;
  final double? size;

  const LoadingWidget({
    super.key,
    this.message,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size ?? 40.w,
            height: size ?? 40.w,
            child: CircularProgressIndicator(
              color: color ?? Theme.of(context).primaryColor,
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: 16.h),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;
  final Color? overlayColor;
  final Color? indicatorColor;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingMessage,
    this.overlayColor,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: overlayColor ?? Colors.black.withOpacity(0.3),
            child: LoadingWidget(
              message: loadingMessage,
              color: indicatorColor,
            ),
          ),
      ],
    );
  }
}

class CustomLinearProgressIndicator extends StatelessWidget {
  final double? value;
  final Color? backgroundColor;
  final Color? valueColor;
  final double height;
  final String? label;

  const CustomLinearProgressIndicator({
    super.key,
    this.value,
    this.backgroundColor,
    this.valueColor,
    this.height = 4.0,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: 8.h),
        ],
        Container(
          height: height.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            color: backgroundColor ?? Theme.of(context).dividerColor,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                valueColor ?? Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PulsatingDot extends StatefulWidget {
  final Color? color;
  final double size;
  final Duration duration;

  const PulsatingDot({
    super.key,
    this.color,
    this.size = 8.0,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  State<PulsatingDot> createState() => _PulsatingDotState();
}

class _PulsatingDotState extends State<PulsatingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.size.w,
            height: widget.size.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color ?? Theme.of(context).primaryColor,
            ),
          ),
        );
      },
    );
  }
}

class ThreeDotLoading extends StatefulWidget {
  final Color? color;
  final double dotSize;
  final Duration duration;

  const ThreeDotLoading({
    super.key,
    this.color,
    this.dotSize = 8.0,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<ThreeDotLoading> createState() => _ThreeDotLoadingState();
}

class _ThreeDotLoadingState extends State<ThreeDotLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final double animationValue = (_animationController.value + (index * 0.2)) % 1.0;
        final double scale = animationValue < 0.5
            ? Tween<double>(begin: 0.5, end: 1.0).transform(animationValue * 2)
            : Tween<double>(begin: 1.0, end: 0.5).transform((animationValue - 0.5) * 2);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.dotSize.w,
            height: widget.dotSize.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color ?? Theme.of(context).primaryColor,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(0),
        SizedBox(width: 4.w),
        _buildDot(1),
        SizedBox(width: 4.w),
        _buildDot(2),
      ],
    );
  }
}

class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    if (widget.isLoading) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              colors: [
                widget.baseColor ?? Colors.grey.shade300,
                widget.highlightColor ?? Colors.grey.shade100,
                widget.baseColor ?? Colors.grey.shade300,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + 2.0 * _animationController.value, 0.0),
              end: Alignment(1.0 + 2.0 * _animationController.value, 0.0),
            ).createShader(rect);
          },
          child: widget.child,
        );
      },
    );
  }
}