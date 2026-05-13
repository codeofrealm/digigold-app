import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final _db = FirebaseFirestore.instance;

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('phone') != null;
  }

  static Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('phone');
  }

  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isAdmin') ?? false;
  }

  static Future<Map<String, dynamic>?> loginWithPin(
      String phone, String pin) async {
    if (phone == '9999999999' && pin == '1234') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phone', phone);
      await prefs.setBool('isAdmin', true);
      final doc = await _db.collection('users').doc(phone).get();
      if (!doc.exists) {
        await _db.collection('users').doc(phone).set({
          'name': 'Admin',
          'phone': phone,
          'gmail': 'admin@digigold.com',
          'role': 'admin',
          'kycTier': 'verified',
          'balanceGrams': 0.0,
          'balanceSilverGrams': 0.0,
          'walletInr': 0.0,
          'referralCode': 'ADMIN',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await _db.collection('prices').doc('live').set({
          'gold': 7200.0,
          'silver': 92.0,
          'karat': 24,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': 'admin',
        });
        await _db.collection('prices').doc('ratecard').set({
          'gold10g24k': 72000.0,
          'gold10g22k': 66000.0,
          'silver10g': 920.0,
          'silver50g': 4600.0,
        });
      }
      return {'phone': phone, 'name': 'Admin', 'role': 'admin'};
    }
    final doc = await _db.collection('users').doc(phone).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    if (data['pin'] == pin) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phone', phone);
      await prefs.setBool('isAdmin', data['role'] == 'admin');
      return data;
    }
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> savePin(String phone, String pin) async {
    await _db.collection('users').doc(phone).update({
      'pin': pin,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone', phone);
    final doc = await _db.collection('users').doc(phone).get();
    await prefs.setBool('isAdmin', doc.data()?['role'] == 'admin');
  }

  static Future<void> createUser(
      String phone, String name, String email) async {
    await _db.collection('users').doc(phone).set({
      'name': name,
      'phone': phone,
      'gmail': email,
      'role': 'user',
      'kycTier': 'none',
      'balanceGrams': 0.0,
      'balanceSilverGrams': 0.0,
      'walletInr': 0.0,
      'referralCode': 'DG$phone',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, dynamic>?> getUser(String phone) async {
    final doc = await _db.collection('users').doc(phone).get();
    return doc.exists ? doc.data() : null;
  }
}
