import 'package:flutter/material.dart';

/// Reusable buttons / fields used by auth + listing screens.

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const AppButton({super.key, required this.label, required this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscure;
  final String? hint;
  final Widget? suffix;
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.hint,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(labelText: label, hintText: hint, suffixIcon: suffix),
    );
  }
}

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  const PasswordField({super.key, required this.controller, required this.label, this.validator});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      validator: widget.validator,
      obscure: !_show,
      suffix: IconButton(
        tooltip: _show ? 'Hide password' : 'Show password',
        icon: Icon(_show ? Icons.visibility_off : Icons.visibility),
        onPressed: () => setState(() => _show = !_show),
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: TextStyle(color: cs.onErrorContainer)),
    );
  }
}

class StrengthMeter extends StatelessWidget {
  final int score;
  const StrengthMeter({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    const colors = [Colors.red, Colors.orange, Colors.amber, Colors.lime, Colors.green];
    return Row(
      children: List.generate(4, (i) {
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: i < score ? colors[score] : Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        );
      }),
    );
  }
}

/// Six-box OTP entry (99acres-style verification). Reports the full code via [onChanged].
class OtpBoxes extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final bool enabled;
  const OtpBoxes({super.key, required this.onChanged, this.enabled = true});

  @override
  State<OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<OtpBoxes> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _emit() => widget.onChanged(_controllers.map((c) => c.text).join());

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 46,
          child: TextField(
            controller: _controllers[i],
            focusNode: _nodes[i],
            enabled: widget.enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(counterText: '', border: OutlineInputBorder()),
            onChanged: (v) {
              final d = v.replaceAll(RegExp(r'\D'), '');
              if (d != v) _controllers[i].text = d;
              if (d.isNotEmpty && i < 5) _nodes[i + 1].requestFocus();
              if (d.isEmpty && i > 0) _nodes[i - 1].requestFocus();
              _emit();
            },
          ),
        );
      }),
    );
  }
}
