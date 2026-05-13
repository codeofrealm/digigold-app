import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../services/auth_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? _phone;
  final _picker = ImagePicker();

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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_phone)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const Center(child: CircularProgressIndicator(color: kGold));
        }
        final u = snap.data!.data() as Map<String, dynamic>;
        final name = (u['name'] ?? 'User').toString();
        final phone = (u['phone'] ?? _phone ?? '').toString();
        final gmail = (u['gmail'] ?? '').toString();
        final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
        final goldGrams = (u['balanceGrams'] ?? 0.0).toDouble();
        final silverGrams = (u['balanceSilverGrams'] ?? 0.0).toDouble();
        final walletInr = (u['walletInr'] ?? 0.0).toDouble();
        final kycTier = (u['kycTier'] ?? 'none').toString();
        final referralCode = (u['referralCode'] ?? 'DG$phone').toString();
        final role = (u['role'] ?? 'user').toString();
        final bankName = (u['bankName'] ?? '').toString();
        final bankAccount = (u['bankAccount'] ?? '').toString();
        final ifsc = (u['ifsc'] ?? '').toString();
        final addressLine = (u['addressLine'] ?? '').toString();
        final city = (u['city'] ?? '').toString();
        final pincode = (u['pincode'] ?? '').toString();
        final panUrl = (u['panUrl'] ?? '').toString();
        final aadhaarUrl = (u['aadhaarUrl'] ?? '').toString();

        final maskedAccount = bankAccount.length > 4
            ? '••••${bankAccount.substring(bankAccount.length - 4)}'
            : bankAccount.isEmpty
                ? 'Not added'
                : bankAccount;

        return SingleChildScrollView(
          child: Column(
            children: [
              _header(initials, name, phone, gmail, role,
                  goldGrams, silverGrams, walletInr),
              const SizedBox(height: 16),
              _section('Account Info', [
                _infoTile(Icons.person_outline, 'Full Name', name),
                _infoTile(Icons.phone_outlined, 'Phone', '+91 $phone'),
                _infoTile(Icons.email_outlined, 'Gmail',
                    gmail.isEmpty ? 'Not set' : gmail),
                _editTile('Edit Profile', () => _showEditDialog(name, gmail)),
              ]),
              const SizedBox(height: 12),
              _section('Bank Details', [
                _infoTile(Icons.account_balance_outlined, 'Bank Name',
                    bankName.isEmpty ? 'Not added' : bankName),
                _infoTile(Icons.credit_card_outlined, 'Account Number',
                    maskedAccount),
                _infoTile(Icons.code, 'IFSC Code',
                    ifsc.isEmpty ? 'Not added' : ifsc),
                _editTile('Update Bank Details',
                    () => _showBankDialog(bankName, bankAccount, ifsc)),
              ]),
              const SizedBox(height: 12),
              _section('Delivery Address', [
                _infoTile(Icons.location_on_outlined, 'Address',
                    addressLine.isEmpty ? 'Not added' : addressLine),
                _infoTile(Icons.location_city_outlined, 'City / PIN',
                    city.isEmpty && pincode.isEmpty
                        ? 'Not added'
                        : '$city - $pincode'),
                _editTile('Update Address',
                    () => _showAddressDialog(addressLine, city, pincode)),
              ]),
              const SizedBox(height: 12),
              _kycSection(kycTier, panUrl, aadhaarUrl),
              const SizedBox(height: 12),
              _referralCard(referralCode),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: kMaroon),
                    onPressed: () async {
                      await AuthService.logout();
                      if (!mounted) return;
                      context.go('/login');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _header(String initials, String name, String phone, String gmail,
          String role, double gold, double silver, double wallet) =>
      Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        decoration: BoxDecoration(gradient: headerGradient),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: kGoldLight,
                  child: Text(initials,
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
                if (role == 'admin')
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: kGold,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('ADMIN',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Text('+91 $phone',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            if (gmail.isNotEmpty)
              Text(gmail,
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _chip('Gold', '${gold.toStringAsFixed(4)}g'),
                const SizedBox(width: 10),
                _chip('Silver', '${silver.toStringAsFixed(4)}g'),
                const SizedBox(width: 10),
                _chip('Wallet', '₹${wallet.toStringAsFixed(0)}'),
              ],
            ),
          ],
        ),
      );

  Widget _chip(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      );

  // ── KYC Section ───────────────────────────────────────────────────────────

  Widget _kycSection(String tier, String panUrl, String aadhaarUrl) {
    const statusMap = {
      'none': 'Not Submitted',
      'pan_submitted': 'Under Review',
      'verified': 'Verified ✓',
    };
    const colorMap = {
      'none': Colors.grey,
      'pan_submitted': Colors.orange,
      'verified': Color(0xFF2e7d32),
    };
    final status = statusMap[tier] ?? tier;
    final color = colorMap[tier] ?? Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('KYC Verification',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                          fontSize: 15)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(status,
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFf0e8d0)),
            // PAN Card
            _kycDocTile(
              icon: Icons.credit_card,
              label: 'PAN Card',
              imageUrl: panUrl,
              onUpload: () => _uploadKycDoc('pan'),
            ),
            const Divider(height: 1, color: Color(0xFFf0e8d0)),
            // Aadhaar
            _kycDocTile(
              icon: Icons.badge_outlined,
              label: 'Aadhaar Card',
              imageUrl: aadhaarUrl,
              onUpload: () => _uploadKycDoc('aadhaar'),
            ),
            if (tier == 'none' || tier == 'pan_submitted')
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: panUrl.isNotEmpty && aadhaarUrl.isNotEmpty
                        ? _submitKyc
                        : null,
                    icon: const Icon(Icons.upload_file),
                    label: Text(tier == 'pan_submitted'
                        ? 'Documents Submitted'
                        : 'Submit KYC'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _kycDocTile({
    required IconData icon,
    required String label,
    required String imageUrl,
    required VoidCallback onUpload,
  }) =>
      ListTile(
        leading: Icon(icon, color: kGold),
        title: Text(label,
            style: const TextStyle(color: kTextPrimary, fontSize: 14)),
        subtitle: Text(
          imageUrl.isNotEmpty ? 'Uploaded ✓' : 'Not uploaded',
          style: TextStyle(
            color: imageUrl.isNotEmpty
                ? const Color(0xFF2e7d32)
                : kTextMuted,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl.isNotEmpty)
              GestureDetector(
                onTap: () => _viewImage(imageUrl, label),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: kGoldPale,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.visibility_outlined,
                      color: kGold, size: 18),
                ),
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onUpload,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: goldGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  imageUrl.isNotEmpty
                      ? Icons.refresh
                      : Icons.upload_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      );

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _section(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary,
                        fontSize: 15)),
              ),
              const Divider(height: 1, color: Color(0xFFf0e8d0)),
              ...children,
            ],
          ),
        ),
      );

  Widget _infoTile(IconData icon, String title, String value) => ListTile(
        leading: Icon(icon, color: kGold),
        title: Text(title,
            style: const TextStyle(color: kTextMuted, fontSize: 12)),
        subtitle: Text(value,
            style: const TextStyle(
                color: kTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      );

  Widget _editTile(String label, VoidCallback onTap) => ListTile(
        leading: const Icon(Icons.edit_outlined, color: kGold),
        title: Text(label,
            style: const TextStyle(color: kTextPrimary, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right, color: kTextMuted),
        onTap: onTap,
      );

  Widget _referralCard(String code) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kGoldPale,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kGoldBorder.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.card_giftcard, color: kGold, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Referral Code',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary)),
                    Text(code,
                        style: const TextStyle(
                            color: kGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: kGold),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Referral code copied!')));
                },
              ),
            ],
          ),
        ),
      );

  // ── KYC Upload Logic ──────────────────────────────────────────────────────

  Future<void> _uploadKycDoc(String docType) async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final picked = await _picker.pickImage(
        source: source, imageQuality: 80, maxWidth: 1200);
    if (picked == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading...')));

    try {
      final file = File(picked.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('kyc/$_phone/$docType.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      final field = docType == 'pan' ? 'panUrl' : 'aadhaarUrl';
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_phone)
          .update({
        field: url,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${docType == 'pan' ? 'PAN Card' : 'Aadhaar'} uploaded!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')));
    }
  }

  Future<void> _submitKyc() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_phone)
        .update({
      'kycTier': 'pan_submitted',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('KYC submitted! Under review.')));
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Select Image Source',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: kTextPrimary)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: kGold),
              title: const Text('Camera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: kGold),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _viewImage(String url, String label) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            Image.network(url, fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: CircularProgressIndicator(color: kGold))),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ── Edit Dialogs ──────────────────────────────────────────────────────────

  void _showEditDialog(String currentName, String currentGmail) {
    final nameCtrl = TextEditingController(text: currentName);
    final gmailCtrl = TextEditingController(text: currentGmail);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: gmailCtrl,
              decoration: const InputDecoration(
                  labelText: 'Gmail',
                  prefixIcon: Icon(Icons.email_outlined)),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final gmail = gmailCtrl.text.trim();
              if (name.isEmpty) return;
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(_phone)
                  .update({
                'name': name,
                'gmail': gmail,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated!')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBankDialog(
      String currentBank, String currentAccount, String currentIfsc) {
    final bankCtrl = TextEditingController(text: currentBank);
    final accountCtrl = TextEditingController(text: currentAccount);
    final ifscCtrl = TextEditingController(text: currentIfsc);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bank Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bankCtrl,
                decoration: const InputDecoration(
                    labelText: 'Bank Name',
                    prefixIcon: Icon(Icons.account_balance_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: accountCtrl,
                decoration: const InputDecoration(
                    labelText: 'Account Number',
                    prefixIcon: Icon(Icons.credit_card_outlined)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ifscCtrl,
                decoration: const InputDecoration(
                    labelText: 'IFSC Code',
                    prefixIcon: Icon(Icons.code)),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(_phone)
                  .update({
                'bankName': bankCtrl.text.trim(),
                'bankAccount': accountCtrl.text.trim(),
                'ifsc': ifscCtrl.text.trim().toUpperCase(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bank details saved!')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddressDialog(
      String currentAddr, String currentCity, String currentPin) {
    final addrCtrl = TextEditingController(text: currentAddr);
    final cityCtrl = TextEditingController(text: currentCity);
    final pinCtrl = TextEditingController(text: currentPin);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delivery Address'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: addrCtrl,
                decoration: const InputDecoration(
                    labelText: 'Address Line',
                    prefixIcon: Icon(Icons.location_on_outlined)),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cityCtrl,
                decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinCtrl,
                decoration: const InputDecoration(
                    labelText: 'PIN Code',
                    prefixIcon: Icon(Icons.pin_drop_outlined)),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(_phone)
                  .update({
                'addressLine': addrCtrl.text.trim(),
                'city': cityCtrl.text.trim(),
                'pincode': pinCtrl.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Address saved!')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
