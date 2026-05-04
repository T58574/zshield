import 'package:flutter/material.dart';

class StatusGlow extends StatefulWidget {
  final Widget child;
  final Color color;
  final bool animate;
  final double blurRadius;
  final double spreadRadius;

  const StatusGlow({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.animate = true,
    this.blurRadius = 40.0,
    this.spreadRadius = 10.0,
  });

  @override
  State<StatusGlow> createState() => _StatusGlowState();
}

class _StatusGlowState extends State<StatusGlow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StatusGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.3 * (widget.animate ? _animation.value : 1.0)),
                blurRadius: widget.blurRadius * (widget.animate ? _animation.value : 1.0),
                spreadRadius: widget.spreadRadius * (widget.animate ? _animation.value : 1.0),
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}
