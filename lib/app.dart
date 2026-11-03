import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'screens/add_item_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/inventory_service.dart';
import 'theme.dart';

class StockInventoryApp extends StatelessWidget {
  const StockInventoryApp({
    super.key,
    required this.firestore,
    required this.auth,
    this.service,
    this.useGoogleFonts = true,
  });

  final FirebaseFirestore firestore;
  final AuthService auth;

  /// Optional override (used by tests to simulate write failures).
  final InventoryService? service;
  final bool useGoogleFonts;

  @override
  Widget build(BuildContext context) {
    final inventory = service ?? InventoryService(firestore);
    return MaterialApp(
      title: 'Stock Inventory Manager',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(useGoogleFonts: useGoogleFonts),
      home: StreamBuilder<AppUser?>(
        stream: auth.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final user = snap.data;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: user == null || !user.isAdmin
                ? PublicFormPage(
                    key: const ValueKey('public'),
                    service: inventory,
                    auth: auth,
                  )
                : HomeShell(
                    key: ValueKey('home_${user.uid}'),
                    service: inventory,
                    user: user,
                    auth: auth,
                  ),
          );
        },
      ),
    );
  }
}

/// Public start page: anyone can submit the stock form without logging in.
/// The "Admin" button opens the admin sign-in.
class PublicFormPage extends StatelessWidget {
  const PublicFormPage({super.key, required this.service, required this.auth});
  final InventoryService service;
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AddItemScreen(service: service),
        Positioned(
          top: 0,
          left: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('adminLoginButton'),
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => LoginScreen(auth: auth)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.admin_panel_settings_rounded,
                          color: AppColors.gold,
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Admin login',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Admin area: Dashboard, Add Item and All Records (every submission with
/// timestamps and filters).
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.service,
    required this.user,
    required this.auth,
  });
  final InventoryService service;
  final AppUser user;
  final AuthService auth;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final admin = widget.user.isAdmin;
    final pages = admin
        ? [
            DashboardScreen(
              service: widget.service,
              onAddItem: () => _go(1),
              onOpenInventory: () => _go(2),
            ),
            AddItemScreen(
              service: widget.service,
              submittedBy: widget.user.email,
              onSaved: () => _go(2),
            ),
            InventoryScreen(service: widget.service),
          ]
        : [
            AddItemScreen(
              service: widget.service,
              submittedBy: widget.user.email,
            ),
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
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: _AccountButton(user: widget.user, auth: widget.auth),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: admin
          ? NavigationBar(
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
            )
          : null,
    );
  }
}

class _AccountButton extends StatelessWidget {
  const _AccountButton({required this.user, required this.auth});
  final AppUser user;
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      key: const Key('accountMenu'),
      tooltip: 'Account',
      onSelected: (v) {
        if (v == 'logout') auth.signOut();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.email,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Text(
                '${user.roleLabel} account',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          key: Key('logoutItem'),
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18),
              SizedBox(width: 10),
              Text('Sign out'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: user.isAdmin
                  ? AppColors.gold
                  : AppColors.emerald,
              child: Icon(
                user.isAdmin
                    ? Icons.admin_panel_settings_rounded
                    : Icons.person_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              user.roleLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
