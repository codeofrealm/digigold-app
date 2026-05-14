import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../services/auth_service.dart';

class AutoPayScreen extends StatefulWidget {
  final Map<String, dynamic> sipData;
  final String sipId;
  const AutoPayScreen({super.key, required this.sipData, required this.sipId});

  @override
  State<AutoPayScreen> createState() => _AutoPayScreenState();
}

class _AutoPayScreenState extends State<AutoPayScreen> {
  final _bankNameCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();

  bool _autoPayEnabled = false;
  bool _saving = false;
  bool _paying = false;
  int _payMethod = 0; // 0=Bank, 1=GPay
  String? _phone;
  double _walletInr = 0;

  double get _amt => (widget.sipData['amount'] ?? 0).toDouble();
  String get _freq => widget.sipData['frequency'] ?? 'monthly';
  String get _freqLabel => _freq[0].toUpperCase() + _freq.substring(1);

  // Calculate all due dates from createdAt until today+3 periods ahead
  List<DateTime> get _schedule {
    final ts = widget.sipData['createdAt'];
    if (ts == null) return [];
    final start = (ts as dynamic).toDate() as DateTime;
    final now = DateTime.now();
    final dates = <DateTime>[];
    DateTime cursor = start;
    // go up to 3 periods in the future
    final limit = _addPeriod(now, 3);
    while (!cursor.isAfter(limit)) {
      dates.add(cursor);
      cursor = _addPeriod(cursor, 1);
    }
    return dates;
  }

  DateTime _addPeriod(DateTime d, int n) {
    if (_freq == 'daily') return d.add(Duration(days: n));
    if (_freq == 'weekly') return d.add(Duration(days: 7 * n));
    return DateTime(d.year, d.month + n, d.day);
  }

  DateTime? get _nextDueDate {
    final now = DateTime.now();
    for (final d in _schedule) {
      if (d.isAfter(now) || _isSameDay(d, now)) return d;
    }
    return null;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isPaid(DateTime dueDate, List<Map<String, dynamic>> payments) {
    return payments.any((p) {
      final ts = p['createdAt'];
      if (ts == null) return false;
      final pd = (ts as dynamic).toDate() as DateTime;
      return _isSameDay(pd, dueDate) ||
          (pd.isAfter(dueDate.subtract(const Duration(hours: 12))) &&
              pd.isBefore(dueDate.add(const Duration(hours: 36))));
    });
  }

  @override
  void initState() {
    super.initState();
    _autoPayEnabled = widget.sipData['autoPayEnabled'] ?? false;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _phone = await AuthService.getPhone();
    if (_phone == null || !mounted) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(_phone).get();
    final data = doc.data();
    if (data != null && mounted) {
      setState(() {
        _walletInr = (data['walletInr'] ?? 0).toDouble();
        _bankNameCtrl.text = data['bankName'] ?? '';
        _accountCtrl.text = data['bankAccount'] ?? '';
        _ifscCtrl.text = data['ifsc'] ?? '';
      });
    }
  }

  Future<void> _saveAndEnableAutoPay() async {
    final bankName = _bankNameCtrl.text.trim();
    final account = _accountCtrl.text.trim();
    final ifsc = _ifscCtrl.text.trim();
    if (bankName.isEmpty || account.isEmpty || ifsc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all bank details')));
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(_phone).update({
        'bankName': bankName,
        'bankAccount': account,
        'ifsc': ifsc,
      });
      await FirebaseFirestore.instance.collection('plans').doc(widget.sipId).update({
        'autoPayEnabled': true,
        'payMethod': _payMethod == 0 ? 'bank' : 'gpay',
      });
      if (!mounted) return;
      setState(() => _autoPayEnabled = true);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Auto Pay enabled!')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _disableAutoPay() async {
    await FirebaseFirestore.instance
        .collection('plans')
        .doc(widget.sipId)
        .update({'autoPayEnabled': false});
    if (mounted) setState(() => _autoPayEnabled = false);
  }

  Future<void> _payNow() async {
    if (_walletInr < _amt) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Insufficient wallet balance')));
      return;
    }
    setState(() => _paying = true);
    try {
      final method = _payMethod == 0 ? 'bank' : 'gpay';
      // Deduct from wallet
      await FirebaseFirestore.instance.collection('users').doc(_phone).update({
        'walletInr': FieldValue.increment(-_amt),
      });
      // Record payment
      await FirebaseFirestore.instance.collection('transactions').add({
        'phone': _phone,
        'type': 'sip_payment',
        'metal': 'gold',
        'amount': _amt,
        'payMethod': method,
        'sipId': widget.sipId,
        'status': 'success',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('plans').doc(widget.sipId).update({
        'lastPaidAt': FieldValue.serverTimestamp(),
        'lastPayMethod': method,
      });
      if (!mounted) return;
      setState(() => _walletInr -= _amt);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ ₹${_amt.toStringAsFixed(0)} deducted from wallet')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('❌ Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _accountCtrl.dispose();
    _ifscCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextDue = _nextDueDate;
    final schedule = _schedule;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Auto Pay Setup'),
        backgroundColor: Colors.white,
        foregroundColor: kTextPrimary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — SIP info + next due date
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: goldGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('💰', style: TextStyle(fontSize: 26)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('₹${_amt.toStringAsFixed(0)} / $_freqLabel',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            Text(
                                'Auto Pay: ${_autoPayEnabled ? "ON ✅" : "OFF"}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (nextDue != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                              'Next Due: ${DateFormat('dd MMM yyyy').format(nextDue)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text('Wallet Balance: ₹${_walletInr.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Auto Pay toggle + bank form
            Container(
              padding: const EdgeInsets.all(16),
              decoration: cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Auto Pay',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kTextPrimary,
                              fontSize: 15)),
                      Switch(
                        value: _autoPayEnabled,
                        activeThumbColor: kGold,
                        onChanged: (v) =>
                            v ? null : _disableAutoPay(),
                      ),
                    ],
                  ),
                  const Text(
                      'Amount will be auto-deducted from your wallet on each due date.',
                      style: TextStyle(color: kTextMuted, fontSize: 12)),
                  const SizedBox(height: 16),

                  // Pay method selector
                  Row(
                    children: [
                      _chip('🏦 Bank', 0),
                      const SizedBox(width: 10),
                      _chip('📱 GPay', 1),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Bank details
                  const Text('Bank Account Details',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary,
                          fontSize: 13)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _bankNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Bank Name',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _accountCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Account Number',
                      prefixIcon: Icon(Icons.credit_card_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _ifscCtrl,
                    decoration: const InputDecoration(
                      labelText: 'IFSC Code',
                      prefixIcon: Icon(Icons.code),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _saveAndEnableAutoPay,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_outlined),
                      label: Text(
                          _saving ? 'Saving...' : 'Save & Enable Auto Pay'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Manual Pay Now
            Container(
              padding: const EdgeInsets.all(16),
              decoration: cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pay Now (Manual)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                      'Deduct ₹${_amt.toStringAsFixed(0)} from wallet balance (₹${_walletInr.toStringAsFixed(0)})',
                      style: TextStyle(
                          color: _walletInr >= _amt ? kTextMuted : Colors.red,
                          fontSize: 12)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _chip('🏦 Bank', 0),
                      const SizedBox(width: 10),
                      _chip('📱 GPay', 1),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_paying || _walletInr < _amt) ? null : _payNow,
                      icon: _paying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Icon(_payMethod == 1
                              ? Icons.phone_android
                              : Icons.payment),
                      label: Text(_paying
                          ? 'Processing...'
                          : 'Pay ₹${_amt.toStringAsFixed(0)} via ${_payMethod == 0 ? "Bank" : "GPay"}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _payMethod == 1 ? const Color(0xFF1a73e8) : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Schedule
            if (schedule.isNotEmpty)
              StreamBuilder<QuerySnapshot>(
                stream: _phone == null
                    ? const Stream.empty()
                    : FirebaseFirestore.instance
                        .collection('transactions')
                        .where('phone', isEqualTo: _phone)
                        .where('type', isEqualTo: 'sip_payment')
                        .where('sipId', isEqualTo: widget.sipId)
                        .snapshots(),
                builder: (_, snap) {
                  final payments = snap.hasData
                      ? snap.data!.docs
                          .map((d) => d.data() as Map<String, dynamic>)
                          .toList()
                      : <Map<String, dynamic>>[];

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment Schedule',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kTextPrimary,
                                fontSize: 15)),
                        const SizedBox(height: 12),
                        ...schedule.map((dueDate) {
                          final isPast = dueDate.isBefore(now) &&
                              !_isSameDay(dueDate, now);
                          final isToday = _isSameDay(dueDate, now);
                          final paid = _isPaid(dueDate, payments);
                          final isUpcoming =
                              dueDate.isAfter(now) && !isToday;

                          Color dotColor;
                          IconData dotIcon;
                          String statusLabel;
                          if (paid) {
                            dotColor = const Color(0xFF2e7d32);
                            dotIcon = Icons.check_circle;
                            statusLabel = 'Paid';
                          } else if (isToday) {
                            dotColor = kGold;
                            dotIcon = Icons.radio_button_checked;
                            statusLabel = 'Due Today';
                          } else if (isPast) {
                            dotColor = Colors.red;
                            dotIcon = Icons.cancel;
                            statusLabel = 'Missed';
                          } else {
                            dotColor = kTextMuted;
                            dotIcon = Icons.radio_button_unchecked;
                            statusLabel = 'Upcoming';
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Icon(dotIcon, color: dotColor, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          DateFormat('dd MMM yyyy (EEE)')
                                              .format(dueDate),
                                          style: TextStyle(
                                              color: isUpcoming
                                                  ? kTextMuted
                                                  : kTextPrimary,
                                              fontWeight: isToday
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              fontSize: 13)),
                                      Text(
                                          '₹${_amt.toStringAsFixed(0)} · $_freqLabel',
                                          style: const TextStyle(
                                              color: kTextMuted,
                                              fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: dotColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(statusLabel,
                                      style: TextStyle(
                                          color: dotColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, int idx) {
    final selected = _payMethod == idx;
    return GestureDetector(
      onTap: () => setState(() => _payMethod = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? goldGradient : null,
          color: selected ? null : kBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kGoldBorder.withValues(alpha: 0.5)),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : kTextSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }
}
