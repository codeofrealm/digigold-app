import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/otp_service.dart';

class VerifyScreen extends StatefulWidget {
  final String phone;
  final String name;
  final String email;
  const VerifyScreen({
    super.key,
    required this.phone,
    required this.name,
    required this.email,
  });

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  String _otp = '';
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
                  _stepIndicator(2),
                  const SizedBox(height: 32),
                  Container(
                    decoration: cardDecoration(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          'Enter OTP',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sent to ${widget.email}',
                          style: const TextStyle(color: kTextMuted),
                        ),
                        const SizedBox(height: 24),
                        PinCodeTextField(
                          appContext: context,
                          length: 6,
                          onChanged: (v) => _otp = v,
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(10),
                            fieldHeight: 52,
                            fieldWidth: 44,
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
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _verify,
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Verify OTP'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () async {
                            await OtpService.sendOtp(
                              widget.email,
                              widget.phone,
                              widget.name,
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('OTP resent')),
                            );
                          },
                          child: const Text(
                            'Resend OTP',
                            style: TextStyle(color: kGold),
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

  void _verify() async {
    if (_otp.length != 6) return;
    setState(() => _loading = true);
    final ok = await OtpService.verifyOtp(widget.phone, _otp);
    setState(() => _loading = false);
    if (!mounted) return;
    if (ok) {
      await AuthService.createUser(widget.phone, widget.name, widget.email);
      if (!mounted) return;
      context.push('/setpin', extra: {'phone': widget.phone});
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid OTP')));
    }
  }
}
