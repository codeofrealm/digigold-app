import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PriceService {
  static final _db = FirebaseFirestore.instance;

  static double _goldPrice = 7200.0;
  static double _silverPrice = 92.0;
  static int _karat = 24;
  static bool _isLive = false;

  static double get goldPrice => _goldPrice;
  static double get silverPrice => _silverPrice;
  static int get karat => _karat;
  static bool get isLive => _isLive;

  static Future<void> fetchPrices() async {
    try {
      final doc = await _db.collection('prices').doc('live').get();
      if (doc.exists) {
        final data = doc.data()!;
        _goldPrice = (data['gold'] ?? 7200).toDouble();
        _silverPrice = (data['silver'] ?? 92).toDouble();
        _karat = (data['karat'] ?? 24).toInt();
        _isLive = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('goldPrice', _goldPrice);
        await prefs.setDouble('silverPrice', _silverPrice);
      }
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      _goldPrice = prefs.getDouble('goldPrice') ?? 7200.0;
      _silverPrice = prefs.getDouble('silverPrice') ?? 92.0;
      _isLive = false;
    }
  }

  static Stream<DocumentSnapshot> priceStream() =>
      _db.collection('prices').doc('live').snapshots();
}
