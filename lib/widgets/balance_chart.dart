import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/challenge.dart';
import '../theme/app_palette.dart';
import '../utils/challenge_math.dart' as math_utils;

class BalanceChart extends StatelessWidget {
  const BalanceChart({super.key, required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;
    final duration = challenge.durationDays;
    // Trades can be logged for any day in the challenge window, so the
    // actual-balance line must reach the furthest logged day, not just
    // today's wall-clock date, or newly logged trades appear to do nothing.
    final lastPlottedDay = math.max(
      math_utils.currentDayIndex(challenge),
      math_utils.lastActivityDayIndex(challenge),
    );

    final paceSpots = List.generate(
      duration + 1,
      (i) => FlSpot(i.toDouble(), math_utils.expectedBalance(challenge, i)),
    );
    final actualSpots = List.generate(
      lastPlottedDay + 1,
      (i) => FlSpot(i.toDouble(), math_utils.actualBalanceAtDayIndex(challenge, i)),
    );

    final maxY = [
      challenge.targetBalance,
      ...paceSpots.map((s) => s.y),
      ...actualSpots.map((s) => s.y),
    ].reduce((a, b) => a > b ? a : b);
    final minY = [
      0.0,
      ...actualSpots.map((s) => s.y),
    ].reduce((a, b) => a < b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.7,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: duration.toDouble(),
              minY: minY,
              maxY: maxY * 1.05,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: palette.gridline, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: (duration / 5).clamp(1, duration).toDouble(),
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'D${value.toInt()}',
                        style: TextStyle(fontSize: 10, color: palette.mutedInk),
                      ),
                    ),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    getTitlesWidget: (value, meta) => Text(
                      '\$${value.toInt()}',
                      style: TextStyle(fontSize: 10, color: palette.mutedInk),
                    ),
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots
                      .map((s) => LineTooltipItem(
                            '\$${s.y.toStringAsFixed(2)}',
                            const TextStyle(color: Colors.white, fontSize: 11),
                          ))
                      .toList(),
                ),
              ),
              lineBarsData: [
                // Required pace line.
                LineChartBarData(
                  spots: paceSpots,
                  isCurved: false,
                  color: palette.mutedInk,
                  barWidth: 2,
                  dashArray: [6, 4],
                  dotData: const FlDotData(show: false),
                ),
                // Target reference line.
                LineChartBarData(
                  spots: [
                    FlSpot(0, challenge.targetBalance),
                    FlSpot(duration.toDouble(), challenge.targetBalance),
                  ],
                  isCurved: false,
                  color: palette.chartAccent,
                  barWidth: 1.5,
                  dashArray: [2, 4],
                  dotData: const FlDotData(show: false),
                ),
                // Actual balance line — a marker only on the endpoint ("you
                // are here"), not on every historical day.
                LineChartBarData(
                  spots: actualSpots,
                  isCurved: false,
                  color: scheme.primary,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (spot, _) => spot.x == actualSpots.last.x,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 4,
                      color: scheme.primary,
                      strokeWidth: 2,
                      strokeColor: palette.cardSurface,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: scheme.primary.withValues(alpha: 0.10),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          children: [
            _LegendDot(color: scheme.primary, label: 'Actual'),
            _LegendDot(color: palette.mutedInk, label: 'Required pace'),
            _LegendDot(color: palette.chartAccent, label: 'Target'),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: context.palette.mutedInk)),
      ],
    );
  }
}
