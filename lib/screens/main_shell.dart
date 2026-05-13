import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../services/auth_service.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  const MainShell(
      {super.key, required this.child, required this.currentIndex});

  static const _routes = ['/', '/trade', '/shop', '/plan', '/passbook', '/account'];
  static const _labels = ['Home', 'Trade', 'Shop', 'Plan', 'Passbook', 'Account'];
  static const _icons = [
    Icons.home_outlined,
    Icons.swap_horiz,
    Icons.storefront_outlined,
    Icons.calendar_month_outlined,
    Icons.book_outlined,
    Icons.person_outline,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('DigiGold',
            style: TextStyle(fontWeight: FontWeight.bold, color: kGoldLight)),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: headerGradient)),
        backgroundColor: Colors.transparent,
        actions: [
          GestureDetector(
            onTap: () => context.go('/account'),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: goldGradient,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: kGoldBorder.withOpacity(0.5))),
          boxShadow: [
            BoxShadow(
                color: kGold.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, -4))
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (i) => context.go(_routes[i]),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: kGold,
          unselectedItemColor: kTextMuted,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle:
              const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: List.generate(
              6,
              (i) => BottomNavigationBarItem(
                    icon: Icon(_icons[i]),
                    label: _labels[i],
                  )),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) => Drawer(
        child: Container(
          decoration: BoxDecoration(gradient: headerGradient),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, gradient: goldGradient),
                        child: const Icon(Icons.person,
                            color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 12),
                      const Text('DigiGold',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24),
                ..._routes.asMap().entries.map((e) => ListTile(
                      leading: Icon(_icons[e.key], color: kGoldLight),
                      title: Text(_labels[e.key],
                          style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                        context.go(e.value);
                      },
                    )),
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white70),
                  title: const Text('Logout',
                      style: TextStyle(color: Colors.white70)),
                  onTap: () async {
                    await AuthService.logout();
                    if (!context.mounted) return;
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ),
      );
}
