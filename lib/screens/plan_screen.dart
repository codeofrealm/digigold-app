import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/price_service.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});
  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String? _phone;
  double _walletInr = 0;

  // SIP step-by-step state
  final _sipAmtCtrl = TextEditingController();
  final _sipGramsCtrl = TextEditingController();
  int _sipKarat = 24;
  int _sipFreq = 0; // 0=Daily, 1=Weekly, 2=Monthly

  final _giftNameCtrl = TextEditingController();
  final _giftGramsCtrl = TextEditingController();
  final _deliveryAddrCtrl = TextEditingController();
  final _deliveryGramsCtrl = TextEditingController();

  double get _goldPrice => PriceService.goldPrice;
  double get _enteredAmt => double.tryParse(_sipAmtCtrl.text) ?? 0;
  double get _enteredGrams => double.tryParse(_sipGramsCtrl.text) ?? 0;

  // karat multiplier vs 24K
  double _karatFactor(int k) => k == 22 ? 22 / 24 : k == 18 ? 18 / 24 : 1.0;
  double get _effectivePrice => _goldPrice * _karatFactor(_sipKarat);

  // per-period grams
  double get _gramsPerPeriod =>
      _enteredGrams > 0 ? _enteredGrams : (_effectivePrice > 0 ? _enteredAmt / _effectivePrice : 0);

  // multiplier to monthly
  int get _freqMultiplier => [30, 4, 1][_sipFreq];
  String get _freqLabel => ['Daily', 'Weekly', 'Monthly'][_sipFreq];

  double get _monthlyAmt => _enteredAmt * _freqMultiplier;
  double get _monthlyGrams => _gramsPerPeriod * _freqMultiplier;
  double get _yearlyGrams => _monthlyGrams * 12;

  // balance after monthly deduction
  double get _balanceAfter => _walletInr - _monthlyAmt;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    AuthService.getPhone().then((p) async {
      setState(() => _phone = p);
      if (p != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(p).get();
        if (mounted) {
          setState(() => _walletInr = (doc.data()?['walletInr'] ?? 0).toDouble());
        }
      }
    });
    PriceService.fetchPrices();
  }

  @override
  void dispose() {
    _tab.dispose();
    _sipAmtCtrl.dispose();
    _sipGramsCtrl.dispose();
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

  Widget _sipTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: goldGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('💰', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gold Savings Plan',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Wallet: ₹${_walletInr.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Step-by-step form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step 1: Amount
                const Text('1. Enter Amount (₹)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: kTextPrimary)),
                const SizedBox(height: 10),
                TextField(
                  controller: _sipAmtCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Amount', prefixText: '₹ '),
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    setState(() {
                      if (_enteredAmt > 0 && _effectivePrice > 0) {
                        _sipGramsCtrl.text = (_enteredAmt / _effectivePrice).toStringAsFixed(4);
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Step 2: Grams
                const Text('2. Gold Grams (auto-calculated)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: kTextPrimary)),
                const SizedBox(height: 10),
                TextField(
                  controller: _sipGramsCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Grams', suffixText: 'g'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Step 3: Karat
                const Text('3. Select Karat',
                    style: TextStyle(fontWeight: FontWeight.bold, color: kTextPrimary)),
                const SizedBox(height: 10),
                Row(
                  children: [24, 22, 18].map((k) {
                    final selected = _sipKarat == k;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _sipKarat = k;
                            if (_enteredAmt > 0 && _effectivePrice > 0) {
                              _sipGramsCtrl.text = (_enteredAmt / _effectivePrice).toStringAsFixed(4);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: selected ? goldGradient : null,
                            color: selected ? null : kBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kGoldBorder.withValues(alpha: 0.5)),
                          ),
                          child: Text('${k}K',
                              style: TextStyle(
                                  color: selected ? Colors.white : kTextSecondary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Step 4: Frequency
                const Text('4. Select Frequency',
                    style: TextStyle(fontWeight: FontWeight.bold, color: kTextPrimary)),
                const SizedBox(height: 10),
                Row(
                  children: ['Daily', 'Weekly', 'Monthly'].asMap().entries.map((e) {
                    final selected = _sipFreq == e.key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _sipFreq = e.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: selected ? goldGradient : null,
                            color: selected ? null : kBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kGoldBorder.withValues(alpha: 0.5)),
                          ),
                          child: Text(e.value,
                              style: TextStyle(
                                  color: selected ? Colors.white : kTextSecondary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Preview
                if (_enteredAmt > 0 || _enteredGrams > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kGoldPale,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kGoldBorder.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Per $_freqLabel',
                                style: const TextStyle(color: kTextMuted, fontSize: 12)),
                            Text('₹${_enteredAmt.toStringAsFixed(0)} → ${_gramsPerPeriod.toStringAsFixed(4)}g',
                                style: const TextStyle(
                                    color: kGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Monthly',
                                style: TextStyle(color: kTextMuted, fontSize: 12)),
                            Text('₹${_monthlyAmt.toStringAsFixed(0)} → ${_monthlyGrams.toStringAsFixed(4)}g',
                                style: const TextStyle(
                                    color: kTextPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Yearly',
                                style: TextStyle(color: kTextMuted, fontSize: 12)),
                            Text('≈ ${_yearlyGrams.toStringAsFixed(4)}g',
                                style: const TextStyle(
                                    color: kMaroon,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Wallet after monthly deduction',
                                style: TextStyle(color: kTextMuted, fontSize: 11)),
                            Text('₹${_balanceAfter.toStringAsFixed(0)}',
                                style: TextStyle(
                                    color: _balanceAfter >= 0 ? kGold : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _enteredAmt > 0 ? _saveSip : null,
                    child: const Text('Activate SIP'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _plansList('sip'),
        ],
      ),
    );
  }

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

  // Gold reach date: how many periods until user accumulates targetGrams
  String _goldReachDate(Map<String, dynamic> data) {
    final amt = (data['amount'] ?? 0).toDouble();
    final freq = data['frequency'] ?? 'monthly';
    final price = _goldPrice > 0 ? _goldPrice : 1;
    final gramsPerPeriod = amt / price;
    if (gramsPerPeriod <= 0) return '-';
    // target = 1g (standard milestone)
    const target = 1.0;
    final periods = (target / gramsPerPeriod).ceil();
    final now = DateTime.now();
    DateTime reach;
    if (freq == 'daily') {
      reach = now.add(Duration(days: periods));
    } else if (freq == 'weekly') {
      reach = now.add(Duration(days: periods * 7));
    } else {
      reach = DateTime(now.year, now.month + periods, now.day);
    }
    return DateFormat('dd MMM yyyy').format(reach);
  }

  Future<void> _exportSipExcel(List<QueryDocumentSnapshot> docs) async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['SIP Plans'];
    final headers = ['Phone', 'Amount (₹)', 'Frequency', 'Grams/Period', '1g Reach Date', 'Status', 'Created At'];
    sheet.appendRow(headers.map((h) => xl.TextCellValue(h)).toList());
    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>;
      final ts = data['createdAt'] as Timestamp?;
      final date = ts != null ? DateFormat('dd MMM yyyy').format(ts.toDate()) : '';
      final amt = (data['amount'] ?? 0).toDouble();
      final price = _goldPrice > 0 ? _goldPrice : 1;
      final gramsPerPeriod = amt / price;
      sheet.appendRow([
        xl.TextCellValue(data['phone'] ?? ''),
        xl.DoubleCellValue(amt),
        xl.TextCellValue(data['frequency'] ?? ''),
        xl.TextCellValue(gramsPerPeriod.toStringAsFixed(4)),
        xl.TextCellValue(_goldReachDate(data)),
        xl.TextCellValue(data['status'] ?? ''),
        xl.TextCellValue(date),
      ]);
    }
    final bytes = excel.encode()!;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/sip_plans_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx');
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My Plans',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary,
                        fontSize: 15)),
                if (type == 'sip')
                  TextButton.icon(
                    onPressed: () => _exportSipExcel(docs),
                    icon: const Icon(Icons.download, size: 16, color: kGold),
                    label: const Text('Excel',
                        style: TextStyle(color: kGold, fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              final ts = data['createdAt'] as Timestamp?;
              final date = ts != null
                  ? DateFormat('dd MMM yyyy').format(ts.toDate())
                  : '';
              return GestureDetector(
                onTap: type == 'sip'
                    ? () => context.push('/sip_detail',
                        extra: {'data': data, 'id': d.id})
                    : null,
                child: Container(
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
                            if (type == 'sip')
                              Text('🏅 1g reach: ${_goldReachDate(data)}',
                                  style: const TextStyle(
                                      color: kGold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      _statusBadge(data['status'] ?? 'pending'),
                    ],
                  ),
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
    _sipGramsCtrl.clear();
    setState(() {});
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
