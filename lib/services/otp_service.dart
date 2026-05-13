import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtpService {
  static const _gmailUser = 'rahul91598308@gmail.com';
  static const _gmailPass = 'szba ciho qqik gkuv';

  static final _db = FirebaseFirestore.instance;

  static String _generateOtp() =>
      (100000 + Random().nextInt(900000)).toString();

  static Future<bool> sendOtp(String email, String phone, String name) async {
    final otp = _generateOtp();
    final expiresAt =
        Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 10)));

    // Save OTP to Firestore otp/{phone}
    await _db.collection('otp').doc(phone).set({
      'otp': otp,
      'email': email,
      'name': name,
      'expiresAt': expiresAt,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Send via Gmail SMTP
    try {
      final smtpServer = gmail(_gmailUser, _gmailPass);
      final message = Message()
        ..from = Address(_gmailUser, 'DigiGold')
        ..recipients.add(email)
        ..subject = 'Your DigiGold OTP'
        ..html = '''
          <div style="font-family:Arial,sans-serif;max-width:480px;margin:auto;padding:32px;border:1px solid #e8c84a;border-radius:16px;">
            <h2 style="color:#7b1c1c;">DigiGold</h2>
            <p>Hello <b>$name</b>,</p>
            <p>Your One-Time Password is:</p>
            <div style="font-size:36px;font-weight:bold;letter-spacing:8px;color:#b8860b;padding:16px 0;">$otp</div>
            <p style="color:#9a8060;font-size:13px;">Valid for 10 minutes. Do not share this OTP with anyone.</p>
          </div>
        ''';

      await send(message, smtpServer);
      return true;
    } catch (e) {
      // OTP already saved to Firestore — dev can read it from console
      return false;
    }
  }

  static Future<bool> verifyOtp(String phone, String otp) async {
    final doc = await _db.collection('otp').doc(phone).get();
    if (!doc.exists) return false;
    final data = doc.data()!;

    // Check expiry
    final expiresAt = data['expiresAt'] as Timestamp?;
    if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
      await _db.collection('otp').doc(phone).delete();
      return false;
    }

    if (data['otp'] == otp) {
      await _db.collection('otp').doc(phone).delete();
      return true;
    }
    return false;
  }
}
