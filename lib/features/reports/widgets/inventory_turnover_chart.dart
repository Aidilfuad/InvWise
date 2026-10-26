import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../data/reports_mock_data.dart';
import 'report_card.dart';
import 'trend_pill.dart';

/// The single main chart: monthly inventory turnover with a target line.
///
/// Drawn with a [CustomPainter] (no chart package). The header shows the
/// latest value and its change so the key number reads without the chart.
class InventoryTurnoverChart extends StatelessWidget {
  const InventoryTurnoverChart({super.key, required this.trend});

  final TurnoverTrend trend;

  static const double _chartHeight = 190;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = (textTheme.labelSmall ?? const TextStyle()).copyWith(
      color: AppColors.textSecondary,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventory Turnover Trend',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapXs,
                    Text(
                      'Monthly · ${trend.months.first} – ${trend.months.last}',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapMd,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    trend.currentLabel,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  AppSpacing.gapXs,
                  TrendPill(delta: trend.delta),
                ],
              ),
            ],
          ),
          AppSpacing.gapLg,
          SizedBox(
            height: _chartHeight,
            width: double.infinity,
            child: CustomPaint(
              painter: _TurnoverPainter(
                months: trend.months,
                values: trend.values,
                axisMin: trend.axisMin,
                axisMax: trend.axisMax,
                target: trend.target,
                targetLabel: trend.targetLabel,
                valueLabel: trend.currentLabel,
                lineColor: AppColors.primary,
                gridColor: AppColors.border,
                targetColor: AppColors.warning,
                labelStyle: labelStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TurnoverPainter extends CustomPainter {
  _TurnoverPainter({
    required this.months,
    required this.values,
    required this.axisMin,
    required this.axisMax,
    required this.target,
    required this.targetLabel,
    required this.valueLabel,
    required this.lineColor,
    required this.gridColor,
    required this.targetColor,
    required this.labelStyle,
  });

  final List<String> months;
  final List<double> values;
  final double axisMin;
  final double axisMax;
  final double target;
  final String targetLabel;
  final String valueLabel;
  final Color lineColor;
  final Color gridColor;
  final Color targetColor;
  final TextStyle labelStyle;

  static const double _leftPad = 30; // y-axis labels
  static const double _rightPad = 4;
  static const double _topPad = 30; // room for the value bubble
  static const double _bottomPad = 26; // month labels
  static const double _xInset = 14; // keeps first / last dot off the edge

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || axisMax <= axisMin) return;

    final rect = Rect.fromLTRB(
      _leftPad,
      _topPad,
      size.width - _rightPad,
      size.height - _bottomPad,
    );
    final span = axisMax - axisMin;
    double yFor(double v) => rect.bottom - ((v - axisMin) / span) * rect.height;

    final stepX = (rect.width - 2 * _xInset) / (values.length - 1);
    double xFor(int i) => rect.left + _xInset + i * stepX;

    // Horizontal grid + y-axis labels.
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var v = axisMin; v <= axisMax + 0.001; v += 1) {
      final y = yFor(v);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
      _drawText(
        canvas,
        '${v.toStringAsFixed(0)}x',
        Offset(rect.left - 6, y),
        Alignment.centerRight,
      );
    }

    // Month labels.
    for (var i = 0; i < months.length; i++) {
      _drawText(
        canvas,
        months[i],
        Offset(xFor(i), rect.bottom + 8),
        Alignment.topCenter,
      );
    }

    // Target line (dashed) + label on the left, where data sits below it.
    final targetY = yFor(target);
    _drawDashedLine(
      canvas,
      Offset(rect.left, targetY),
      Offset(rect.right, targetY),
      Paint()
        ..color = targetColor
        ..strokeWidth = 1.5,
    );
    _drawText(
      canvas,
      targetLabel,
      Offset(rect.left + 4, targetY - 3),
      Alignment.bottomLeft,
      style: labelStyle.copyWith(
        color: AppColors.onWarningContainer,
        fontWeight: FontWeight.w700,
      ),
    );

    // Smooth line through the points (horizontal tangents, no overshoot).
    final points = [
      for (var i = 0; i < values.length; i++) Offset(xFor(i), yFor(values[i])),
    ];
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }

    // Gradient area under the line.
    final areaPath = Path.from(linePath)
      ..lineTo(points.last.dx, rect.bottom)
      ..lineTo(points.first.dx, rect.bottom)
      ..close();
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.22),
            lineColor.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = lineColor,
    );

    // Data points.
    final dotFill = Paint()..color = AppColors.surface;
    final dotStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = lineColor;
    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawCircle(points[i], 3.5, dotFill);
      canvas.drawCircle(points[i], 3.5, dotStroke);
    }

    // Highlighted latest point + value bubble.
    final last = points.last;
    canvas.drawCircle(last, 11, Paint()..color = lineColor.withValues(alpha: 0.15));
    canvas.drawCircle(last, 6.5, dotFill);
    canvas.drawCircle(last, 4.5, Paint()..color = lineColor);
    _drawBubble(canvas, size, last);
  }

  void _drawBubble(Canvas canvas, Size size, Offset anchor) {
    final tp = TextPainter(
      text: TextSpan(
        text: valueLabel,
        style: labelStyle.copyWith(
          color: AppColors.textOnPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final width = tp.width + 16;
    final height = tp.height + 8;
    final left = (anchor.dx - width / 2).clamp(2.0, size.width - width - 2);
    final bottom = anchor.dy - 14;
    final bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, bottom - height, width, height),
      const Radius.circular(8),
    );

    final paint = Paint()..color = lineColor;
    canvas.drawRRect(bubble, paint);
    canvas.drawPath(
      Path()
        ..moveTo(anchor.dx - 4, bottom)
        ..lineTo(anchor.dx + 4, bottom)
        ..lineTo(anchor.dx, bottom + 5)
        ..close(),
      paint,
    );
    tp.paint(canvas, Offset(left + 8, bottom - height + 4));
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    Alignment anchor, {
    TextStyle? style,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style ?? labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = position -
        Offset(
          tp.width * (anchor.x + 1) / 2,
          tp.height * (anchor.y + 1) / 2,
        );
    tp.paint(canvas, offset);
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dash = 5,
    double gap = 4,
  }) {
    var x = start.dx;
    while (x < end.dx) {
      final next = (x + dash).clamp(start.dx, end.dx);
      canvas.drawLine(Offset(x, start.dy), Offset(next, start.dy), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _TurnoverPainter old) =>
      old.values != values ||
      old.months != months ||
      old.axisMin != axisMin ||
      old.axisMax != axisMax ||
      old.target != target ||
      old.lineColor != lineColor ||
      old.labelStyle != labelStyle;
}
