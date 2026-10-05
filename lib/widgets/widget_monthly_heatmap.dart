import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/challenge.dart';
import '../utils/challenge_math.dart';

class WidgetMonthlyHeatmap extends StatelessWidget {
  const WidgetMonthlyHeatmap({
    super.key,
    required this.challenge,
    this.now,
  });

  final Challenge challenge;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final currentDate = dateOnly(now ?? DateTime.now());
    final year = currentDate.year;
    final month = currentDate.month;
    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month)).toUpperCase();

    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final totalDays = lastDay.day;

    // GitHub matrix layout:
    // Rows: 0..6 (Mon, Tue, Wed, Thu, Fri, Sat, Sun)
    // Columns: 0..numWeeks-1
    final firstWeekday = firstDay.weekday; // 1 = Mon, 7 = Sun
    final totalSlots = (firstWeekday - 1) + totalDays;
    final numWeeks = (totalSlots / 7.0).ceil();

    int activeDays = 0;
    int profitDays = 0;
    int lossDays = 0;
    double monthlyPnl = 0.0;

    for (int d = 1; d <= totalDays; d++) {
      final date = DateTime(year, month, d);
      if (hasTradesOnDay(challenge, date)) {
        activeDays++;
        final pnl = netPnlForDay(challenge, date);
        monthlyPnl += pnl;
        if (pnl > 0) profitDays++;
        if (pnl < 0) lossDays++;
      }
    }

    return Container(
      width: 320,
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Heatmap section (Left)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        monthName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$activeDays/$totalDays active',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Heatmap Grid: Day labels + Week columns
                Expanded(
                  child: Row(
                    children: [
                      // Day labels (M, T, W, T, F, S, S)
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _DayLabel('M'),
                          _DayLabel('T'),
                          _DayLabel('W'),
                          _DayLabel('T'),
                          _DayLabel('F'),
                          _DayLabel('S'),
                          _DayLabel('S'),
                        ],
                      ),
                      const SizedBox(width: 4),
                      // Columns for each week
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            for (int w = 0; w < numWeeks; w++)
                              Padding(
                                padding: const EdgeInsets.only(right: 3.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    for (int r = 0; r < 7; r++)
                                      _buildHeatmapCell(
                                        weekIndex: w,
                                        rowDayIndex: r,
                                        firstWeekday: firstWeekday,
                                        totalDays: totalDays,
                                        year: year,
                                        month: month,
                                        currentDate: currentDate,
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Vertical Divider
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(vertical: 2),
            color: const Color(0xFF1E293B),
          ),
          const SizedBox(width: 8),
          // Summary Panel (Right)
          SizedBox(
            width: 95,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'MONTH P&L',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${monthlyPnl >= 0 ? '+' : ''}\$${monthlyPnl.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: monthlyPnl >= 0
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFF87171),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _StatBadge(
                      count: profitDays,
                      color: const Color(0xFF22C55E),
                      label: 'W',
                    ),
                    const SizedBox(width: 4),
                    _StatBadge(
                      count: lossDays,
                      color: const Color(0xFFEF4444),
                      label: 'L',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Legend
                const Row(
                  children: [
                    _LegendBox(color: Color(0xFF334155)),
                    SizedBox(width: 2),
                    _LegendBox(color: Color(0xFFEF4444)),
                    SizedBox(width: 2),
                    _LegendBox(color: Color(0xFFF59E0B)),
                    SizedBox(width: 2),
                    _LegendBox(color: Color(0xFF22C55E)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapCell({
    required int weekIndex,
    required int rowDayIndex,
    required int firstWeekday,
    required int totalDays,
    required int year,
    required int month,
    required DateTime currentDate,
  }) {
    final slotIndex = weekIndex * 7 + rowDayIndex;
    final dayNum = slotIndex - (firstWeekday - 1) + 1;

    if (dayNum < 1 || dayNum > totalDays) {
      return const SizedBox(width: 8.5, height: 8.5);
    }

    final date = DateTime(year, month, dayNum);
    final isFuture = date.isAfter(currentDate);
    final hasTrades = hasTradesOnDay(challenge, date);

    Color cellColor;
    Border? cellBorder;

    if (isFuture) {
      cellColor = const Color(0xFF0F172A);
      cellBorder = Border.all(color: const Color(0xFF1E293B), width: 0.6);
    } else if (hasTrades) {
      final pnl = netPnlForDay(challenge, date);
      if (pnl > 0) {
        cellColor = const Color(0xFF22C55E);
      } else if (pnl < 0) {
        cellColor = const Color(0xFFEF4444);
      } else {
        cellColor = const Color(0xFFF59E0B);
      }
    } else {
      cellColor = const Color(0xFF334155);
    }

    return Container(
      width: 8.5,
      height: 8.5,
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(2),
        border: cellBorder,
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8.5,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 7,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
          height: 1.0,
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.count,
    required this.color,
    required this.label,
  });

  final int count;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        '$count$label',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _LegendBox extends StatelessWidget {
  const _LegendBox({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
