import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/verify_screen.dart';
import 'screens/setpin_screen.dart';
import 'screens/main_shell.dart';
import 'screens/home_screen.dart';
import 'screens/trade_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/passbook_screen.dart';
import 'screens/account_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/sip_detail_screen.dart';
import 'screens/auto_pay_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const DigiGoldApp());
}

final _router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final loggedIn = await AuthService.isLoggedIn();
    final isAdmin = await AuthService.isAdmin();
    final loc = state.matchedLocation;

    if (!loggedIn &&
        loc != '/login' &&
        loc != '/register' &&
        loc != '/verify' &&
        loc != '/setpin') {
      return '/login';
    }
    if (loggedIn && loc == '/login') {
      return isAdmin ? '/admin' : '/';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return RegisterScreen(
            name: extra['name'], phone: extra['phone']);
      },
    ),
    GoRoute(
      path: '/verify',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return VerifyScreen(
            phone: extra['phone'],
            name: extra['name'],
            email: extra['email']);
      },
    ),
    GoRoute(
      path: '/setpin',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return SetPinScreen(phone: extra['phone']);
      },
    ),
    GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
    GoRoute(
      path: '/sip_detail',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return SipDetailScreen(data: extra['data'], sipId: extra['id']);
      },
    ),
    GoRoute(
      path: '/auto_pay',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return AutoPayScreen(
            sipData: extra['data'], sipId: extra['id']);
      },
    ),
    ShellRoute(
      builder: (_, state, child) {
        final loc = state.matchedLocation;
        final idx = ['/','trade','shop','plan','passbook','account']
            .indexWhere((r) => loc == '/$r' || loc == r);
        return MainShell(
            child: child, currentIndex: idx < 0 ? 0 : idx);
      },
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/trade', builder: (_, __) => const TradeScreen()),
        GoRoute(path: '/shop', builder: (_, __) => const ShopScreen()),
        GoRoute(path: '/plan', builder: (_, __) => const PlanScreen()),
        GoRoute(path: '/passbook', builder: (_, __) => const PassbookScreen()),
        GoRoute(path: '/account', builder: (_, __) => const AccountScreen()),
      ],
    ),
  ],
);

class DigiGoldApp extends StatelessWidget {
  const DigiGoldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DigiGold',
      theme: appTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
