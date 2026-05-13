import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';

class AdminUserDetailScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  const AdminUserDetailScreen({super.key, required this.user});

  static const _rupee = '\u20B9';

  @override
  Widget build(BuildContext context) {
    final name = (user['name'] ?? 'User').toString();
    final phone = (user['phone'] ?? '').toString();
    final gmail = (user['gmail'] ?? '').toString();
    final kycTier = (user['kycTier'] ?? 'none').toString();
    final role = (user['role'] ?? 'user').toString();
    final gold = _asNum(user['balanceGrams']);
    final silver = _asNum(user['balanceSilverGrams']);
    final wallet = _asNum(user['walletInr']);
    final bankName = (user['bankName'] ?? '').toString();
    final bankAccount = (user['bankAccount'] ?? '').toString();
    final ifsc = (user['ifsc'] ?? '').toString();
    final addressLine = (user['addressLine'] ?? '').toString();
    final city = (user['city'] ?? '').toString();
    final pincode = (user['pincode'] ?? '').toString();
    final referralCode = (user['referralCode'] ?? '').toString();
    final panUrl = (user['panUrl'] ?? '').toString();
    final aadhaarUrl = (user['aadhaarUrl'] ?? '').toString();

    final kycLabel = kycTier == 'verified'
        ? 'Verified ✓'
        : kycTier == 'pan_submitted'
            ? 'Under Review'
            : 'Not Submitted';
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

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // ── App Bar ──────────────────────────────────────────────────────
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
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900)),
                          Text('+91 $phone',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: kycBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(kycLabel,
                          style: TextStyle(
                              color: kycColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Holdings
                  Row(
                    children: [
                      Expanded(child: _holdingCard('🏅 GOLD', '${gold.toStringAsFixed(4)}g',
                          '$_rupee${NumberFormat('#,##0').format(gold * 0)}', kGoldPale, kGold)),
                      const SizedBox(width: 10),
                      Expanded(child: _holdingCard('🥈 SILVER', '${silver.toStringAsFixed(4)}g',
                          '', const Color(0xFFF3F3F3), const Color(0xFF5b5b5b))),
                      const SizedBox(width: 10),
                      Expanded(child: _holdingCard('💰 WALLET', '$_rupee${wallet.toStringAsFixed(0)}',
                          '', const Color(0xFFDDFBE9), const Color(0xFF138a43))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Profile Info
                  _sectionCard('Profile', [
                    _row(Icons.person_outline, 'Name', name),
                    _row(Icons.phone_outlined, 'Phone', '+91 $phone'),
                    if (gmail.isNotEmpty) _row(Icons.email_outlined, 'Gmail', gmail),
                    _row(Icons.shield_outlined, 'Role', role.toUpperCase()),
                    _row(Icons.card_giftcard_outlined, 'Referral', referralCode),
                    _row(Icons.calendar_today_outlined, 'Joined',
                        _formatDate(user['createdAt'])),
                  ]),
                  const SizedBox(height: 12),

                  // Bank Details
                  _sectionCard('Bank Details', [
                    _row(Icons.account_balance_outlined, 'Bank',
                        bankName.isEmpty ? '—' : bankName),
                    _row(Icons.credit_card_outlined, 'Account',
                        bankAccount.isEmpty ? '—' : '••••${bankAccount.length > 4 ? bankAccount.substring(bankAccount.length - 4) : bankAccount}'),
                    _row(Icons.code, 'IFSC', ifsc.isEmpty ? '—' : ifsc),
                  ]),
                  const SizedBox(height: 12),

                  // Address
                  _sectionCard('Delivery Address', [
                    _row(Icons.location_on_outlined, 'Address',
                        addressLine.isEmpty ? '—' : addressLine),
                    _row(Icons.location_city_outlined, 'City / PIN',
                        city.isEmpty && pincode.isEmpty ? '—' : '$city - $pincode'),
                  ]),
                  const SizedBox(height: 12),

                  // KYC Documents
                  _kycCard(context, panUrl, aadhaarUrl),
                  const SizedBox(height: 12),

                  // Transactions
                  _transactionsSection(phone),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _holdingCard(String label, String value, String sub, Color bg, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w900)),
          ],
        ),
      );

  Widget _sectionCard(String title, List<Widget> rows) => Container(
        decoration: cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Text(title,
                  style: const TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 14)),
            ),
            const Divider(height: 1, color: Color(0xFFf0e8d0)),
            ...rows,
          ],
        ),
      );

  Widget _row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: kGold, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: kTextMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _kycCard(BuildContext context, String panUrl, String aadhaarUrl) =>
      Container(
        decoration: cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Text('KYC Documents',
                  style: TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 14)),
            ),
            const Divider(height: 1, color: Color(0xFFf0e8d0)),
            _kycDocRow(context, 'PAN Card', Icons.credit_card, panUrl),
            const Divider(height: 1, color: Color(0xFFf0e8d0)),
            _kycDocRow(context, 'Aadhaar Card', Icons.badge_outlined, aadhaarUrl),
          ],
        ),
      );

  Widget _kycDocRow(
      BuildContext context, String label, IconData icon, String base64Str) =>
      ListTile(
        leading: Icon(icon, color: kGold),
        title: Text(label,
            style: const TextStyle(color: kTextPrimary, fontSize: 13)),
        subtitle: Text(
          base64Str.isNotEmpty ? 'Uploaded ✓' : 'Not uploaded',
          style: TextStyle(
              color: base64Str.isNotEmpty
                  ? const Color(0xFF138a43)
                  : kTextMuted,
              fontSize: 11),
        ),
        trailing: base64Str.isNotEmpty
            ? GestureDetector(
                onTap: () => _viewImage(context, base64Str, label),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: goldGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.visibility_outlined,
                      color: Colors.white, size: 18),
                ),
              )
            : const Icon(Icons.remove_circle_outline,
                color: kTextMuted, size: 20),
      );

  void _viewImage(BuildContext context, String base64Str, String label) {
    final bytes = base64Decode(base64Str);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, color: kTextPrimary)),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop()),
                ],
              ),
            ),
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transactionsSection(String phone) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('phone', isEqualTo: phone)
            .snapshots(),
        builder: (_, snap) {
          final docs = snap.data?.docs ?? [];
          docs.sort((a, b) {
            final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
            final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return bTs.compareTo(aTs);
          });
          return Container(
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Transactions',
                          style: TextStyle(
                              color: kTextPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 14)),
                      Text('${docs.length} total',
                          style: const TextStyle(
                              color: kGold,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFf0e8d0)),
                if (docs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No transactions yet',
                        style: TextStyle(color: kTextMuted)),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFf0e8d0)),
                    itemBuilder: (_, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final isBuy = d['type'] == 'buy';
                      final metal =
                          (d['metal'] ?? '').toString().toUpperCase();
                      final amount = _asNum(d['amount']);
                      final grams = _asNum(d['grams']);
                      final rate = _asNum(d['rate']);
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
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
                            size: 14,
                          ),
                        ),
                        title: Text(
                          '${isBuy ? 'BUY' : 'SELL'} $metal',
                          style: const TextStyle(
                              color: kTextPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 13),
                        ),
                        subtitle: Text(
                          '${grams.toStringAsFixed(4)}g @ $_rupee${rate.toStringAsFixed(0)}/g  •  ${_formatDate(d['createdAt'])}',
                          style: const TextStyle(
                              color: kTextMuted, fontSize: 11),
                        ),
                        trailing: Text(
                          '$_rupee${amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: isBuy
                                ? const Color(0xFF138a43)
                                : const Color(0xFFc62828),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      );

  double _asNum(Object? v, {double fallback = 0}) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  String _formatDate(Object? ts) {
    if (ts is Timestamp) {
      return DateFormat('dd MMM yyyy').format(ts.toDate());
    }
    return '—';
  }
}
