import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedGpsIcon extends StatefulWidget {
  final bool isActive;
  final double size;

  const AnimatedGpsIcon({
    Key? key,
    required this.isActive,
    this.size = 32,
  }) : super(key: key);

  @override
  State<AnimatedGpsIcon> createState() => _AnimatedGpsIconState();
}

class _AnimatedGpsIconState extends State<AnimatedGpsIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Icon(
        Icons.location_on,
        size: widget.size,
        color: const Color(0xFFFF4081),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulso externo
            Transform.scale(
              scale: 1.0 + (_controller.value * 0.3),
              child: Opacity(
                opacity: 1.0 - _controller.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00E5FF).withOpacity(0.3),
                  ),
                ),
              ),
            ),
            // Ícone
            Icon(
              Icons.location_on,
              size: widget.size,
              color: const Color(0xFF00E5FF),
            ),
          ],
        );
      },
    );
  }
}




