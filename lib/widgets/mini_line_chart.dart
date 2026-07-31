import 'package:flutter/material.dart';
import 'dart:math';

import '../theme/app_theme.dart';

// ============================================================
//  GRÁFICO DE LINHA (desenhado à mão, sem biblioteca externa)
// ============================================================

class MiniLineChart extends StatelessWidget {
  final List<double> values;
  final double height;
  final bool showDots;

  const MiniLineChart({
    super.key,
    required this.values,
    this.height = 80,
    this.showDots = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Pegamos a cor principal do tema aqui, onde temos acesso ao 'context'
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: height,
      width: double.infinity,
      // 2. Passamos a cor capturada para dentro do pintor
      child: CustomPaint(
        painter: _LineChartPainter(values, showDots, primaryColor, isDark),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final bool showDots;
  final Color primaryColor; // 3. O pintor recebe e guarda a cor aqui
  final bool isDark;

  _LineChartPainter(this.values, this.showDots, this.primaryColor, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final double maxV = values.reduce(max);
    final double minV = values.reduce(min);
    final double range = (maxV - minV) == 0 ? 1 : (maxV - minV);
    final double dx = size.width / (values.length - 1);
    const double topPad = 10;
    final double usableHeight = size.height - topPad - 6;

    final List<Offset> points = [];
    for (int i = 0; i < values.length; i++) {
      final double x = dx * i;
      final double norm = (values[i] - minV) / range;
      final double y = topPad + (1 - norm) * usableHeight;
      points.add(Offset(x, y));
    }

    final Path linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final Offset prev = points[i - 1];
      final Offset curr = points[i];
      final double midX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }

    final Path fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          // 4. Usando a cor recebida com o formato moderno de transparência
          primaryColor.withValues(alpha: isDark ? 0.28 : 0.16),
          primaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final Paint linePaint = Paint()
      ..color =
          primaryColor // 5. Usando a cor no contorno da linha
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    if (showDots) {
      final Paint dotFill = Paint()
        ..color = primaryColor; // 6. Usando a cor nas bolinhas
      final Paint dotBorder = Paint()
        ..color = AppColors.background
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (final Offset p in points) {
        canvas.drawCircle(p, 3.5, dotFill);
        canvas.drawCircle(p, 3.5, dotBorder);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.isDark != isDark;
}
