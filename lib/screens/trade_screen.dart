import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/price_service.dart';

class TradeScreen extends StatefulWidget {
  const TradeScreen({super.key});
  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  int _metal = 0; // 0=gold, 1=silver
  int _action = 0; // 0=buy, 1=sell
  final _amtCtrl = TextEditingController();
  double _goldPrice = PriceService.goldPrice;
  double _silverPrice = PriceService.silverPrice;
  String? _phone;

  double get _price => _metal == 0 ? _goldPrice : _silverPrice;
  double get _grams {
    final amt = double.tryParse(_amtCtrl.text) ?? 0;
    return amt > 0 ? amt / _price : 0;
  }

  @override
  void initState() {
    super.initState();
    _loadPrices();
    _loadPhone();
  }

  Future<void> _loadPhone() async {
    _phone = await AuthService.getPhone();
    if (mounted) setState(() {});
  }

  Future<void> _loadPrices() async {
    await PriceService.fetchPrices();
    setState(() {
      _goldPrice = PriceService.goldPrice;
      _silverPrice = PriceService.silverPrice;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _metalSelector(),
          const SizedBox(height: 16),
          _actionToggle(),
          const SizedBox(height: 16),
          _rateCard(),
          const SizedBox(height: 16),
          _amountInput(),
          const SizedBox(height: 16),
          _quickChips(),
          const SizedBox(height: 24),
          _confirmButton(),
          const SizedBox(height: 24),
          _summaryGrid(),
        ],
      ),
    );
  }

  Widget _metalSelector() => Container(
        decoration: cardDecoration(),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(child: _metalTab('Gold', 0)),
            Expanded(child: _metalTab('Silver', 1)),
          ],
        ),
      );

  Widget _metalTab(String label, int idx) => GestureDetector(
        onTap: () => setState(() => _metal = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: _metal == idx ? goldGradient : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _metal == idx ? Colors.white : kTextMuted)),
        ),
      );

  Widget _actionToggle() => Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _action = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _action == 0 ? const Color(0xFF2e7d32) : kBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kGoldBorder.withValues(alpha: 0.5)),
                ),
                child: Text('Buy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _action == 0 ? Colors.white : kTextMuted)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _action = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _action == 1 ? const Color(0xFFc62828) : kBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kGoldBorder.withValues(alpha: 0.5)),
                ),
                child: Text('Sell',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _action == 1 ? Colors.white : kTextMuted)),
              ),
            ),
          ),
        ],
      );

  Widget _rateCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${_metal == 0 ? 'Gold' : 'Silver'} Rate',
                    style: const TextStyle(color: kTextMuted, fontSize: 13)),
                Text('₹${_price.toStringAsFixed(0)}/g',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary)),
              ],
            ),
            if (_grams > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('You get',
                      style: TextStyle(color: kTextMuted, fontSize: 13)),
                  Text('${_grams.toStringAsFixed(4)} g',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kGold)),
                ],
              ),
          ],
        ),
      );

  Widget _amountInput() => TextField(
        controller: _amtCtrl,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          labelText: 'Amount (₹)',
          prefixText: '₹ ',
          prefixIcon: Icon(Icons.currency_rupee),
        ),
        keyboardType: TextInputType.number,
      );

  Widget _quickChips() => Wrap(
        spacing: 8,
        children: [500, 1000, 2000, 5000].map((amt) {
          return GestureDetector(
            onTap: () {
              _amtCtrl.text = amt.toString();
              setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: kGoldPale,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kGoldBorder),
              ),
              child: Text('₹$amt',
                  style: const TextStyle(
                      color: kTextSecondary, fontWeight: FontWeight.w600)),
            ),
          );
        }).toList(),
      );

  Widget _confirmButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _action == 0 ? const Color(0xFF2e7d32) : const Color(0xFFc62828),
          ),
          onPressed: _confirm,
          child: Text(
              '${_action == 0 ? 'Buy' : 'Sell'} ${_metal == 0 ? 'Gold' : 'Silver'}'),
        ),
      );

  Widget _summaryGrid() => Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Purchase Summary',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                    fontSize: 16)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _phone == null
                  ? const Stream.empty()
                  : FirebaseFirestore.instance
                      .collection('transactions')
                      .where('phone', isEqualTo: _phone)
                      .limit(5)
                      .snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                final docs = snap.data!.docs.toList()
                  ..sort((a, b) {
                    final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
                    final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
                    if (aTs == null) return 1;
                    if (bTs == null) return -1;
                    return bTs.compareTo(aTs);
                  });
                if (docs.isEmpty) {
                  return const Text('No transactions yet',
                      style: TextStyle(color: kTextMuted));
                }
                return Column(
                  children: docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor:
                            data['type'] == 'buy' ? const Color(0xFFe8f5e9) : const Color(0xFFffebee),
                        child: Icon(
                          data['type'] == 'buy'
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: data['type'] == 'buy'
                              ? const Color(0xFF2e7d32)
                              : const Color(0xFFc62828),
                          size: 18,
                        ),
                      ),
                      title: Text(
                          '${data['type']?.toString().toUpperCase()} ${data['metal']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('${data['grams']?.toStringAsFixed(4)} g',
                          style: const TextStyle(color: kTextMuted, fontSize: 12)),
                      trailing: Text('₹${data['amount']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: kTextPrimary)),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      );

  void _confirm() async {
    final amt = double.tryParse(_amtCtrl.text);
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter valid amount')));
      return;
    }
    final phone = await AuthService.getPhone();
    if (phone == null) return;
    final grams = amt / _price;
    final metal = _metal == 0 ? 'gold' : 'silver';
    final field = _metal == 0 ? 'balanceGrams' : 'balanceSilverGrams';

    await FirebaseFirestore.instance.collection('transactions').add({
      'phone': phone,
      'type': _action == 0 ? 'buy' : 'sell',
      'metal': metal,
      'amount': amt,
      'grams': grams,
      'rate': _price,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('users').doc(phone).update({
      field: FieldValue.increment(_action == 0 ? grams : -grams),
    });

    if (!mounted) return;
    _amtCtrl.clear();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${_action == 0 ? 'Bought' : 'Sold'} ${grams.toStringAsFixed(4)}g of $metal')));
  }
}
