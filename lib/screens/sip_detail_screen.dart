import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as xl;
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../theme.dart';
import '../services/price_service.dart';

class SipDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String sipId;
  const SipDetailScreen({super.key, required this.data, required this.sipId});

  @override
  State<SipDetailScreen> createState() => _SipDetailScreenState();
}

class _SipDetailScreenState extends State<SipDetailScreen> {
  bool _exporting = false;

  double get _goldPrice => PriceService.goldPrice > 0 ? PriceService.goldPrice : 1;

  Map<String, dynamic> get _calc {
    final amt = (widget.data['amount'] ?? 0).toDouble();
    final freq = widget.data['frequency'] ?? 'monthly';
    final gramsPerPeriod = amt / _goldPrice;

    final dailyAmt = freq == 'daily' ? amt : freq == 'weekly' ? amt / 7 : amt / 30;
    final weeklyAmt = freq == 'daily' ? amt * 7 : freq == 'weekly' ? amt : amt / 4;
    final monthlyAmt = freq == 'daily' ? amt * 30 : freq == 'weekly' ? amt * 4 : amt;
    final yearlyAmt = monthlyAmt * 12;

    final dailyGrams = dailyAmt / _goldPrice;
    final weeklyGrams = weeklyAmt / _goldPrice;
    final monthlyGrams = monthlyAmt / _goldPrice;
    final yearlyGrams = monthlyGrams * 12;

    // 1g reach: periods from today
    final periods = gramsPerPeriod > 0 ? (1.0 / gramsPerPeriod).ceil() : 0;
    final now = DateTime.now();
    DateTime reach;
    if (freq == 'daily') {
      reach = now.add(Duration(days: periods));
    } else if (freq == 'weekly') {
      reach = now.add(Duration(days: periods * 7));
    } else {
      reach = DateTime(now.year, now.month + periods, now.day);
    }

    // Total paid so far since createdAt
    final ts = widget.data['createdAt'];
    double totalPaid = 0;
    double totalGrams = 0;
    int periodsDone = 0;
    if (ts != null) {
      final start = (ts as dynamic).toDate() as DateTime;
      final diff = now.difference(start);
      if (freq == 'daily') {
        periodsDone = diff.inDays;
      } else if (freq == 'weekly') {
        periodsDone = (diff.inDays / 7).floor();
      } else {
        periodsDone = (diff.inDays / 30).floor();
      }
      if (periodsDone < 0) periodsDone = 0;
      totalPaid = amt * periodsDone;
      totalGrams = gramsPerPeriod * periodsDone;
    }

    // Balance remaining to reach 1g
    final balanceGrams = (1.0 - totalGrams).clamp(0.0, 1.0);
    final balanceAmt = balanceGrams * _goldPrice;

    return {
      'amt': amt,
      'freq': freq,
      'gramsPerPeriod': gramsPerPeriod,
      'dailyAmt': dailyAmt,
      'weeklyAmt': weeklyAmt,
      'monthlyAmt': monthlyAmt,
      'yearlyAmt': yearlyAmt,
      'dailyGrams': dailyGrams,
      'weeklyGrams': weeklyGrams,
      'monthlyGrams': monthlyGrams,
      'yearlyGrams': yearlyGrams,
      'reachDate': DateFormat('dd MMM yyyy').format(reach),
      'totalPaid': totalPaid,
      'totalGrams': totalGrams,
      'periodsDone': periodsDone,
      'balanceGrams': balanceGrams,
      'balanceAmt': balanceAmt,
    };
  }

  Future<void> _exportExcel() async {
    setState(() => _exporting = true);
    try {
      final c = _calc;
      final freq = c['freq'] as String;
      final freqLabel = freq[0].toUpperCase() + freq.substring(1);
      final ts = widget.data['createdAt'];
      final createdDate = ts != null
          ? DateFormat('dd MMM yyyy').format((ts as dynamic).toDate())
          : '';

      final excel = xl.Excel.createExcel();
      final sheet = excel['SIP Detail'];

      sheet.appendRow([xl.TextCellValue('SIP Plan Detail Report')]);
      sheet.appendRow([xl.TextCellValue('')]);
      sheet.appendRow([xl.TextCellValue('Phone'), xl.TextCellValue(widget.data['phone'] ?? '')]);
      sheet.appendRow([xl.TextCellValue('Frequency'), xl.TextCellValue(freqLabel)]);
      sheet.appendRow([xl.TextCellValue('Amount per $freqLabel'), xl.TextCellValue('₹${(c['amt'] as double).toStringAsFixed(0)}')]);
      sheet.appendRow([xl.TextCellValue('Grams per $freqLabel'), xl.TextCellValue('${(c['gramsPerPeriod'] as double).toStringAsFixed(6)}g')]);
      sheet.appendRow([xl.TextCellValue('Status'), xl.TextCellValue(widget.data['status'] ?? '')]);
      sheet.appendRow([xl.TextCellValue('Started On'), xl.TextCellValue(createdDate)]);
      sheet.appendRow([xl.TextCellValue('')]);

      // Breakdown
      sheet.appendRow([
        xl.TextCellValue('Period'),
        xl.TextCellValue('Amount Paid (₹)'),
        xl.TextCellValue('Gold Accumulated (g)'),
      ]);
      for (final row in [
        ['Daily', c['dailyAmt'], c['dailyGrams']],
        ['Weekly', c['weeklyAmt'], c['weeklyGrams']],
        ['Monthly', c['monthlyAmt'], c['monthlyGrams']],
        ['Yearly', c['yearlyAmt'], c['yearlyGrams']],
      ]) {
        sheet.appendRow([
          xl.TextCellValue(row[0] as String),
          xl.TextCellValue('₹${(row[1] as double).toStringAsFixed(2)}'),
          xl.TextCellValue('${(row[2] as double).toStringAsFixed(6)}g'),
        ]);
      }

      sheet.appendRow([xl.TextCellValue('')]);
      sheet.appendRow([xl.TextCellValue('--- Summary So Far ---')]);
      sheet.appendRow([xl.TextCellValue('Periods Completed'), xl.TextCellValue('${c['periodsDone']}')]);
      sheet.appendRow([xl.TextCellValue('Total Paid'), xl.TextCellValue('₹${(c['totalPaid'] as double).toStringAsFixed(2)}')]);
      sheet.appendRow([xl.TextCellValue('Total Gold Accumulated'), xl.TextCellValue('${(c['totalGrams'] as double).toStringAsFixed(6)}g')]);
      sheet.appendRow([xl.TextCellValue('Balance to reach 1g'), xl.TextCellValue('${(c['balanceGrams'] as double).toStringAsFixed(6)}g (₹${(c['balanceAmt'] as double).toStringAsFixed(2)})')]);
      sheet.appendRow([xl.TextCellValue('')]);
      sheet.appendRow([xl.TextCellValue('🏅 1g Gold Reach Date'), xl.TextCellValue(c['reachDate'] as String)]);

      final bytes = excel.encode()!;
      // Save to Downloads folder
      final downloadsDir = Directory('/storage/emulated/0/Download');
      final dir = downloadsDir.existsSync() ? downloadsDir : Directory('/sdcard/Download');
      final fileName = 'sip_${widget.data['phone']}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Saved to Downloads/$fileName'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _calc;
    final freq = c['freq'] as String;
    final freqLabel = freq[0].toUpperCase() + freq.substring(1);
    final ts = widget.data['createdAt'];
    final createdDate = ts != null
        ? DateFormat('dd MMM yyyy').format((ts as dynamic).toDate())
        : '';
    final status = widget.data['status'] ?? 'active';
    final totalPaid = c['totalPaid'] as double;
    final totalGrams = c['totalGrams'] as double;
    final balanceGrams = c['balanceGrams'] as double;
    final balanceAmt = c['balanceAmt'] as double;
    final periodsDone = c['periodsDone'] as int;
    final progress = (totalGrams / 1.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('SIP Details'),
        backgroundColor: Colors.white,
        foregroundColor: kTextPrimary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: goldGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('💰', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Auto SIP Plan',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            Text('₹${(c['amt'] as double).toStringAsFixed(0)} / $freqLabel',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                      _statusBadge(status),
                    ],
                  ),
                  if (createdDate.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Started: $createdDate',
                        style: const TextStyle(color: Colors.white60, fontSize: 11)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment breakdown table
            Container(
              padding: const EdgeInsets.all(16),
              decoration: cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Breakdown',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                          fontSize: 14)),
                  const SizedBox(height: 12),
                  _tableHeader(),
                  const Divider(height: 10),
                  _tableRow('Daily', c['dailyAmt'] as double, c['dailyGrams'] as double),
                  _tableRow('Weekly', c['weeklyAmt'] as double, c['weeklyGrams'] as double),
                  _tableRow('Monthly', c['monthlyAmt'] as double, c['monthlyGrams'] as double),
                  const Divider(height: 10),
                  _tableRow('Yearly', c['yearlyAmt'] as double, c['yearlyGrams'] as double, bold: true),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 1g reach date
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kGoldPale,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kGoldBorder.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  const Text('🏅', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('1g Gold Reach Date',
                          style: TextStyle(color: kTextMuted, fontSize: 12)),
                      Text(c['reachDate'] as String,
                          style: const TextStyle(
                              color: kGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Auto Pay button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/auto_pay',
                    extra: {'data': widget.data, 'id': widget.sipId}),
                icon: const Icon(Icons.autorenew, color: kGold),
                label: const Text('Setup Auto Pay / Pay Now',
                    style: TextStyle(color: kGold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kGold),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Total paid & balance summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('My Payment Summary',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                          fontSize: 14)),
                  const SizedBox(height: 12),
                  _summaryRow('Periods Completed', '$periodsDone $freqLabel(s)'),
                  _summaryRow('Total Paid', '₹${totalPaid.toStringAsFixed(2)}'),
                  _summaryRow('Total Gold Accumulated', '${totalGrams.toStringAsFixed(6)}g'),
                  const Divider(height: 16),
                  // Progress bar toward 1g
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Progress to 1g',
                          style: TextStyle(color: kTextMuted, fontSize: 12)),
                      Text('${(progress * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              color: kGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: kGoldBorder.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(kGold),
                    ),
                  ),
                  const Divider(height: 16),
                  _summaryRow(
                    'Balance to reach 1g',
                    '${balanceGrams.toStringAsFixed(6)}g',
                    sub: '≈ ₹${balanceAmt.toStringAsFixed(2)} remaining',
                    highlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton.icon(
            onPressed: _exporting ? null : _exportExcel,
            icon: _exporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.download_rounded),
            label: Text(_exporting ? 'Exporting...' : 'Download Excel Sheet'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {String? sub, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: kTextMuted, fontSize: 13)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(
                      color: highlight ? kMaroon : kTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              if (sub != null)
                Text(sub,
                    style: const TextStyle(
                        color: kTextMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHeader() => const Row(
        children: [
          Expanded(
              flex: 2,
              child: Text('Period',
                  style: TextStyle(
                      color: kTextMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600))),
          Expanded(
              flex: 3,
              child: Text('Amount (₹)',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: kTextMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600))),
          Expanded(
              flex: 3,
              child: Text('Gold (g)',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: kTextMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600))),
        ],
      );

  Widget _tableRow(String period, double amt, double grams,
      {bool bold = false}) {
    final style = TextStyle(
        color: bold ? kGold : kTextPrimary,
        fontWeight: bold ? FontWeight.bold : FontWeight.w500,
        fontSize: 13);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(period, style: style)),
          Expanded(
              flex: 3,
              child: Text('₹${amt.toStringAsFixed(2)}',
                  textAlign: TextAlign.right, style: style)),
          Expanded(
              flex: 3,
              child: Text(grams.toStringAsFixed(6),
                  textAlign: TextAlign.right, style: style)),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status.toUpperCase(),
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }
}
