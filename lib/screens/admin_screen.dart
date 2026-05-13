import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../services/auth_service.dart';
import '../theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _goldCtrl = TextEditingController();
  final _silverCtrl = TextEditingController();
  final _gold10_24Ctrl = TextEditingController();
  final _gold10_22Ctrl = TextEditingController();
  final _silver10Ctrl = TextEditingController();
  final _silver50Ctrl = TextEditingController();

  static const _rupee = '\u20B9';
  final _tabs = const [
    'Dashboard',
    'Transactions',
    'Users',
    'Orders',
    'Prices',
    'Shop',
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _loadPrices();
  }

  @override
  void dispose() {
    _tab.dispose();
    _goldCtrl.dispose();
    _silverCtrl.dispose();
    _gold10_24Ctrl.dispose();
    _gold10_22Ctrl.dispose();
    _silver10Ctrl.dispose();
    _silver50Ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrices() async {
    final liveDoc = await FirebaseFirestore.instance
        .collection('prices')
        .doc('live')
        .get();
    final rateDoc = await FirebaseFirestore.instance
        .collection('prices')
        .doc('ratecard')
        .get();
    if (!liveDoc.exists) return;
    final data = liveDoc.data()!;
    final rateData = rateDoc.data() ?? {};
    _goldCtrl.text = _asNumber(
      data['gold'],
      fallback: 15500,
    ).toStringAsFixed(0);
    _silverCtrl.text = _asNumber(
      data['silver'],
      fallback: 10000,
    ).toStringAsFixed(0);
    _gold10_24Ctrl.text = _asNumber(rateData['gold10g24k']).toStringAsFixed(0);
    _gold10_22Ctrl.text = _asNumber(rateData['gold10g22k']).toStringAsFixed(0);
    _silver10Ctrl.text = _asNumber(rateData['silver10g']).toStringAsFixed(0);
    _silver50Ctrl.text = _asNumber(rateData['silver50g']).toStringAsFixed(0);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _adminHeader(),
            _tabStrip(),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _dashboardTab(),
                  _transactionsTab(),
                  _usersTab(),
                  _ordersTab(),
                  _pricesTab(),
                  _shopTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminHeader() => Container(
    height: 98,
    padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
    decoration: BoxDecoration(gradient: headerGradient),
    child: Row(
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: const Icon(Icons.star, color: kGoldLight, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ADMIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'DigiGold',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            await AuthService.logout();
            if (!mounted) return;
            context.go('/login');
          },
          icon: const Icon(Icons.logout, size: 16),
          label: const Text('Logout'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _tabStrip() => Container(
    height: 48,
    color: Colors.white,
    child: TabBar(
      controller: _tab,
      isScrollable: true,
      labelColor: kGold,
      unselectedLabelColor: kTextSecondary,
      indicatorColor: kGold,
      indicatorWeight: 1.5,
      labelPadding: const EdgeInsets.symmetric(horizontal: 18),
      tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
    ),
  );

  Widget _dashboardTab() => StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance
        .collection('prices')
        .doc('live')
        .snapshots(),
    builder: (_, priceSnap) {
      final priceData =
          priceSnap.data?.data() as Map<String, dynamic>? ?? {};
      final goldRate = _asNumber(priceData['gold'], fallback: 7200);
      final silverRate = _asNumber(priceData['silver'], fallback: 92);
      final updatedAt = priceData['updatedAt'] as Timestamp?;

      return StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (_, userSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .snapshots(),
            builder: (_, orderSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('transactions')
                    .snapshots(),
                builder: (_, txnSnap) {
                  if (!userSnap.hasData ||
                      !orderSnap.hasData ||
                      !txnSnap.hasData) {
                    return const Center(
                        child:
                            CircularProgressIndicator(color: kGold));
                  }

                  final users = userSnap.data!.docs
                      .map((d) => d.data() as Map<String, dynamic>)
                      .where((u) => u['phone'] != '9999999999')
                      .toList();
                  final orders = orderSnap.data!.docs
                      .map((d) => d.data() as Map<String, dynamic>)
                      .toList();
                  final txnCount = txnSnap.data!.docs.length;

                  final totalGold = users.fold<double>(
                      0, (t, u) => t + _asNumber(u['balanceGrams']));
                  final totalSilver = users.fold<double>(0,
                      (t, u) => t + _asNumber(u['balanceSilverGrams']));
                  final totalWallet = users.fold<double>(
                      0, (t, u) => t + _asNumber(u['walletInr']));
                  final goldValue = totalGold * goldRate;
                  final silverValue = totalSilver * silverRate;
                  final totalValue = goldValue + silverValue + totalWallet;

                  final processing = orders
                      .where((o) => o['status'] == 'processing')
                      .length;
                  final shipped = orders
                      .where((o) => o['status'] == 'shipped')
                      .length;
                  final delivered = orders
                      .where((o) => o['status'] == 'delivered')
                      .length;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live price banner
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: headerGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('LIVE PRICES',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                            'Gold: $_rupee${goldRate.toStringAsFixed(0)}/g',
                                            style: const TextStyle(
                                                color: kGoldLight,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14)),
                                        const SizedBox(width: 16),
                                        Text(
                                            'Silver: $_rupee${silverRate.toStringAsFixed(0)}/g',
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13)),
                                      ],
                                    ),
                                    if (updatedAt != null)
                                      Text(
                                          'Updated: ${_formatDate(updatedAt)}',
                                          style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 10)),
                                  ],
                                ),
                              ),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Summary card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: cardDecoration(),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('TOTAL PLATFORM VALUE',
                                        style: TextStyle(
                                            color: kTextMuted,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 8),
                                    Text(
                                        '$_rupee${NumberFormat('#,##0').format(totalValue)}',
                                        style: const TextStyle(
                                            color: kGold,
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 6),
                                    Text(
                                        'Gold: ${totalGold.toStringAsFixed(2)}g  •  Silver: ${totalSilver.toStringAsFixed(2)}g',
                                        style: const TextStyle(
                                            color: kTextMuted,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              const Text('🏅',
                                  style: TextStyle(fontSize: 32)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Metrics grid
                        GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: [
                            _metricTile('people', 'TOTAL USERS',
                                '${users.length}',
                                const Color(0xFF2563eb)),
                            _metricTile('txn', 'TRANSACTIONS',
                                '$txnCount', kMaroon),
                            _metricTile('order', 'TOTAL ORDERS',
                                '${orders.length}', kGold),
                            _metricTile('timer', 'PROCESSING',
                                '$processing',
                                const Color(0xFFd97706)),
                            _metricTile('truck', 'SHIPPED', '$shipped',
                                const Color(0xFF2563eb)),
                            _metricTile('done', 'DELIVERED',
                                '$delivered',
                                const Color(0xFF138a43)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      );
    },
  );

  Widget _metricTile(String icon, String title, String value, Color color) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(_metricEmoji(icon), style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kTextMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );

  Widget _transactionsTab() => StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('transactions')
        .snapshots(),
    builder: (_, snap) {
      if (!snap.hasData) {
        return const Center(child: CircularProgressIndicator(color: kGold));
      }
      final docs = snap.data!.docs.toList()
        ..sort((a, b) {
          final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
          final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
          if (aTs == null) return 1;
          if (bTs == null) return -1;
          return bTs.compareTo(aTs);
        });
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${docs.length} Transactions',
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9FFF3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle,
                          color: Color(0xFF10b981), size: 8),
                      SizedBox(width: 4),
                      Text('Live',
                          style: TextStyle(
                              color: Color(0xFF047857),
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: docs.isEmpty
                ? const Center(
                    child: Text('No transactions yet',
                        style: TextStyle(color: kTextMuted)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final data =
                          docs[i].data() as Map<String, dynamic>;
                      final isBuy = data['type'] == 'buy';
                      final metal =
                          (data['metal'] ?? '').toString().toUpperCase();
                      final amount = _asNumber(data['amount']);
                      final grams = _asNumber(data['grams']);
                      final rate = _asNumber(data['rate']);
                      final phone = data['phone']?.toString() ?? '';
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: cardDecoration(radius: 14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isBuy
                                  ? const Color(0xFFE4F8E9)
                                  : const Color(0xFFFFE5E5),
                              child: Icon(
                                isBuy
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: isBuy
                                    ? const Color(0xFF138a43)
                                    : const Color(0xFFc62828),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${isBuy ? 'BUY' : 'SELL'} $metal',
                                      style: const TextStyle(
                                          color: kTextPrimary,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13)),
                                  Text(
                                      '+91 $phone',
                                      style: const TextStyle(
                                          color: kTextMuted,
                                          fontSize: 11)),
                                  Text(
                                      '${grams.toStringAsFixed(4)}g @ $_rupee${rate.toStringAsFixed(0)}/g',
                                      style: const TextStyle(
                                          color: kTextMuted,
                                          fontSize: 11)),
                                  Text(
                                      _formatDate(data['createdAt']),
                                      style: const TextStyle(
                                          color: kTextMuted,
                                          fontSize: 10)),
                                ],
                              ),
                            ),
                            Text(
                              '$_rupee${amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: isBuy
                                    ? const Color(0xFF138a43)
                                    : const Color(0xFFc62828),
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    },
  );

  Widget _usersTab() => StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .snapshots(),
    builder: (_, snap) {
      if (!snap.hasData) {
        return const Center(child: CircularProgressIndicator(color: kGold));
      }
      final docs = snap.data!.docs
          .where((doc) =>
              (doc.data() as Map<String, dynamic>)['phone'] != '9999999999')
          .toList()
        ..sort((a, b) {
          final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
          final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
          if (aTs == null) return 1;
          if (bTs == null) return -1;
          return bTs.compareTo(aTs);
        });
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${docs.length} Registered Users',
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: docs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (_, i) =>
                  _userCard(docs[i].data() as Map<String, dynamic>),
            ),
          ),
        ],
      );
    },
  );

  Widget _userCard(Map<String, dynamic> user) {
    final name = (user['name'] ?? 'User').toString();
    final kycTier = (user['kycTier'] ?? 'none').toString();
    final kycLabel = kycTier == 'verified'
        ? 'Verified'
        : kycTier == 'pan_submitted'
            ? 'KYC Submitted'
            : 'Not Verified';
    final kycColor = kycTier == 'verified'
        ? const Color(0xFF138a43)
        : kycTier == 'pan_submitted'
            ? Colors.orange
            : const Color(0xFFd92d20);
    final kycBg = kycTier == 'verified'
        ? const Color(0xFFDDFBE9)
        : kycTier == 'pan_submitted'
            ? const Color(0xFFFFF3CD)
            : const Color(0xFFFFE8E8);
    final walletInr = _asNumber(user['walletInr']);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(radius: 16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: kGold,
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: kTextPrimary,
                            fontWeight: FontWeight.w900)),
                    Text('+91 ${user['phone'] ?? ''}',
                        style:
                            const TextStyle(color: kTextMuted, fontSize: 12)),
                    if ((user['gmail'] ?? '').toString().isNotEmpty)
                      Text(user['gmail'].toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: kTextMuted, fontSize: 11)),
                  ],
                ),
              ),
              _pill(kycLabel, kycColor, kycBg),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _holdingBox(
                  'GOLD',
                  '${_asNumber(user['balanceGrams']).toStringAsFixed(4)}g',
                  kGoldPale,
                  kGold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _holdingBox(
                  'SILVER',
                  '${_asNumber(user['balanceSilverGrams']).toStringAsFixed(4)}g',
                  const Color(0xFFF3F3F3),
                  const Color(0xFF5b5b5b),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _holdingBox(
                  'WALLET',
                  '$_rupee${_compactMoney(walletInr)}',
                  const Color(0xFFDDFBE9),
                  const Color(0xFF138a43),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Joined: ${_formatShortDate(user['createdAt'])}',
                  style: const TextStyle(color: kTextMuted, fontSize: 11)),
              Text('Ref: ${user['referralCode'] ?? ''}',
                  style: const TextStyle(
                      color: kGold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _holdingBox(String label, String value, Color bg, Color valueColor) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: kTextMuted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );

  Widget _ordersTab() => StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('orders')
        .snapshots(),
    builder: (_, snap) {
      if (!snap.hasData) {
        return const Center(child: CircularProgressIndicator(color: kGold));
      }
      final docs = snap.data!.docs.toList()
        ..sort((a, b) {
          final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
          final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
          if (aTs == null) return 1;
          if (bTs == null) return -1;
          return bTs.compareTo(aTs);
        });
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'All Orders',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${docs.length} total',
                  style: const TextStyle(
                    color: kGold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (docs.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFF1E8D8),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Center(
                child: Text(
                  'No order data available yet',
                  style: TextStyle(
                    color: kTextMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return _orderCard(docs[i].reference, data);
                },
              ),
            ),
        ],
      );
    },
  );

  Widget _orderCard(DocumentReference ref, Map<String, dynamic> order) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: cardDecoration(radius: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📦', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order['productLabel'] ?? 'Order',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '$_rupee${_asNumber(order['priceInr']).toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: kGold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              order['addressLine'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: kTextMuted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['processing', 'shipped', 'delivered']
                  .map((status) => _statusAction(ref, order['status'], status))
                  .toList(),
            ),
          ],
        ),
      );

  Widget _statusAction(DocumentReference ref, Object? current, String status) {
    final active = current == status;
    return GestureDetector(
      onTap: () => ref.update({'status': status}),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? kGold : kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kGoldBorder.withValues(alpha: 0.6)),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: active ? Colors.white : kTextMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _pricesTab() => StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance
        .collection('prices')
        .doc('live')
        .snapshots(),
    builder: (_, liveSnap) {
      // Auto-fill fields when Firestore data loads (only if user hasn't typed)
      if (liveSnap.hasData && liveSnap.data!.exists) {
        final d = liveSnap.data!.data() as Map<String, dynamic>;
        if (_goldCtrl.text.isEmpty) {
          _goldCtrl.text = _asNumber(d['gold'], fallback: 7200).toStringAsFixed(0);
        }
        if (_silverCtrl.text.isEmpty) {
          _silverCtrl.text = _asNumber(d['silver'], fallback: 92).toStringAsFixed(0);
        }
      }
      return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live current prices from Firestore
        if (liveSnap.hasData && liveSnap.data!.exists) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: headerGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CURRENT LIVE PRICES',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Gold: $_rupee${_asNumber((liveSnap.data!.data() as Map)['gold'], fallback: 0).toStringAsFixed(0)}/g',
                            style: const TextStyle(
                                color: kGoldLight,
                                fontWeight: FontWeight.w900,
                                fontSize: 16),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            'Silver: $_rupee${_asNumber((liveSnap.data!.data() as Map)['silver'], fallback: 0).toStringAsFixed(0)}/g',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                                fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last updated: ${_formatDate((liveSnap.data!.data() as Map)['updatedAt'])}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        const Text(
          'Update Prices',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter new prices below and tap Save. Users see changes instantly.',
          style: TextStyle(color: kTextMuted, fontSize: 12),
        ),
        const SizedBox(height: 20),
        // Gold input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: cardDecoration(radius: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('🏅', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 8),
                  Text('Gold Price (₹ per gram)',
                      style: TextStyle(
                          color: kTextPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 15)),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _goldCtrl,
                onChanged: (_) => setState(() {}),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Gold price per gram',
                  prefixText: '$_rupee ',
                  fillColor: kGoldPale,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kGoldBorder, width: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Silver input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: cardDecoration(radius: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('🥈', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 8),
                  Text('Silver Price (₹ per gram)',
                      style: TextStyle(
                          color: kTextPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 15)),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _silverCtrl,
                onChanged: (_) => setState(() {}),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Silver price per gram',
                  prefixText: '$_rupee ',
                  fillColor: const Color(0xFFF5F5F5),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Colors.grey.shade400, width: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _rateCardEditor(),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _updatePrices,
            style: ElevatedButton.styleFrom(
              backgroundColor: kGold,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.save_outlined),
            label: const Text(
              'Save & Publish Prices',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ),
        ),
      ],
    ),
  );
    },
  );

  Widget _pricePreview(
    String label,
    TextEditingController controller,
    String sub,
    Color color,
    Color bg,
  ) => Container(
    height: 116,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.55), width: 1.4),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: kTextMuted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$_rupee${_formatController(controller)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(sub, style: const TextStyle(color: kTextMuted, fontSize: 11)),
      ],
    ),
  );

  Widget _metalPriceCard({
    required String medal,
    required String title,
    required TextEditingController controller,
    required Color borderColor,
    String? activeKarat,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: cardDecoration(radius: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(medal, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'PRICE PER GRAM (₹)',
          style: TextStyle(
            color: kTextMuted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Current: ${_formatController(controller)}',
            fillColor: borderColor == kGoldBorder
                ? kGoldPale
                : const Color(0xFFF7F7F7),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1.4),
            ),
          ),
        ),
        if (activeKarat != null) ...[
          const SizedBox(height: 16),
          const Text(
            'KARAT',
            style: TextStyle(
              color: kTextMuted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: ['24K', '22K', '18K']
                .map(
                  (karat) => Expanded(
                    child: Container(
                      height: 44,
                      margin: EdgeInsets.only(right: karat == '18K' ? 0 : 8),
                      decoration: BoxDecoration(
                        color: karat == activeKarat
                            ? kGoldPale
                            : const Color(0xFFF3EDE4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: karat == activeKarat
                              ? kGoldBorder
                              : const Color(0xFFE5DAC9),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          karat,
                          style: const TextStyle(
                            color: kTextMuted,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    ),
  );

  Widget _rateCardEditor() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: cardDecoration(radius: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rate Card',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Shown on user dashboard as weight-based prices',
          style: TextStyle(color: kTextMuted, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _smallPriceInput('GOLD 10G 24K', _gold10_24Ctrl)),
            const SizedBox(width: 12),
            Expanded(child: _smallPriceInput('GOLD 10G 22K', _gold10_22Ctrl)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _smallPriceInput('SILVER 10G', _silver10Ctrl)),
            const SizedBox(width: 12),
            Expanded(child: _smallPriceInput('SILVER 50G', _silver50Ctrl)),
          ],
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _updatePrices,
            style: ElevatedButton.styleFrom(
              backgroundColor: kMaroon,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Save Rate Card'),
          ),
        ),
      ],
    ),
  );

  Widget _smallPriceInput(String label, TextEditingController controller) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: kTextMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter price'),
          ),
        ],
      );

  Widget _shopTab() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Shop Products',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addProductDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('shop_products')
              .snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: kGold),
              );
            }
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'No products yet',
                  style: TextStyle(color: kTextMuted),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: docs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final product = docs[i].data() as Map<String, dynamic>;
                return _productRow(docs[i].reference, product);
              },
            );
          },
        ),
      ),
    ],
  );

  Widget _productRow(DocumentReference ref, Map<String, dynamic> product) {
    final active = product['inStock'] != false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: cardDecoration(radius: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product['name'] ?? 'Product',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _pill(
                      active ? 'In Stock' : 'Hidden',
                      active ? const Color(0xFF138a43) : kTextMuted,
                      active
                          ? const Color(0xFFDDFBE9)
                          : const Color(0xFFEFEFEF),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_asNumber(product['weightGrams']).toStringAsFixed(0)}g · ${product['purity'] ?? ''} · $_rupee${_asNumber(product['priceInr']).toStringAsFixed(0)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: kTextMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: active,
            activeThumbColor: const Color(0xFF138a43),
            onChanged: (value) => ref.update({'inStock': value}),
          ),
          _iconButton(
            Icons.edit_outlined,
            kGold,
            () => _editProductDialog(ref, product),
          ),
          const SizedBox(width: 6),
          _iconButton(
            Icons.delete_outline,
            const Color(0xFFdc2626),
            () => ref.delete(),
          ),
        ],
      ),
    );
  }

  Widget _adminListCard({
    required Widget leading,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) => Container(
    padding: const EdgeInsets.all(12),
    decoration: cardDecoration(radius: 14),
    child: Row(
      children: [
        leading,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: kTextMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        trailing,
      ],
    ),
  );

  Widget _pill(String label, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
    ),
  );

  Widget _iconButton(IconData icon, Color color, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(9),
    child: Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, color: color, size: 18),
    ),
  );

  Future<void> _updatePrices() async {
    final gold = double.tryParse(_goldCtrl.text.trim());
    final silver = double.tryParse(_silverCtrl.text.trim());
    if (gold == null || gold <= 0 || silver == null || silver <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter valid gold and silver prices')));
      return;
    }
    await FirebaseFirestore.instance.collection('prices').doc('live').set({
      'gold': gold,
      'silver': silver,
      'karat': 24,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': 'admin',
    }, SetOptions(merge: true));
    await FirebaseFirestore.instance.collection('prices').doc('ratecard').set({
      'gold10g24k': double.tryParse(_gold10_24Ctrl.text) ?? 0,
      'gold10g22k': double.tryParse(_gold10_22Ctrl.text) ?? 0,
      'silver10g': double.tryParse(_silver10Ctrl.text) ?? 0,
      'silver50g': double.tryParse(_silver50Ctrl.text) ?? 0,
    }, SetOptions(merge: true));
    // Clear so stream auto-refills with saved values
    _goldCtrl.clear();
    _silverCtrl.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Color(0xFF138a43),
            content: Text('✓ Prices updated! Users see new rates now.')));
  }

  void _addProductDialog() => _productDialog();

  void _editProductDialog(
    DocumentReference ref,
    Map<String, dynamic> product,
  ) => _productDialog(ref: ref, product: product);

  void _productDialog({DocumentReference? ref, Map<String, dynamic>? product}) {
    final nameCtrl = TextEditingController(text: product?['name'] ?? '');
    final priceCtrl = TextEditingController(
      text: _fieldText(product?['priceInr']),
    );
    final weightCtrl = TextEditingController(
      text: _fieldText(product?['weightGrams']),
    );
    final purityCtrl = TextEditingController(text: product?['purity'] ?? '');
    int catIdx = 0;
    final cats = ['gold_coin', 'gold_biscuit', 'silver_coin', 'silver_biscuit'];
    final existingCat = product?['category'];
    if (existingCat != null && cats.contains(existingCat)) {
      catIdx = cats.indexOf(existingCat);
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(ref == null ? 'Add Product' : 'Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: catIdx,
                  items: cats
                      .asMap()
                      .entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(_categoryLabel(entry.value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => catIdx = value ?? 0),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: weightCtrl,
                  decoration: const InputDecoration(labelText: 'Weight (g)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: purityCtrl,
                  decoration: const InputDecoration(labelText: 'Purity'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'name': nameCtrl.text.trim(),
                  'category': cats[catIdx],
                  'priceInr': double.tryParse(priceCtrl.text) ?? 0,
                  'weightGrams': double.tryParse(weightCtrl.text) ?? 0,
                  'purity': purityCtrl.text.trim(),
                  'description': product?['description'] ?? '',
                  'inStock': product?['inStock'] ?? true,
                };
                if (ref == null) {
                  await FirebaseFirestore.instance
                      .collection('shop_products')
                      .add(data);
                } else {
                  await ref.update(data);
                }
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
              child: Text(ref == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  double _asNumber(Object? value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  String _fieldText(Object? value) {
    if (value == null) return '';
    if (value is num) return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
    return value.toString();
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'gold_coin':
        return 'Gold Coins';
      case 'gold_biscuit':
        return 'Gold Biscuits';
      case 'silver_coin':
        return 'Silver Coins';
      case 'silver_biscuit':
        return 'Silver Biscuits';
      default:
        return category;
    }
  }

  String _formatController(TextEditingController controller) {
    final value = double.tryParse(controller.text) ?? 0;
    return NumberFormat('#,##0').format(value);
  }

  String _compactMoney(double value) {
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  String _formatDate(Object? timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('dd MMM yyyy, h:mm a').format(timestamp.toDate());
    }
    return 'No date';
  }

  String _formatShortDate(Object? timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('dd MMM yyyy').format(timestamp.toDate());
    }
    return 'Today';
  }

  String _metricEmoji(String icon) {
    switch (icon) {
      case 'people':
        return '👥';
      case 'money':
        return '💰';
      case 'silver':
        return '🥈';
      case 'order':
        return '📦';
      case 'timer':
        return '⏳';
      case 'truck':
        return '🚚';
      case 'done':
        return '✓';
      case 'txn':
        return '↔';
      default:
        return '•';
    }
  }
}
