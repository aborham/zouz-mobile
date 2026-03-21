import 'package:flutter/material.dart';

class ZouzLogo extends StatelessWidget {
  final double size;
  final Color color;

  const ZouzLogo({super.key, this.size = 100, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LogoPainter(color: color),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color color;

  _LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.15
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw two parallel diagonal lines //
    // Line 1
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.6, size.height * 0.2),
      paint,
    );

    // Line 2
    canvas.drawLine(
      Offset(size.width * 0.45, size.height * 0.8),
      Offset(size.width * 0.85, size.height * 0.2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
