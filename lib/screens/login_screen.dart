import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _tab = 0;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _hero(),
            _promoStrip(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
                child: Column(
                  children: [
                    _tabSelector(),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
                      decoration: cardDecoration(radius: 16),
                      child: _tab == 0 ? _loginForm() : _registerForm(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero() => Container(
    width: double.infinity,
    height: 246,
    decoration: BoxDecoration(gradient: headerGradient),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: 68,
          width: 68,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: const Icon(Icons.star, color: kGoldLight, size: 42),
        ),
        const SizedBox(height: 26),
        const Text(
          'DigiGold',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Buy & Save Digital Gold · Secure · Insured',
          style: TextStyle(color: Colors.white, fontSize: 13),
        ),
        const SizedBox(height: 34),
      ],
    ),
  );

  Widget _promoStrip() => Container(
    height: 44,
    width: double.infinity,
    decoration: const BoxDecoration(
      color: kGoldPale,
      border: Border(bottom: BorderSide(color: kGoldBorder)),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('🏅', style: TextStyle(fontSize: 18)),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            'Start with ₹10 · 24K 999 purity · MMTC-PAMP certified',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _tabSelector() => Container(
    height: 54,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: const Color(0xFFF2E9D8),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE9DDC6)),
    ),
    child: Row(
      children: [
        Expanded(child: _tabBtn('Login', 0, _tab == 0)),
        Expanded(child: _tabBtn('Register', 1, _tab == 1)),
      ],
    ),
  );

  Widget _tabBtn(String label, int idx, bool active) => GestureDetector(
    onTap: () => setState(() => _tab = idx),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                colors: [kMaroon, kGold],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : kTextMuted,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ),
  );

  Widget _loginForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Welcome Back',
        style: TextStyle(
          color: kTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Enter your mobile number and PIN',
        style: TextStyle(color: kTextMuted, fontSize: 13),
      ),
      const SizedBox(height: 24),
      const _FieldLabel('MOBILE NUMBER'),
      const SizedBox(height: 8),
      _phoneField(),
      const SizedBox(height: 18),
      const _FieldLabel('4-DIGIT PIN'),
      const SizedBox(height: 8),
      TextField(
        controller: _pinCtrl,
        decoration: const InputDecoration(hintText: 'Enter PIN'),
        keyboardType: TextInputType.number,
        obscureText: true,
        maxLength: 4,
      ),
      const SizedBox(height: 16),
      _primaryButton('Login', Icons.login, _login),
    ],
  );

  Widget _registerForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Create Account ✨',
        style: TextStyle(
          color: kTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Step 1 of 3 · Enter your details',
        style: TextStyle(color: kTextMuted, fontSize: 13),
      ),
      const SizedBox(height: 24),
      const _FieldLabel('FULL NAME'),
      const SizedBox(height: 8),
      TextField(
        controller: _nameCtrl,
        decoration: const InputDecoration(hintText: 'Enter full name'),
        textCapitalization: TextCapitalization.words,
      ),
      const SizedBox(height: 18),
      const _FieldLabel('MOBILE NUMBER'),
      const SizedBox(height: 8),
      _phoneField(),
      const SizedBox(height: 22),
      _primaryButton('Next', Icons.arrow_forward, _register),
      const SizedBox(height: 20),
      const Divider(color: Color(0xFFE9DDC6)),
    ],
  );

  Widget _phoneField() => Row(
    children: [
      Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFBF6EA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE9DDC6)),
        ),
        child: const Center(
          child: Text(
            'IN  +91',
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: TextField(
          controller: _phoneCtrl,
          decoration: const InputDecoration(hintText: '1234567890'),
          keyboardType: TextInputType.phone,
        ),
      ),
    ],
  );

  Widget _primaryButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) => SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: kGold,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 20),
        ],
      ),
    ),
  );

  void _login() async {
    final phone = _phoneCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    if (phone.isEmpty || pin.length != 4) {
      _showError('Enter valid phone and 4-digit PIN');
      return;
    }
    final user = await AuthService.loginWithPin(phone, pin);
    if (user == null) {
      _showError('Invalid phone or PIN');
      return;
    }
    if (!mounted) return;
    context.go(phone == '9999999999' ? '/admin' : '/');
  }

  void _register() {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      _showError('Enter name and phone');
      return;
    }
    context.push('/register', extra: {'name': name, 'phone': phone});
  }

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: kTextMuted,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
