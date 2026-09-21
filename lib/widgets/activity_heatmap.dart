import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/challenge.dart';
import '../theme/app_palette.dart';
import '../utils/challenge_math.dart';

class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({super.key, required this.challenge, this.onDayTap});

  final Challenge challenge;
  final void Function(DateTime day)? onDayTap;

  static const _cellSize = 22.0;
  static const _cellGap = 6.0;

  @override
  Widget build(BuildContext context) {
    final start = dateOnly(challenge.startDate);
    final duration = challenge.durationDays;
    final days = List.generate(duration, (i) => start.add(Duration(days: i)));
    // ~6 tick labels spread across the strip, however long it is.
    final labelEvery = (duration / 6).ceil().clamp(1, duration);
    final mutedStyle = TextStyle(fontSize: 10, color: context.palette.mutedInk);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A single horizontal timeline strip (day 1 -> day N, left to right)
        // rather than a GitHub-style weeks grid — a 20-30 day challenge reads
        // more clearly as one scrollable row than as a squarish block.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (final date in days)
                    Padding(
                      padding: const EdgeInsets.only(right: _cellGap),
                      child: _DayCell(challenge: challenge, date: date, onTap: onDayTap),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (var i = 0; i < days.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: _cellGap),
                      child: SizedBox(
                        width: _cellSize,
                        child: i % labelEvery == 0
                            ? Text('D${i + 1}', style: mutedStyle, textAlign: TextAlign.center)
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _Legend(),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.challenge, required this.date, this.onTap});

  final Challenge challenge;
  final DateTime date;
  final void Function(DateTime day)? onTap;

  @override
  Widget build(BuildContext context) {
    final status = statusForDay(challenge, date);
    final pnl = netPnlForDay(challenge, date);
    final color = _dayCellColor(context, status, challenge, date);

    final tooltip = status == DayStatus.future
        ? DateFormat.yMMMd().format(date)
        : '${DateFormat.yMMMd().format(date)}\n'
            '${status == DayStatus.noActivity ? 'No trades logged' : '${pnl >= 0 ? '+' : ''}\$${pnl.toStringAsFixed(2)}'}';

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap == null || status == DayStatus.future ? null : () => onTap!(date),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: ActivityHeatmap._cellSize,
          height: ActivityHeatmap._cellSize,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

/// Resolves a day's heatmap color from the app's fixed status palette:
/// profit/loss are the same hue tinted toward the card surface by
/// magnitude (relative to the daily gain required to hit target), so the
/// scale is single-hue per direction rather than an arbitrary gradient.
Color _dayCellColor(
  BuildContext context,
  DayStatus status,
  Challenge challenge,
  DateTime date,
) {
  final palette = context.palette;
  final surface = context.palette.cardSurface;
  switch (status) {
    case DayStatus.future:
      return Color.lerp(surface, palette.mutedInk, 0.08)!;
    case DayStatus.noActivity:
      return Color.lerp(surface, palette.mutedInk, 0.18)!;
    case DayStatus.breakeven:
      return palette.statusWarning;
    case DayStatus.profit:
    case DayStatus.loss:
      final pnl = netPnlForDay(challenge, date);
      final rate = requiredDailyRate(
        challenge.startBalance,
        challenge.targetBalance,
        challenge.durationDays,
      );
      final requiredGain = (challenge.startBalance * rate).abs().clamp(1, double.infinity);
      final ratio = (pnl.abs() / requiredGain).clamp(0.0, 2.0);
      final t = (0.35 + (ratio / 2.0) * 0.65).clamp(0.35, 1.0);
      final base = status == DayStatus.profit ? palette.statusGood : palette.statusCritical;
      return Color.lerp(surface, base, t)!;
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final surface = palette.cardSurface;
    Widget swatch(Color c) => Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
        );
    Widget label(String text) => Text(
          text,
          style: TextStyle(fontSize: 11, color: palette.mutedInk),
        );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        swatch(Color.lerp(surface, palette.mutedInk, 0.18)!),
        label('No activity'),
        const SizedBox(width: 10),
        swatch(palette.statusCritical),
        label('Loss day'),
        const SizedBox(width: 10),
        swatch(palette.statusWarning),
        label('Breakeven'),
        const SizedBox(width: 10),
        swatch(palette.statusGood),
        label('Profit day'),
      ],
    );
  }
}
