import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth_store.dart';
import '../../../core/logger.dart';
import '../../../core/validators.dart';
import '../../../core/widgets.dart';

// 99acres-style login: mobile + OTP is the primary tab, email + password secondary.
class LoginScreen extends ConsumerStatefulWidget {
  final String? next;
  const LoginScreen({super.key, this.next});
  @override
  ConsumerState<LoginScreen> createState() => _LoginState();
}

class _LoginState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  final _emailForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  final _phone = TextEditingController();
  String? _phoneError;
  OtpChallenge? _challenge;
  String _code = '';
  int _cooldownUntil = 0;
  Timer? _ticker;

  bool _pending = false;
  String? _serverError;

  @override
  void dispose() {
    _tabs.dispose();
    _email.dispose();
    _pass.dispose();
    _phone.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  void _fail(Object e, String fallback) {
    setState(() => _serverError = apiErrorMessage(e, fallback));
  }

  void _goHome() {
    if (!mounted) return;
    context.go(widget.next ?? ref.read(authStoreProvider).homeRoute);
  }

  Future<void> _submitEmail() async {
    if (_pending) return;
    FocusScope.of(context).unfocus();
    setState(() => _serverError = null);
    if (!_emailForm.currentState!.validate()) return;
    setState(() => _pending = true);
    try {
      await ref.read(authStoreProvider.notifier).login(_email.text, _pass.text);
      _goHome();
    } catch (e) {
      _fail(e, 'Login failed. Please try again.');
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  Future<void> _sendOtp() async {
    if (_pending) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _serverError = null;
      _phoneError = mobileValidator(_phone.text);
    });
    if (_phoneError != null) return;
    setState(() => _pending = true);
    try {
      final c = await ref.read(authStoreProvider.notifier).requestOtp(_phone.text);
      setState(() {
        _challenge = c;
        _code = '';
        _cooldownUntil = DateTime.now().millisecondsSinceEpoch + 60_000;
      });
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } catch (e) {
      _fail(e, 'Could not send the code. Please try again.');
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  Future<void> _submitOtp() async {
    final challenge = _challenge;
    if (_pending || challenge == null || _code.length != 6) return;
    setState(() => _pending = true);
    setState(() => _serverError = null);
    try {
      final v = await ref.read(authStoreProvider.notifier).verifyOtp(challenge.phone, _code);
      if (!mounted) return;
      if (v.isNewUser) {
        context.push('/register');
        return;
      }
      await ref.read(authStoreProvider.notifier).loginWithOtp(v.otpToken);
      _goHome();
    } catch (e) {
      _fail(e, 'Verification failed. Please try again.');
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cooldownLeft =
        ((_cooldownUntil - DateTime.now().millisecondsSinceEpoch) / 1000).ceil().clamp(0, 999);
    return Scaffold(
      appBar: AppBar(title: const Text('Log in')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Welcome back',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Log in to search, save and manage properties.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabs,
                  onTap: (_) => setState(() => _serverError = null),
                  tabs: const [Tab(text: 'Mobile OTP'), Tab(text: 'Email')],
                ),
                const SizedBox(height: 16),
                if (_serverError != null) ...[
                  ErrorBanner(message: _serverError!),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Error details'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: SingleChildScrollView(
                              child: SelectableText(
                                AppLog.entries.reversed.take(25).toList().reversed.join('\n'),
                                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
                          ],
                        ),
                      ),
                      child: const Text('Details'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  height: 380,
                  child: TabBarView(
                    controller: _tabs,
                    children: [_otpTab(cooldownLeft), _emailTab()],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('New here?'),
                      TextButton(
                        onPressed: _pending ? null : () => context.push('/register'),
                        child: const Text('Create account')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _otpTab(int cooldownLeft) {
    final challenge = _challenge;
    if (challenge == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _phone,
            label: 'Mobile number',
            hint: '+91 98765 43210',
            keyboardType: TextInputType.phone,
            validator: (_) => _phoneError,
          ),
          const SizedBox(height: 12),
          AppButton(label: 'Send OTP', loading: _pending, onPressed: _sendOtp),
          const SizedBox(height: 8),
          const Text('New number? We will create your account after verification.',
              textAlign: TextAlign.center),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Code sent to ${challenge.maskedPhone}'),
            TextButton(
              onPressed: _pending
                  ? null
                  : () => setState(() {
                        _challenge = null;
                        _code = '';
                      }),
              child: const Text('Change'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OtpBoxes(enabled: !_pending, onChanged: (v) => setState(() => _code = v)),
        if (challenge.devCode != null) ...[
          const SizedBox(height: 8),
          Text('Dev mode — your code is ${challenge.devCode}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
        ],
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            cooldownLeft > 0
                ? Text('Resend code in ${cooldownLeft}s')
                : TextButton(onPressed: _pending ? null : _sendOtp, child: const Text('Resend code')),
          ],
        ),
        const SizedBox(height: 4),
        AppButton(label: 'Verify & log in', loading: _pending, onPressed: _code.length == 6 ? _submitOtp : null),
      ],
    );
  }

  Widget _emailTab() {
    return Form(
      key: _emailForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _email,
            label: 'Email',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            validator: emailValidator,
          ),
          const SizedBox(height: 12),
          PasswordField(
            controller: _pass,
            label: 'Password',
            validator: (v) => requiredValidator(v, 'Password'),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Reset password'),
                  content: const Text(
                    'Self-service password reset is not available in this release. '
                    'Please email support from your registered address and we will help.',
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
                ),
              ),
              child: const Text('Forgot password?'),
            ),
          ),
          AppButton(label: 'Log in', loading: _pending, onPressed: _submitEmail),
        ],
      ),
    );
  }
}
