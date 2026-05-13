import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../services/auth_service.dart';

class PassbookScreen extends StatefulWidget {
  const PassbookScreen({super.key});
  @override
  State<PassbookScreen> createState() => _PassbookScreenState();
}

class _PassbookScreenState extends State<PassbookScreen> {
  String? _phone;

  @override
  void initState() {
    super.initState();
    AuthService.getPhone().then((p) => setState(() => _phone = p));
  }

  @override
  Widget build(BuildContext context) {
    if (_phone == null) {
      return const Center(child: CircularProgressIndicator(color: kGold));
    }
    return StreamBuilder<QuerySnapshot>(
      // Filter by phone only — sort client-side to avoid composite index
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('phone', isEqualTo: _phone)
          .snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kGold));
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book_outlined, size: 64, color: kTextMuted),
                SizedBox(height: 12),
                Text('No transactions yet',
                    style: TextStyle(color: kTextMuted, fontSize: 16)),
              ],
            ),
          );
        }

        // Sort client-side by createdAt descending
        final docs = snap.data!.docs.toList()
          ..sort((a, b) {
            final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
            final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return bTs.compareTo(aTs);
          });

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final isBuy = data['type'] == 'buy';
            final ts = data['createdAt'] as Timestamp?;
            final date = ts != null
                ? DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate())
                : 'Processing...';
            final metal = (data['metal'] ?? '').toString().toUpperCase();
            final grams = (data['grams'] ?? 0.0).toDouble();
            final rate = (data['rate'] ?? 0.0).toDouble();
            final amount = (data['amount'] ?? 0.0).toDouble();

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: cardDecoration(radius: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isBuy
                          ? const Color(0xFFe8f5e9)
                          : const Color(0xFFffebee),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isBuy
                          ? const Color(0xFF2e7d32)
                          : const Color(0xFFc62828),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${isBuy ? 'Bought' : 'Sold'} $metal',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kTextPrimary),
                        ),
                        Text(
                          '${grams.toStringAsFixed(4)}g @ ₹${rate.toStringAsFixed(0)}/g',
                          style: const TextStyle(
                              color: kTextMuted, fontSize: 12),
                        ),
                        Text(date,
                            style: const TextStyle(
                                color: kTextMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(
                    '${isBuy ? '-' : '+'}₹${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isBuy
                          ? const Color(0xFFc62828)
                          : const Color(0xFF2e7d32),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
