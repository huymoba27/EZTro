import 'package:flutter/material.dart';

class JumpingDots extends StatefulWidget {
  final Color color;
  final double radius;
  final double spacing;

  const JumpingDots({
    super.key,
    this.color = Colors.grey,
    this.radius = 3.0,
    this.spacing = 3.0,
  });

  @override
  State<JumpingDots> createState() => _JumpingDotsState();
}

class _JumpingDotsState extends State<JumpingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double delay = index * 0.2;
            final double value =
                (1.0 + (index * 0.2) + _controller.value) % 1.0;
            final double verticalOffset =
                (value < 0.5) ? -6.0 * (value / 0.5) : -6.0 * (1.0 - (value / 0.5));
            
            // Một cách tính toán mượt mà hơn cho hiệu ứng nhảy
            double bounce = 0.0;
            double t = (_controller.value + delay) % 1.0;
            if (t < 0.5) {
              bounce = -8.0 * (4 * t * (0.5 - t)); // Parabolic jump
            }

            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.spacing),
              transform: Matrix4.translationValues(0, bounce, 0),
              child: Container(
                width: widget.radius * 2,
                height: widget.radius * 2,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(t < 0.5 ? 1.0 : 0.4),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
