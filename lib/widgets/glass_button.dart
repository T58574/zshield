import 'package:flutter/material.dart';
import 'dart:ui';

class GlassButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool isPrimary;
  final double width;
  final double height;
  final BorderRadiusGeometry? borderRadius;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isPrimary = false,
    this.width = double.infinity,
    this.height = 56.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(12.0);

    if (isPrimary) {
      return SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: effectiveRadius,
            ),
            elevation: 8,
            shadowColor: Colors.white.withOpacity(0.3),
          ),
          child: child,
        ),
      );
    }

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: SizedBox(
          width: width,
          height: height,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: effectiveRadius,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
