import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/stock_item.dart';
import '../services/inventory_service.dart';
import '../theme.dart';
import '../utils/validators.dart';
import '../widgets/common.dart';
import '../widgets/stock_item_card.dart';

/// Task 1 + Task 2: scrollable stock entry form that saves to Firestore.
class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key, required this.service, this.onSaved});

  final InventoryService service;

  /// Called after Firestore confirms a write (e.g. to jump to Inventory).
  final VoidCallback? onSaved;

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _sku = TextEditingController();
  final _name = TextEditingController();
  final _qty = TextEditingController();
  final _price = TextEditingController();
  final _reorder = TextEditingController();
  String? _category;
  int _resetCount = 0; // forces the dropdown to rebuild empty after a save

  bool _saving = false;
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void initState() {
    super.initState();
    for (final c in [_sku, _name, _qty, _price, _reorder]) {
      c.addListener(_refreshPreview);
    }
  }

  void _refreshPreview() => setState(() {});

  @override
  void dispose() {
    for (final c in [_sku, _name, _qty, _price, _reorder]) {
      c.dispose();
    }
    _shake.dispose();
    super.dispose();
  }

  StockItem get _preview => StockItem(
    sku: _sku.text.trim().isEmpty ? 'STK-000' : _sku.text.trim(),
    itemName: _name.text.trim().isEmpty ? 'Your item name' : _name.text.trim(),
    category: _category ?? 'Category',
    quantity: int.tryParse(_qty.text.trim()) ?? 0,
    unitPrice: double.tryParse(_price.text.trim()) ?? 0,
    reorderLevel: int.tryParse(_reorder.text.trim()) ?? 0,
  );

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    // Validation gate: nothing is written to Firestore unless every field
    // passes.
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      _shake.forward(from: 0);
      _showSnack(
        'Please fix the highlighted fields. Nothing was saved.',
        AppColors.crimson,
        Icons.error_outline_rounded,
      );
      return;
    }

    final item = StockItem(
      sku: _sku.text.trim(),
      itemName: _name.text.trim(),
      category: _category!,
      quantity: int.parse(_qty.text.trim()),
      unitPrice: double.parse(_price.text.trim()),
      reorderLevel: int.parse(_reorder.text.trim()),
    );

    setState(() => _saving = true);
    try {
      final ref = await widget.service.addItem(item);
      if (!mounted) return;
      // Confirmation is shown only after Firestore acknowledged the write.
      for (final c in [_sku, _name, _qty, _price, _reorder]) {
        c.clear();
      }
      setState(() {
        _category = null;
        _resetCount++;
        _saving = false;
        _autovalidate = AutovalidateMode.disabled;
      });
      await _showSuccess(item, ref.id);
      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      // Keep everything the user typed so they can retry.
      setState(() => _saving = false);
      _shake.forward(from: 0);
      _showSnack(
        'Save failed: ${_friendly(e)}. Your input was kept.',
        AppColors.crimson,
        Icons.cloud_off_rounded,
      );
    }
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('permission-denied')) {
      return 'Firestore rules denied the write';
    }
    if (s.contains('unavailable') || s.contains('Timeout')) {
      return 'Firestore is unreachable';
    }
    return s.replaceFirst('Exception: ', '');
  }

  void _showSnack(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color,
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(msg)),
            ],
          ),
        ),
      );
  }

  Future<void> _showSuccess(StockItem item, String docId) {
    _showSnack(
      '${item.sku} saved to Firestore',
      AppColors.emerald,
      Icons.cloud_done_rounded,
    );
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF34D399), AppColors.emerald],
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Saved to Firestore',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.itemName} (${item.sku}) was stored in stockItems.\nDocument ID: $docId',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('View inventory'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
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
                'Add Stock Item',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: const NetworkBackdrop(url: AppImages.shelves),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel(
                        icon: Icons.visibility_rounded,
                        text: 'Live preview',
                      ),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: StockItemCard(
                          key: ValueKey(_category),
                          item: _preview,
                          showTimestamp: false,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _SectionLabel(
                        icon: Icons.edit_document,
                        text: 'Item details',
                      ),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: _shake,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(
                            math.sin(_shake.value * math.pi * 6) *
                                10 *
                                (1 - _shake.value),
                            0,
                          ),
                          child: child,
                        ),
                        child: _buildFormCard(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('skuField'),
                controller: _sku,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  _UpperCaseFormatter(),
                  LengthLimitingTextInputFormatter(7),
                ],
                decoration: const InputDecoration(
                  labelText: 'SKU',
                  hintText: 'STK-101',
                  helperText: 'Format: STK- followed by 3 digits',
                  prefixIcon: Icon(Icons.qr_code_2_rounded),
                ),
                validator: validateSku,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('nameField'),
                controller: _name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Item name',
                  hintText: 'e.g. Wireless Mouse',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: validateItemName,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                key: ValueKey('categoryField$_resetCount'),
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                hint: const Text('Select a category'),
                items: kCategories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Icon(
                              styleFor(c).icon,
                              color: styleFor(c).color,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(c),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
                validator: validateCategory,
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, c) {
                  final wide = c.maxWidth > 480;
                  final qty = TextFormField(
                    key: const Key('qtyField'),
                    controller: _qty,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      hintText: '0 or more',
                      prefixIcon: Icon(Icons.stacked_bar_chart_rounded),
                    ),
                    validator: validateQuantity,
                  );
                  final reorder = TextFormField(
                    key: const Key('reorderField'),
                    controller: _reorder,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Reorder level',
                      hintText: '0 or more',
                      prefixIcon: Icon(Icons.notifications_active_outlined),
                    ),
                    validator: validateReorderLevel,
                  );
                  if (!wide) {
                    return Column(
                      children: [qty, const SizedBox(height: 14), reorder],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: qty),
                      const SizedBox(width: 12),
                      Expanded(child: reorder),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('priceField'),
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                decoration: const InputDecoration(
                  labelText: 'Unit price (RM)',
                  hintText: '19.90',
                  prefixIcon: Icon(Icons.payments_outlined),
                  prefixText: 'RM ',
                ),
                validator: validateUnitPrice,
              ),
              const SizedBox(height: 22),
              GradientButton(
                key: const Key('saveButton'),
                label: 'Save Item',
                busyLabel: 'Saving to Firestore...',
                icon: Icons.cloud_upload_rounded,
                busy: _saving,
                onPressed: _save,
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: AppColors.muted,
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'All fields are required. Saved to Firestore › stockItems',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
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
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.gold),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
