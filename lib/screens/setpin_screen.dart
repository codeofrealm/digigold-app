import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../theme.dart';
import '../services/auth_service.dart';

class SetPinScreen extends StatefulWidget {
  final String phone;
  const SetPinScreen({super.key, required this.phone});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  String _pin = '';
  int _step = 0; // 0=set, 1=confirm
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
                  const Text('DigiGold',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  _stepIndicator(),
                  const SizedBox(height: 32),
                  Container(
                    decoration: cardDecoration(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          _step == 0 ? 'Set Your PIN' : 'Confirm PIN',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: kTextPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _step == 0
                              ? 'Choose a 4-digit PIN'
                              : 'Re-enter your PIN',
                          style: const TextStyle(color: kTextMuted),
                        ),
                        const SizedBox(height: 24),
                        PinCodeTextField(
                          key: ValueKey(_step),
                          appContext: context,
                          length: 4,
                          obscureText: true,
                          onChanged: (v) {
                            if (_step == 0) _pin = v;
                          },
                          onCompleted: (v) =>
                              _step == 0 ? _onPinSet(v) : _onConfirm(v),
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.circle,
                            fieldHeight: 60,
                            fieldWidth: 60,
                            activeFillColor: kGoldPale,
                            selectedFillColor: kGoldPale,
                            inactiveFillColor: Colors.white,
                            activeColor: kGold,
                            selectedColor: kGold,
                            inactiveColor: kGoldBorder,
                          ),
                          enableActiveFill: true,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 24),
                        if (_loading)
                          const CircularProgressIndicator(color: kGold),
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

  Widget _stepIndicator() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
            3,
            (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 24,
                  height: 8,
                  decoration: BoxDecoration(
                    color: kGoldLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
      );

  void _onPinSet(String v) {
    setState(() {
      _pin = v;
      _step = 1;
    });
  }

  void _onConfirm(String v) async {
    if (v != _pin) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('PINs do not match')));
      setState(() => _step = 0);
      return;
    }
    setState(() => _loading = true);
    await AuthService.savePin(widget.phone, v);
    setState(() => _loading = false);
    if (!mounted) return;
    context.go('/');
  }
}
