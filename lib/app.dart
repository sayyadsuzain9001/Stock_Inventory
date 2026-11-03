import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'screens/add_item_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inventory_screen.dart';
import 'services/inventory_service.dart';
import 'theme.dart';

class StockInventoryApp extends StatelessWidget {
  const StockInventoryApp({
    super.key,
    required this.firestore,
    this.service,
    this.useGoogleFonts = true,
  });

  final FirebaseFirestore firestore;

  /// Optional override (used by tests to simulate write failures).
  final InventoryService? service;
  final bool useGoogleFonts;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Inventory Manager',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(useGoogleFonts: useGoogleFonts),
      home: HomeShell(service: service ?? InventoryService(firestore)),
    );
  }
}

/// Admin panel: Dashboard, Add Item and All Records (every submission with
/// timestamps and filters). No login.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.service});
  final InventoryService service;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        service: widget.service,
        onAddItem: () => _go(1),
        onOpenInventory: () => _go(2),
      ),
      AddItemScreen(service: widget.service, onSaved: () => _go(2)),
      InventoryScreen(service: widget.service),
    ];

    return Scaffold(
      body: Stack(
        children: [
          for (var i = 0; i < pages.length; i++)
            IgnorePointer(
              ignoring: i != _index,
              child: AnimatedOpacity(
                opacity: i == _index ? 1 : 0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                child: AnimatedSlide(
                  offset: i == _index ? Offset.zero : const Offset(0, 0.02),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  child: TickerMode(
                    enabled: i == _index,
                    child: ExcludeFocus(
                      excluding: i != _index,
                      child: pages[i],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box_rounded),
            label: 'Add Item',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_outlined),
            selectedIcon: Icon(Icons.inventory_rounded),
            label: 'Records',
          ),
        ],
      ),
    );
  }
}
