import 'package:flutter/material.dart';

class MobileFrame extends StatelessWidget {
  final Widget child;

  const MobileFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final frameWidth = constraints.maxWidth < 430
            ? constraints.maxWidth
            : 430.0;

        return ColoredBox(
          color: const Color(0xFF2C322B),
          child: Center(
            child: Container(
              width: frameWidth,
              height: constraints.maxHeight,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F3EA),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
