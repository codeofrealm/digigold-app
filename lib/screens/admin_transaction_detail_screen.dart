import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';

class AdminTransactionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> txn;
  const AdminTransactionDetailScreen({super.key, required this.txn});

  static const _rupee = '\u20B9';

  @override
  Widget build(BuildContext context) {
    final isBuy = txn['type'] == 'buy';
    final metal = (txn['metal'] ?? '').toString().toUpperCase();
    final amount = _asNum(txn['amount']);
    final grams = _asNum(txn['grams']);
    final rate = _asNum(txn['rate']);
    final phone = (txn['phone'] ?? '').toString();
    final typeColor = isBuy ? const Color(0xFF138a43) : const Color(0xFFc62828);
    final typeBg = isBuy ? const Color(0xFFE4F8E9) : const Color(0xFFFFE5E5);

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // App Bar
          Container(
            decoration: BoxDecoration(gradient: headerGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                    ),
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: typeBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                        color: typeColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${isBuy ? 'BUY' : 'SELL'} $metal',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900),
                          ),
                          Text('+91 $phone',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: typeBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_rupee${amount.toStringAsFixed(0)}',
                        style: TextStyle(
                            color: typeColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Amount hero card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: headerGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isBuy ? 'BOUGHT' : 'SOLD',
                          style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_rupee${NumberFormat('#,##0').format(amount)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${grams.toStringAsFixed(4)}g of $metal',
                          style: const TextStyle(
                              color: kGoldLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Details card
                  Container(
                    decoration: cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                          child: Text('Transaction Details',
                              style: TextStyle(
                                  color: kTextPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14)),
                        ),
                        const Divider(height: 1, color: Color(0xFFf0e8d0)),
                        _detailRow(Icons.swap_horiz, 'Type',
                            isBuy ? 'Buy' : 'Sell', typeColor),
                        _divider(),
                        _detailRow(Icons.monetization_on_outlined, 'Metal',
                            metal, kGold),
                        _divider(),
                        _detailRow(Icons.currency_rupee, 'Amount',
                            '$_rupee${NumberFormat('#,##0').format(amount)}',
                            kTextPrimary),
                        _divider(),
                        _detailRow(Icons.scale_outlined, 'Quantity',
                            '${grams.toStringAsFixed(6)} grams', kTextPrimary),
                        _divider(),
                        _detailRow(Icons.price_change_outlined, 'Rate',
                            '$_rupee${rate.toStringAsFixed(0)} / gram',
                            kTextPrimary),
                        _divider(),
                        _detailRow(Icons.phone_outlined, 'User Phone',
                            '+91 $phone', kTextPrimary),
                        _divider(),
                        _detailRow(Icons.calendar_today_outlined, 'Date & Time',
                            _formatDate(txn['createdAt']), kTextPrimary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User quick info
                  _userInfoCard(phone),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color valueColor) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: kGold, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(color: kTextMuted, fontSize: 13)),
            ),
            Text(value,
                style: TextStyle(
                    color: valueColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
          ],
        ),
      );

  Widget _divider() =>
      const Divider(height: 1, indent: 46, color: Color(0xFFf0e8d0));

  Widget _userInfoCard(String phone) => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(phone)
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData || !snap.data!.exists) return const SizedBox();
          final u = snap.data!.data() as Map<String, dynamic>;
          final name = (u['name'] ?? 'User').toString();
          final gmail = (u['gmail'] ?? '').toString();
          final gold = _asNum(u['balanceGrams']);
          final silver = _asNum(u['balanceSilverGrams']);
          final wallet = _asNum(u['walletInr']);
          return Container(
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text('User Info',
                      style: TextStyle(
                          color: kTextPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 14)),
                ),
                const Divider(height: 1, color: Color(0xFFf0e8d0)),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: kGold,
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w900)),
                  ),
                  title: Text(name,
                      style: const TextStyle(
                          color: kTextPrimary, fontWeight: FontWeight.w900)),
                  subtitle: Text(gmail.isNotEmpty ? gmail : '+91 $phone',
                      style: const TextStyle(color: kTextMuted, fontSize: 12)),
                ),
                const Divider(height: 1, color: Color(0xFFf0e8d0)),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(child: _balChip('🏅 Gold', '${gold.toStringAsFixed(4)}g', kGoldPale, kGold)),
                      const SizedBox(width: 8),
                      Expanded(child: _balChip('🥈 Silver', '${silver.toStringAsFixed(4)}g', const Color(0xFFF3F3F3), const Color(0xFF5b5b5b))),
                      const SizedBox(width: 8),
                      Expanded(child: _balChip('💰 Wallet', '$_rupee${wallet.toStringAsFixed(0)}', const Color(0xFFDDFBE9), const Color(0xFF138a43))),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

  Widget _balChip(String label, String value, Color bg, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w900)),
          ],
        ),
      );

  double _asNum(Object? v, {double fallback = 0}) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  String _formatDate(Object? ts) {
    if (ts is Timestamp) {
      return DateFormat('dd MMM yyyy, h:mm a').format(ts.toDate());
    }
    return '—';
  }
}
