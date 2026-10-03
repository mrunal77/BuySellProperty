import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth_store.dart';
import '../../../core/validators.dart';
import '../../../core/widgets.dart';

const _types = ['Customer', 'Owner', 'Agent', 'Builder'];

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterState();
}

class _RegisterState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  String _type = 'Customer';
  bool _terms = false;
  bool _pending = false;
  String? _serverError;

  // Inline OTP verification state (direct arrivals).
  String _code = '';
  OtpChallenge? _challenge;

  bool get _phoneVerified {
    final pending = ref.read(authStoreProvider.notifier).pendingOtp;
    return pending != null && pending.phone == _phone.text.trim() && _phone.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    final pending = ref.read(authStoreProvider.notifier).pendingOtp;
    if (pending != null) _phone.text = pending.phone;
  }

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_pending) return;
    final err = mobileValidator(_phone.text);
    if (err != null) {
      setState(() => _serverError = err);
      return;
    }
    setState(() {
      _pending = true;
      _serverError = null;
    });
    try {
      final c = await ref.read(authStoreProvider.notifier).requestOtp(_phone.text);
      setState(() {
        _challenge = c;
        _code = '';
      });
    } catch (e) {
      setState(() => _serverError = apiErrorMessage(e, 'Could not send the code.'));
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  Future<void> _verifyCode() async {
    final challenge = _challenge;
    if (_pending || challenge == null || _code.length != 6) return;
    setState(() => _pending = true);
    setState(() => _serverError = null);
    try {
      final v = await ref.read(authStoreProvider.notifier).verifyOtp(challenge.phone, _code);
      if (!mounted) return;
      if (!v.isNewUser) {
        setState(() => _serverError = 'This number is already registered. Please log in with OTP.');
        return;
      }
      setState(() {
        _challenge = null;
        _code = '';
      });
    } catch (e) {
      setState(() => _serverError = apiErrorMessage(e, 'Verification failed.'));
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  Future<void> _submit() async {
    if (_pending) return;
    FocusScope.of(context).unfocus();
    setState(() => _serverError = null);
    if (!_form.currentState!.validate()) return;
    if (!_terms) {
      setState(() => _serverError = 'Please accept the Terms & Privacy Policy.');
      return;
    }
    setState(() => _pending = true);
    try {
      final store = ref.read(authStoreProvider.notifier);
      if (_phoneVerified) {
        await store.registerWithOtp(_phone.text, _email.text, _pass.text, _type);
      } else {
        await store.register(_email.text, _pass.text, _type, _phone.text);
      }
      if (!mounted) return;
      context.go(ref.read(authStoreProvider).homeRoute);
    } catch (e) {
      setState(() => _serverError = apiErrorMessage(e, 'Registration failed. Please try again.'));
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final verified = _phoneVerified;
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Join BuySellProperty',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Buy, sell, rent — or list your property for free.',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 20),
                  if (_serverError != null) ...[
                    ErrorBanner(message: _serverError!),
                    const SizedBox(height: 12),
                  ],
                  AppTextField(
                      controller: _email,
                      label: 'Email',
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: emailValidator),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _phone,
                    label: 'Mobile (Optional)',
                    hint: '+91 98765 43210',
                    keyboardType: TextInputType.phone,
                    validator: phoneValidator,
                  ),
                  if (verified)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(children: [
                        Icon(Icons.verified, color: Colors.green, size: 18),
                        SizedBox(width: 4),
                        Text('Mobile verified', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                      ]),
                    )
                  else if (_challenge == null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _pending ? null : _sendCode,
                        child: const Text('Verify via OTP'),
                      ),
                    )
                  else ...[
                    const SizedBox(height: 8),
                    Text('Code sent to ${_challenge!.maskedPhone}',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    OtpBoxes(enabled: !_pending, onChanged: (v) => setState(() => _code = v)),
                    if (_challenge!.devCode != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('Dev mode — your code is ${_challenge!.devCode}',
                            style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
                      ),
                    const SizedBox(height: 8),
                    AppButton(label: 'Verify number', loading: _pending,
                        onPressed: _code.length == 6 ? _verifyCode : null),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'I am a', border: OutlineInputBorder()),
                    items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _type = v ?? 'Customer'),
                  ),
                  const SizedBox(height: 12),
                  PasswordField(controller: _pass, label: 'Password', validator: passwordValidator),
                  const SizedBox(height: 8),
                  StrengthMeter(score: passwordScore(_pass.text)),
                  ValueListenableBuilder(
                    valueListenable: _pass,
                    builder: (_, __, ___) => Text(
                      _pass.text.isEmpty ? '' : 'Strength: ${passwordLabel(passwordScore(_pass.text))}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PasswordField(
                    controller: _confirm,
                    label: 'Confirm password',
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please repeat your password.';
                      if (v != _pass.text) return 'Passwords do not match.';
                      return null;
                    },
                  ),
                  CheckboxListTile(
                    value: _terms,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('I accept the Terms of Use and Privacy Policy.',
                        style: TextStyle(fontSize: 14)),
                    onChanged: (v) => setState(() => _terms = v ?? false),
                  ),
                  const SizedBox(height: 4),
                  AppButton(label: 'Create account', loading: _pending, onPressed: _submit),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already registered?'),
                      TextButton(
                          onPressed: _pending ? null : () => context.push('/login'),
                          child: const Text('Log in')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
