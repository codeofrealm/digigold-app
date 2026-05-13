import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../services/auth_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _cat = 0;
  final _cats = ['gold_coin', 'gold_biscuit', 'silver_coin', 'silver_biscuit'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _categoryTabs(),
        Expanded(child: _productGrid()),
      ],
    );
  }

  Widget _categoryTabs() => Container(
    color: Colors.white,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: _cats.asMap().entries.map((e) {
          final active = _cat == e.key;
          return GestureDetector(
            onTap: () => setState(() => _cat = e.key),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: active ? goldGradient : null,
                color: active ? null : kBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? kGold : kGoldBorder.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                _categoryLabel(e.value),
                style: TextStyle(
                  color: active ? Colors.white : kTextSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );

  Widget _productGrid() => StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('shop_products')
        .where('category', isEqualTo: _cats[_cat])
        .snapshots(),
    builder: (_, snap) {
      if (!snap.hasData) {
        return const Center(child: CircularProgressIndicator(color: kGold));
      }
      final docs = snap.data!.docs.where((doc) {
        final product = doc.data() as Map<String, dynamic>;
        return product['inStock'] != false;
      }).toList();
      if (docs.isEmpty) return _emptyState();
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: docs.length,
        itemBuilder: (_, i) {
          final p = Map<String, dynamic>.from(
            docs[i].data() as Map<String, dynamic>,
          )..['id'] = docs[i].id;
          return _productCard(p);
        },
      );
    },
  );

  Widget _productCard(Map<String, dynamic> p) => Container(
    decoration: cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: kGoldPale,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: const Center(
              child: Icon(Icons.diamond_outlined, size: 48, color: kGold),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p['name'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _badge('${p['weightGrams']}g'),
                  const SizedBox(width: 4),
                  _badge(p['purity'] ?? ''),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${p['priceInr']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kGold,
                      fontSize: 15,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showOrderModal(p),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: goldGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _badge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: kGoldPale,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: kGoldBorder.withValues(alpha: 0.5)),
    ),
    child: Text(
      label,
      style: const TextStyle(color: kTextSecondary, fontSize: 10),
    ),
  );

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.storefront_outlined, size: 64, color: kTextMuted),
        const SizedBox(height: 12),
        const Text(
          'No products in this category',
          style: TextStyle(color: kTextMuted),
        ),
      ],
    ),
  );

  void _showOrderModal(Map<String, dynamic> product) {
    final addrCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24,
          left: 24,
          right: 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              product['name'] ?? '',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${product['priceInr']}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kGold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addrCtrl,
              decoration: const InputDecoration(
                labelText: 'Delivery Address',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _placeOrder(product, addrCtrl.text, 'wallet'),
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: const Text('Wallet'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: kMaroon),
                    onPressed: () =>
                        _placeOrder(product, addrCtrl.text, 'card'),
                    icon: const Icon(Icons.credit_card),
                    label: const Text('Card'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _placeOrder(
    Map<String, dynamic> product,
    String address,
    String payment,
  ) async {
    if (address.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter delivery address')));
      return;
    }
    final phone = await AuthService.getPhone();
    final user = phone == null ? null : await AuthService.getUser(phone);
    await FirebaseFirestore.instance.collection('orders').add({
      'userId': phone,
      'userName': user?['name'] ?? '',
      'phone': phone,
      'metal': (product['category'] ?? '').toString().startsWith('silver')
          ? 'silver'
          : 'gold',
      'productId': product['id'] ?? '',
      'productLabel': product['name'],
      'grams': (product['weightGrams'] ?? 0).toDouble(),
      'priceInr': product['priceInr'],
      'paymentMode': payment,
      'status': 'processing',
      'addressLine': address,
      'city': '',
      'pin': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Order placed successfully!')));
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
}
