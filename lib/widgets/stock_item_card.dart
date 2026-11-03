import 'package:flutter/material.dart';

import '../models/stock_item.dart';
import '../theme.dart';
import '../utils/inventory_filter.dart' show formatTimestamp;
import 'common.dart';

/// Readable card for one Firestore stock item.
class StockItemCard extends StatelessWidget {
  const StockItemCard({
    super.key,
    required this.item,
    this.showTimestamp = true,
  });
  final StockItem item;

  /// Off for the live preview on the form (nothing submitted yet).
  final bool showTimestamp;

  @override
  Widget build(BuildContext context) {
    final style = styleFor(item.category);
    final low = item.isLowStock;
    final statusColor = low ? AppColors.crimson : AppColors.emerald;
    // Fill the bar relative to twice the reorder level (or the quantity).
    final cap = [
      item.reorderLevel * 2,
      item.quantity,
      1,
    ].reduce((a, b) => a > b ? a : b);
    final ratio = (item.quantity / cap).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: low
              ? AppColors.crimson.withValues(alpha: 0.35)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: style.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: style.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(style.icon, color: style.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.itemName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Pill(
                                    text: item.sku,
                                    color: AppColors.indigo,
                                    icon: Icons.qr_code_2_rounded,
                                  ),
                                  Pill(text: item.category, color: style.color),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'RM ${item.unitPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Pill(
                              text: low ? 'LOW' : 'OK',
                              color: statusColor,
                              filled: low,
                              icon: low
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (showTimestamp) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Submitted ${formatTimestamp(item.createdAt)}'
                              '${item.createdBy != null ? ' by ${item.createdBy}' : ''}',
                              key: const Key('submittedAt'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        Flexible(
                          flex: 3,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                _Metric(
                                  label: 'Qty',
                                  value: '${item.quantity}',
                                  color: statusColor,
                                ),
                                const SizedBox(width: 16),
                                _Metric(
                                  label: 'Reorder at',
                                  value: '${item.reorderLevel}',
                                  color: AppColors.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: ratio),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, _) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: v,
                                minHeight: 8,
                                backgroundColor: AppColors.line,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
