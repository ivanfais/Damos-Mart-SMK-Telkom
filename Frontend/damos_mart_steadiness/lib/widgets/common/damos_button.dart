import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

enum DamosButtonVariant { primary, outline, text }

class DamosButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final DamosButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  /// When true (default) the button stretches to fill the available width.
  /// Set to false when placing the button inside a [Row] or any widget that
  /// provides unbounded width, otherwise layout throws an "infinite width" error.
  final bool expand;

  const DamosButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = DamosButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  @override
  State<DamosButton> createState() => _DamosButtonState();
}

class _DamosButtonState extends State<DamosButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() {
      _scale = AppAnimations.cardScaleValue;
    });
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() {
      _scale = 1.0;
    });
  }

  void _onTapCancel() {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() {
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;

    Widget buttonChild;
    if (widget.isLoading) {
      buttonChild = const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else {
      buttonChild = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: AppDimensions.buttonIconSize),
            const SizedBox(width: 8),
          ],
          // When the button is allowed to expand (width-bounded by its parent),
          // let the label shrink with an ellipsis so it never overflows.
          widget.expand
              ? Flexible(
                  child: Text(
                    widget.text,
                    textAlign: TextAlign.center,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : Text(widget.text),
        ],
      );
    }

    final Size minimumSize = Size(
      widget.expand ? double.infinity : 0,
      AppDimensions.buttonHeight,
    );

    ButtonStyle buttonStyle;
    switch (widget.variant) {
      case DamosButtonVariant.primary:
        buttonStyle = ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.textHint,
          disabledForegroundColor: Colors.white,
          minimumSize: minimumSize,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
          textStyle: AppTextStyles.labelLarge,
          elevation: 1,
        );
        break;
      case DamosButtonVariant.outline:
        buttonStyle = OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textHint,
          side: BorderSide(
            color: isEnabled ? AppColors.primary : AppColors.divider,
            width: 1.5,
          ),
          minimumSize: minimumSize,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
          textStyle: AppTextStyles.labelLarge,
        );
        break;
      case DamosButtonVariant.text:
        buttonStyle = TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textHint,
          minimumSize: minimumSize,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
          textStyle: AppTextStyles.labelLarge,
        );
        break;
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: AppAnimations.buttonPress,
        curve: Curves.easeOut,
        child: widget.variant == DamosButtonVariant.outline
            ? OutlinedButton(
                onPressed: isEnabled ? widget.onPressed : null,
                style: buttonStyle,
                child: buttonChild,
              )
            : widget.variant == DamosButtonVariant.text
                ? TextButton(
                    onPressed: isEnabled ? widget.onPressed : null,
                    style: buttonStyle,
                    child: buttonChild,
                  )
                : ElevatedButton(
                    onPressed: isEnabled ? widget.onPressed : null,
                    style: buttonStyle,
                    child: buttonChild,
                  ),
      ),
    );
  }
}
