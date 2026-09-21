import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/trade_entry.dart';
import '../theme/app_palette.dart';

class TradeTile extends StatelessWidget {
  const TradeTile({super.key, required this.trade, this.onDelete});

  final TradeEntry trade;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isProfit = trade.pnl >= 0;
    final palette = context.palette;
    final color = isProfit ? palette.statusGood : palette.statusCritical;
    final subtitleParts = <String>[
      DateFormat.yMMMd().format(trade.date),
      if (trade.setup != null && trade.setup!.isNotEmpty) trade.setup!,
      if (trade.instrument != null && trade.instrument!.isNotEmpty) trade.instrument!,
      if (trade.direction != null) trade.direction!.toUpperCase(),
    ];

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(isProfit ? Icons.trending_up : Icons.trending_down, color: color, size: 20),
      ),
      title: Text(subtitleParts.join(' · ')),
      subtitle: trade.note != null && trade.note!.isNotEmpty
          ? Text(trade.note!, style: TextStyle(color: palette.mutedInk))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trade.followedPlan != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                trade.followedPlan! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 16,
                color: trade.followedPlan! ? palette.statusGood : palette.statusCritical,
              ),
            ),
          Text(
            '${isProfit ? '+' : ''}\$${trade.pnl.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
