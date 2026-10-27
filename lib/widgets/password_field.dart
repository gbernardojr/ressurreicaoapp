import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Senha',
    this.hint,
    this.enabled = true,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _oculta = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _oculta,
      enabled: widget.enabled,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: _oculta ? 'Mostrar senha' : 'Ocultar senha',
          icon: Icon(_oculta ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _oculta = !_oculta),
        ),
      ),
    );
  }
}
