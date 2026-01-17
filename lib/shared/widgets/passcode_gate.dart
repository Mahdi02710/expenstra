import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/services/settings_service.dart';

class PasscodeGate extends StatefulWidget {
  final Widget child;

  const PasscodeGate({super.key, required this.child});

  @override
  State<PasscodeGate> createState() => _PasscodeGateState();
}

class _PasscodeGateState extends State<PasscodeGate> {
  final SettingsService _settingsService = SettingsService();
  final TextEditingController _controller = TextEditingController();
  String? _passcode;
  bool _unlocked = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _loadPasscode();
  }

  Future<void> _loadPasscode() async {
    final code = await _settingsService.getPasscode();
    if (!mounted) return;
    setState(() {
      _passcode = code;
      _unlocked = code == null;
      _isChecking = false;
    });
  }

  void _checkPasscode() {
    if (_passcode == null) {
      setState(() => _unlocked = true);
      return;
    }
    if (_controller.text.trim() == _passcode) {
      setState(() => _unlocked = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect passcode'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return widget.child;
    }
    if (_unlocked) {
      return widget.child;
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 16),
              Text('Enter Passcode', style: AppTextStyles.h3),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: '4-digit passcode',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _checkPasscode(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkPasscode,
                child: const Text('Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
