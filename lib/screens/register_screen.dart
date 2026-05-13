import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../services/otp_service.dart';

class RegisterScreen extends StatefulWidget {
  final String name;
  final String phone;
  const RegisterScreen({super.key, required this.name, required this.phone});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: headerGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.star, size: 60, color: kGoldLight),
                  const SizedBox(height: 8),
                  const Text(
                    'DigiGold',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _stepIndicator(1),
                  const SizedBox(height: 32),
                  Container(
                    decoration: cardDecoration(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${widget.name}!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Enter your Gmail to receive OTP',
                          style: TextStyle(color: kTextMuted),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Gmail Address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _sendOtp,
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Send OTP'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepIndicator(int step) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      3,
      (i) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: i == step ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: i <= step ? kGoldLight : Colors.white38,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    ),
  );

  void _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter valid email')));
      return;
    }
    setState(() => _loading = true);
    await OtpService.sendOtp(email, widget.phone, widget.name);
    setState(() => _loading = false);
    if (!mounted) return;
    context.push(
      '/verify',
      extra: {'phone': widget.phone, 'name': widget.name, 'email': email},
    );
  }
}
