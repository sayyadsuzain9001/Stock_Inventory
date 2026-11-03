import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/stock_item.dart';
import '../services/inventory_service.dart';
import '../theme.dart';
import '../utils/validators.dart';
import '../widgets/common.dart';
import 'inventory_screen.dart' show lowStockItems;

/// Graphic overview of the Firestore inventory.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.service,
    required this.onAddItem,
    required this.onOpenInventory,
  });

  final InventoryService service;
  final VoidCallback onAddItem;
  final VoidCallback onOpenInventory;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Stream<InventorySnapshot> _stream = widget.service.watchItems();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<InventorySnapshot>(
        stream: _stream,
        builder: (context, snap) {
          final items = snap.data?.items ?? const <StockItem>[];
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 240,
                backgroundColor: AppColors.midnight,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 20,
                    bottom: 16,
                  ),
                  title: const Text(
                    'StockPilot',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      const NetworkBackdrop(
                        url: AppImages.warehouseHero,
                        opacity: 0.55,
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 78,
                        child:
                            Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Pill(
                                      text: 'NET4207 · Firestore',
                                      color: AppColors.gold,
                                      filled: true,
                                      icon: Icons.local_fire_department_rounded,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Smart stock control\nfor small retailers',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            height: 1.2,
                                          ),
                                    ),
                                  ],
                                )
                                .animate()
                                .fadeIn(duration: 500.ms)
                                .slideX(begin: -0.08, end: 0),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: _buildContent(context, snap, items),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncSnapshot<InventorySnapshot> snap,
    List<StockItem> items,
  ) {
    if (snap.hasError) {
      return StateMessage(
        icon: Icons.cloud_off_rounded,
        color: AppColors.crimson,
        title: 'Firestore is unreachable',
        message: '${snap.error}',
        actionLabel: 'Retry',
        onAction: () => setState(() => _stream = widget.service.watchItems()),
      );
    }
    if (!snap.hasData) {
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: SkeletonList(count: 3),
      );
    }

    final totalUnits = items.fold<int>(0, (s, i) => s + i.quantity);
    final value = items.fold<double>(0, (s, i) => s + i.stockValue);
    final low = lowStockItems(items);

    final tiles = [
      _StatTile(
        label: 'Stock items',
        value: items.length.toDouble(),
        icon: Icons.inventory_2_rounded,
        gradient: AppColors.actionGradient,
      ),
      _StatTile(
        label: 'Units on hand',
        value: totalUnits.toDouble(),
        icon: Icons.stacked_line_chart_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
        ),
      ),
      _StatTile(
        label: 'Low stock',
        value: low.length.toDouble(),
        icon: Icons.warning_amber_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFFFB7185), AppColors.crimson],
        ),
      ),
      _StatTile(
        label: 'Stock value',
        value: value,
        prefix: 'RM ',
        decimals: 2,
        icon: Icons.account_balance_wallet_rounded,
        gradient: AppColors.goldGradient,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth > 700 ? 4 : 2;
            final w = (c.maxWidth - (cols - 1) * 12) / cols;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < tiles.length; i++)
                  SizedBox(width: w, child: tiles[i])
                      .animate()
                      .fadeIn(delay: (80 * i).ms, duration: 400.ms)
                      .scaleXY(begin: 0.92, end: 1, curve: Curves.easeOutBack),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GradientButton(
                label: 'Add Item',
                icon: Icons.add_circle_rounded,
                onPressed: widget.onAddItem,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GradientButton(
                label: 'Search Stock',
                icon: Icons.manage_search_rounded,
                gradient: AppColors.goldGradient,
                onPressed: widget.onOpenInventory,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Panel(
          title: 'Stock by category',
          icon: Icons.bar_chart_rounded,
          child: _CategoryChart(items: items),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Needs reorder',
          icon: Icons.notification_important_rounded,
          trailing: low.isEmpty
              ? null
              : Pill(
                  text: '${low.length} item${low.length == 1 ? '' : 's'}',
                  color: AppColors.crimson,
                ),
          child: low.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.verified_rounded, color: AppColors.emerald),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'All items are above their reorder level.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (final i in low.take(5)) _LowStockRow(item: i),
                  ],
                ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    this.prefix = '',
    this.decimals = 0,
  });

  final String label;
  final double value;
  final IconData icon;
  final Gradient gradient;
  final String prefix;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -14,
            child: Icon(
              icon,
              size: 84,
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$prefix${v.toStringAsFixed(decimals)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Horizontal bar chart (no chart package needed).
class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.items});
  final List<StockItem> items;

  @override
  Widget build(BuildContext context) {
    final units = {
      for (final c in kCategories)
        c: items
            .where((i) => i.category == c)
            .fold<int>(0, (s, i) => s + i.quantity),
    };
    final counts = {
      for (final c in kCategories)
        c: items.where((i) => i.category == c).length,
    };
    final maxUnits = units.values
        .fold<int>(0, (a, b) => a > b ? a : b)
        .clamp(1, 1 << 30);

    return Column(
      children: [
        for (final c in kCategories)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Row(
                    children: [
                      Icon(
                        styleFor(c).icon,
                        size: 18,
                        color: styleFor(c).color,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          c,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      return Stack(
                        children: [
                          Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.line,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: units[c]! / maxUnits),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, _) => Container(
                              height: 14,
                              width: box.maxWidth * v,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    styleFor(c).color.withValues(alpha: 0.7),
                                    styleFor(c).color,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 92,
                  child: Text(
                    '${units[c]} units · ${counts[c]}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LowStockRow extends StatelessWidget {
  const _LowStockRow({required this.item});
  final StockItem item;

  @override
  Widget build(BuildContext context) {
    final style = styleFor(item.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.crimson.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(style.icon, color: style.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${item.itemName}  ·  ${item.sku}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${item.quantity} / ${item.reorderLevel}',
            style: const TextStyle(
              color: AppColors.crimson,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
