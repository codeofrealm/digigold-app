import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../services/auth_service.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});
  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String? _phone;
  bool _sipEnabled = false;
  int _sipFreq = 0;
  final _sipAmtCtrl = TextEditingController();
  final _giftNameCtrl = TextEditingController();
  final _giftGramsCtrl = TextEditingController();
  final _deliveryAddrCtrl = TextEditingController();
  final _deliveryGramsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    AuthService.getPhone().then((p) => setState(() => _phone = p));
  }

  @override
  void dispose() {
    _tab.dispose();
    _sipAmtCtrl.dispose();
    _giftNameCtrl.dispose();
    _giftGramsCtrl.dispose();
    _deliveryAddrCtrl.dispose();
    _deliveryGramsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tab,
            labelColor: kGold,
            unselectedLabelColor: kTextMuted,
            indicatorColor: kGold,
            tabs: const [
              Tab(text: 'Auto SIP'),
              Tab(text: 'Gift'),
              Tab(text: 'Delivery'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [_sipTab(), _giftTab(), _deliveryTab()],
          ),
        ),
      ],
    );
  }

  Widget _sipTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: cardDecoration(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Auto SIP',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kTextPrimary,
                              fontSize: 16)),
                      Text('Automatic gold investment',
                          style: TextStyle(color: kTextMuted, fontSize: 12)),
                    ],
                  ),
                  Switch(
                    value: _sipEnabled,
                    activeThumbColor: kGold,
                    onChanged: (v) => setState(() => _sipEnabled = v),
                  ),
                ],
              ),
            ),
            if (_sipEnabled) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Frequency',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: kTextPrimary)),
                    const SizedBox(height: 12),
                    Row(
                      children: ['Daily', 'Weekly', 'Monthly']
                          .asMap()
                          .entries
                          .map((e) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _sipFreq = e.key),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: _sipFreq == e.key
                                          ? goldGradient
                                          : null,
                                      color: _sipFreq == e.key ? null : kBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: kGoldBorder
                                              .withValues(alpha: 0.5)),
                                    ),
                                    child: Text(e.value,
                                        style: TextStyle(
                                            color: _sipFreq == e.key
                                                ? Colors.white
                                                : kTextSecondary,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _sipAmtCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Amount (₹)', prefixText: '₹ '),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveSip,
                        child: const Text('Activate SIP'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _plansList('sip'),
          ],
        ),
      );

  Widget _giftTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gift Gold',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                          fontSize: 16)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _giftNameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Recipient Name',
                        prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _giftGramsCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Grams', suffixText: 'g'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sendGift,
                      child: const Text('Send Gift'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _plansList('gift'),
          ],
        ),
      );

  Widget _deliveryTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Request Delivery',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                          fontSize: 16)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _deliveryGramsCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Grams to deliver', suffixText: 'g'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _deliveryAddrCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Delivery Address',
                        prefixIcon: Icon(Icons.location_on_outlined)),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _requestDelivery,
                      child: const Text('Request Delivery'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _plansList('delivery'),
          ],
        ),
      );

  // Filter by phone + type only — sort client-side (no composite index needed)
  Widget _plansList(String type) {
    if (_phone == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('plans')
          .where('phone', isEqualTo: _phone)
          .where('type', isEqualTo: type)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const SizedBox.shrink();
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
            const Text('My Plans',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                    fontSize: 15)),
            const SizedBox(height: 8),
            ...docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              final ts = data['createdAt'] as Timestamp?;
              final date = ts != null
                  ? DateFormat('dd MMM yyyy').format(ts.toDate())
                  : '';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: cardDecoration(radius: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['details'] ?? '',
                              style: const TextStyle(
                                  color: kTextPrimary,
                                  fontWeight: FontWeight.w600)),
                          if (date.isNotEmpty)
                            Text(date,
                                style: const TextStyle(
                                    color: kTextMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                    _statusBadge(data['status'] ?? 'pending'),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _statusBadge(String status) {
    const colors = {
      'pending': Colors.orange,
      'active': Color(0xFF2e7d32),
      'completed': kGold,
      'cancelled': Color(0xFFc62828),
    };
    final color = colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  void _saveSip() async {
    final amt = double.tryParse(_sipAmtCtrl.text);
    if (amt == null || amt <= 0) return;
    final freqs = ['daily', 'weekly', 'monthly'];
    await FirebaseFirestore.instance.collection('plans').add({
      'phone': _phone,
      'type': 'sip',
      'amount': amt,
      'frequency': freqs[_sipFreq],
      'details': '₹${amt.toStringAsFixed(0)} ${freqs[_sipFreq]}',
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    _sipAmtCtrl.clear();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('SIP activated!')));
  }

  void _sendGift() async {
    final name = _giftNameCtrl.text.trim();
    final grams = double.tryParse(_giftGramsCtrl.text);
    if (name.isEmpty || grams == null || grams <= 0) return;
    await FirebaseFirestore.instance.collection('plans').add({
      'phone': _phone,
      'type': 'gift',
      'recipient': name,
      'grams': grams,
      'details': '${grams.toStringAsFixed(4)}g to $name',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    _giftNameCtrl.clear();
    _giftGramsCtrl.clear();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Gift sent!')));
  }

  void _requestDelivery() async {
    final grams = double.tryParse(_deliveryGramsCtrl.text);
    final addr = _deliveryAddrCtrl.text.trim();
    if (grams == null || grams <= 0 || addr.isEmpty) return;
    await FirebaseFirestore.instance.collection('plans').add({
      'phone': _phone,
      'type': 'delivery',
      'grams': grams,
      'address': addr,
      'details': '${grams.toStringAsFixed(4)}g → $addr',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    _deliveryGramsCtrl.clear();
    _deliveryAddrCtrl.clear();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Delivery requested!')));
  }
}
