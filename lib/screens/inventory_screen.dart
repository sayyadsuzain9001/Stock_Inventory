import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/stock_item.dart';
import '../services/inventory_service.dart';
import '../theme.dart';
import '../utils/inventory_filter.dart';
import '../utils/validators.dart';
import '../widgets/common.dart';
import '../widgets/stock_item_card.dart';

/// Task 2 (retrieval) + Task 3 (advanced search) on live Firestore data.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, required this.service});
  final InventoryService service;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _search = TextEditingController();
  String _category = 'All';
  bool _lowStockOnly = false;
  QtySort _sort = QtySort.newest;
  DateFilter _dateFilter = DateFilter.all;
  DateTime? _customFrom;
  DateTime? _customTo;
  late Stream<InventorySnapshot> _stream;

  @override
  void initState() {
    super.initState();
    _stream = widget.service.watchItems();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _anyFilterActive =>
      _search.text.trim().isNotEmpty ||
      _category != 'All' ||
      _lowStockOnly ||
      _dateFilter != DateFilter.all ||
      _sort != QtySort.newest;

  void _clearFilters() {
    setState(() {
      _search.clear();
      _category = 'All';
      _lowStockOnly = false;
      _sort = QtySort.newest;
      _dateFilter = DateFilter.all;
      _customFrom = null;
      _customTo = null;
    });
  }

  ({DateTime? from, DateTime? to}) get _dateRange =>
      _dateFilter == DateFilter.custom
      ? (from: _customFrom, to: _customTo)
      : rangeFor(_dateFilter);

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _customFrom != null && _customTo != null
          ? DateTimeRange(start: _customFrom!, end: _customTo!)
          : null,
      helpText: 'Show records submitted between',
      builder: (context, child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 640),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: child,
          ),
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _dateFilter = DateFilter.custom;
      _customFrom = picked.start;
      _customTo = picked.end;
    });
  }

  static const _sortLabels = {
    QtySort.newest: 'Newest first',
    QtySort.oldest: 'Oldest first',
    QtySort.ascending: 'Quantity: low to high',
    QtySort.descending: 'Quantity: high to low',
  };
  static const _sortIcons = {
    QtySort.newest: Icons.schedule_rounded,
    QtySort.oldest: Icons.history_rounded,
    QtySort.ascending: Icons.arrow_upward_rounded,
    QtySort.descending: Icons.arrow_downward_rounded,
  };

  Widget _dateChip(
    String label,
    DateFilter f,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final selected = _dateFilter == f;
    return ChoiceChip(
      key: Key('date_${f.name}'),
      label: Text(label),
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? Colors.white : AppColors.indigo,
      ),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.indigo,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.ink,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) =>
          onTap != null ? onTap() : setState(() => _dateFilter = f),
    );
  }

  void _retry() => setState(() => _stream = widget.service.watchItems());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<InventorySnapshot>(
        stream: _stream,
        builder: (context, snap) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 150,
                backgroundColor: AppColors.midnight,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 20,
                    bottom: 16,
                  ),
                  title: const Text(
                    'Inventory',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  background: const NetworkBackdrop(
                    url: AppImages.warehouseHero,
                  ),
                ),
                actions: [
                  if (snap.hasData)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _SyncBadge(fromCache: snap.data!.fromCache),
                    ),
                ],
              ),
              SliverToBoxAdapter(child: _buildControls()),
              ..._buildBody(snap),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildControls() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.midnight.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('searchField'),
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by item name or SKU',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(_search.clear),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', ...kCategories].map((c) {
                    final selected = _category == c;
                    final style = c == 'All'
                        ? const CategoryStyle(
                            Icons.apps_rounded,
                            AppColors.indigo,
                          )
                        : styleFor(c);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        key: Key('cat_$c'),
                        label: Text(c),
                        avatar: Icon(
                          style.icon,
                          size: 18,
                          color: selected ? Colors.white : style.color,
                        ),
                        selected: selected,
                        showCheckmark: false,
                        selectedColor: style.color,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setState(() => _category = c),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Icon(
                    Icons.event_note_rounded,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'SUBMITTED',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _dateChip(
                    'All time',
                    DateFilter.all,
                    Icons.all_inclusive_rounded,
                  ),
                  _dateChip('Today', DateFilter.today, Icons.today_rounded),
                  _dateChip(
                    'Last 7 days',
                    DateFilter.last7Days,
                    Icons.date_range_rounded,
                  ),
                  _dateChip(
                    _dateFilter == DateFilter.custom && _customFrom != null
                        ? '${formatDate(_customFrom!)} – ${formatDate(_customTo!)}'
                        : 'Pick dates…',
                    DateFilter.custom,
                    Icons.edit_calendar_rounded,
                    onTap: _pickDates,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilterChip(
                    key: const Key('lowStockChip'),
                    label: const Text('Low stock only'),
                    avatar: Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: _lowStockOnly ? Colors.white : AppColors.crimson,
                    ),
                    selected: _lowStockOnly,
                    showCheckmark: false,
                    selectedColor: AppColors.crimson,
                    labelStyle: TextStyle(
                      color: _lowStockOnly ? Colors.white : AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (v) => setState(() => _lowStockOnly = v),
                  ),
                  PopupMenuButton<QtySort>(
                    key: const Key('sortControl'),
                    tooltip: 'Sort records',
                    initialValue: _sort,
                    onSelected: (v) => setState(() => _sort = v),
                    itemBuilder: (_) => [
                      for (final v in QtySort.values)
                        PopupMenuItem(
                          key: Key('sort_${v.name}'),
                          value: v,
                          child: Row(
                            children: [
                              Icon(_sortIcons[v], size: 18),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  _sortLabels[v]!,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.indigo,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _sortIcons[_sort],
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              'Sort: ${_sortLabels[_sort]}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _anyFilterActive ? 1 : 0.45,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton.icon(
                      key: const Key('clearFilters'),
                      onPressed: _anyFilterActive ? _clearFilters : null,
                      icon: const Icon(Icons.filter_alt_off_rounded),
                      label: const Text('Clear Filters'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBody(AsyncSnapshot<InventorySnapshot> snap) {
    Widget wrap(Widget child) => SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: child,
          ),
        ),
      ),
    );

    if (snap.hasError) {
      return [
        wrap(
          StateMessage(
            icon: Icons.cloud_off_rounded,
            color: AppColors.crimson,
            title: 'Could not load inventory',
            message: 'Firestore error: ${snap.error}',
            actionLabel: 'Retry',
            onAction: _retry,
          ),
        ),
      ];
    }
    if (!snap.hasData) {
      return [
        wrap(
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Loading stock from Firestore...',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
                SkeletonList(),
              ],
            ),
          ),
        ),
      ];
    }

    final all = snap.data!.items;
    if (all.isEmpty) {
      return [
        wrap(
          const StateMessage(
            icon: Icons.inventory_2_outlined,
            title: 'No stock items yet',
            message: 'Items you save on the Add Item tab are stored in Firestore and appear here.',
          ),
        ),
      ];
    }

    final visible = applyInventoryFilters(
      all,
      keyword: _search.text,
      category: _category,
      lowStockOnly: _lowStockOnly,
      from: _dateRange.from,
      to: _dateRange.to,
      sort: _sort,
    );

    return [
      wrap(
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  'Showing ${visible.length} of ${all.length} items',
                  key: const Key('resultCount'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${all.where((i) => i.isLowStock).length} low stock',
                style: const TextStyle(
                  color: AppColors.crimson,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      if (visible.isEmpty)
        wrap(
          StateMessage(
            icon: Icons.search_off_rounded,
            color: AppColors.gold,
            title: 'No items match your filters',
            message:
                'Try a different keyword or category, or clear the filters to see all ${all.length} items.',
            actionLabel: 'Clear Filters',
            onAction: _clearFilters,
          ),
        )
      else
        SliverList.builder(
          itemCount: visible.length,
          itemBuilder: (context, i) {
            final item = visible[i];
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child:
                      StockItemCard(
                            key: ValueKey('card_${item.id}'),
                            item: item,
                          )
                          .animate(key: ValueKey('anim_${item.id}_$i'))
                          .fadeIn(
                            duration: 350.ms,
                            delay: (40 * (i < 10 ? i : 10)).ms,
                          )
                          .slideY(
                            begin: 0.15,
                            end: 0,
                            duration: 350.ms,
                            curve: Curves.easeOutCubic,
                          ),
                ),
              ),
            );
          },
        ),
    ];
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.fromCache});
  final bool fromCache;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: fromCache
          ? 'Showing cached data while reconnecting'
          : 'Live data from Firestore',
      child: Pill(
        text: fromCache ? 'Cached' : 'Live',
        color: fromCache ? AppColors.gold : AppColors.emerald,
        filled: true,
        icon: fromCache ? Icons.cloud_sync_rounded : Icons.cloud_done_rounded,
      ),
    );
  }
}

/// Exposed for the dashboard's "low stock" quick list.
List<StockItem> lowStockItems(List<StockItem> items) =>
    items.where((i) => i.isLowStock).toList()
      ..sort((a, b) => a.quantity.compareTo(b.quantity));
