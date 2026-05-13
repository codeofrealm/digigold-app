import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/price_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _bannerCtrl = PageController();
  String? _phone;
  double _goldPrice = 7200;
  double _silverPrice = 92;
  bool _isLive = false;

  final _banners = const [
    {'title': 'Buy Gold from ₹1', 'sub': 'Start your gold journey today', 'color': kGold},
    {'title': 'Silver at Best Rates', 'sub': 'Invest in silver now', 'color': kMaroon},
    {'title': 'Refer & Earn', 'sub': 'Get ₹100 on every referral', 'color': Color(0xFF2e7d32)},
  ];

  @override
  void initState() {
    super.initState();
    _init();
    _startBannerTimer();
  }

  Future<void> _init() async {
    _phone = await AuthService.getPhone();
    await PriceService.fetchPrices();
    if (!mounted) return;
    setState(() {
      _goldPrice = PriceService.goldPrice;
      _silverPrice = PriceService.silverPrice;
      _isLive = PriceService.isLive;
    });
  }

  void _startBannerTimer() {
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (!mounted) return;
      final next = (_bannerCtrl.page?.round() ?? 0) + 1;
      _bannerCtrl.animateToPage(
        next % _banners.length,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _startBannerTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_phone == null) {
      return const Center(child: CircularProgressIndicator(color: kGold));
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(_phone).snapshots(),
      builder: (_, userSnap) {
        final user = userSnap.data?.data() as Map<String, dynamic>? ?? {};
        final goldGrams = (user['balanceGrams'] ?? 0.0).toDouble();
        final silverGrams = (user['balanceSilverGrams'] ?? 0.0).toDouble();
        final walletInr = (user['walletInr'] ?? 0.0).toDouble();
        final portfolioValue = goldGrams * _goldPrice + silverGrams * _silverPrice + walletInr;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('prices').doc('live').snapshots(),
          builder: (_, priceSnap) {
            if (priceSnap.hasData && priceSnap.data!.exists) {
              final p = priceSnap.data!.data() as Map<String, dynamic>;
              _goldPrice = (p['gold'] ?? _goldPrice).toDouble();
              _silverPrice = (p['silver'] ?? _silverPrice).toDouble();
              _isLive = true;
            }
            return RefreshIndicator(
              onRefresh: _init,
              color: kGold,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _portfolioCard(portfolioValue, goldGrams, silverGrams, walletInr),
                    const SizedBox(height: 16),
                    _priceCards(),
                    const SizedBox(height: 16),
                    _bannerSection(),
                    const SizedBox(height: 16),
                    _savingsSlabs(goldGrams),
                    const SizedBox(height: 16),
                    _trustBadges(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _portfolioCard(double value, double gold, double silver, double wallet) =>
      Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: headerGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: kMaroon.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My Portfolio',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isLive ? Colors.greenAccent : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(_isLive ? 'Live' : 'Cached',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('₹${value.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _metalChip('Gold', '${gold.toStringAsFixed(4)}g'),
                const SizedBox(width: 10),
                _metalChip('Silver', '${silver.toStringAsFixed(4)}g'),
                const SizedBox(width: 10),
                _metalChip('Wallet', '₹${wallet.toStringAsFixed(0)}'),
              ],
            ),
          ],
        ),
      );

  Widget _metalChip(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );

  Widget _priceCards() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(child: _priceCard('Gold', _goldPrice, '24K 999.9', kGold)),
            const SizedBox(width: 12),
            Expanded(child: _priceCard('Silver', _silverPrice, '999 Fine', kTextSecondary)),
          ],
        ),
      );

  Widget _priceCard(String metal, double price, String purity, Color color) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, color: color, size: 10),
                const SizedBox(width: 6),
                Text(metal,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text('₹${price.toStringAsFixed(0)}/g',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: kTextPrimary)),
            Text(purity, style: const TextStyle(color: kTextMuted, fontSize: 12)),
          ],
        ),
      );

  Widget _bannerSection() => Column(
        children: [
          SizedBox(
            height: 120,
            child: PageView.builder(
              controller: _bannerCtrl,
              itemCount: _banners.length,
              itemBuilder: (_, i) {
                final b = _banners[i];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: b['color'] as Color,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(b['title'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(b['sub'] as String,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          SmoothPageIndicator(
            controller: _bannerCtrl,
            count: _banners.length,
            effect: const WormEffect(
              dotHeight: 6,
              dotWidth: 6,
              activeDotColor: kGold,
              dotColor: Colors.grey,
            ),
          ),
        ],
      );

  Widget _savingsSlabs(double goldGrams) {
    // Slab thresholds: Bronze 0-1g, Silver 1-5g, Gold 5-10g
    final slabs = [
      {'label': 'Bronze', 'min': 0.0, 'max': 1.0},
      {'label': 'Silver', 'min': 1.0, 'max': 5.0},
      {'label': 'Gold', 'min': 5.0, 'max': 10.0},
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Savings Slabs',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: kTextPrimary, fontSize: 16)),
          const SizedBox(height: 12),
          ...slabs.asMap().entries.map((e) {
            final min = e.value['min'] as double;
            final max = e.value['max'] as double;
            final progress = goldGrams <= min
                ? 0.0
                : goldGrams >= max
                    ? 1.0
                    : (goldGrams - min) / (max - min);
            return Padding(
              padding: EdgeInsets.only(bottom: e.key < slabs.length - 1 ? 10 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.value['label'] as String,
                          style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                      Text('${min.toStringAsFixed(0)}–${max.toStringAsFixed(0)}g',
                          style: const TextStyle(color: kTextMuted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: kGoldPale,
                      valueColor: const AlwaysStoppedAnimation<Color>(kGold),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _trustBadges() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: kGoldPale,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kGoldBorder.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _badge(Icons.verified_outlined, 'BIS Certified'),
            _badge(Icons.lock_outline, 'Secure'),
            _badge(Icons.local_shipping_outlined, 'Fast Delivery'),
          ],
        ),
      );

  Widget _badge(IconData icon, String label) => Column(
        children: [
          Icon(icon, color: kGold, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 11)),
        ],
      );
}
