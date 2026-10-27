import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/message_banner.dart';

class EsqueciSenhaScreen extends StatefulWidget {
  const EsqueciSenhaScreen({super.key});

  @override
  State<EsqueciSenhaScreen> createState() => _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends State<EsqueciSenhaScreen> {
  final _cpfController = TextEditingController();
  bool _carregando = false;
  bool _enviado = false;
  String? _erro;
  String? _sucesso;

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    final cpf = onlyDigits(_cpfController.text);

    setState(() {
      _erro = null;
      _sucesso = null;
    });

    if (cpf.length != 11) {
      setState(() => _erro = 'CPF inválido');
      return;
    }

    setState(() => _carregando = true);

    try {
      final sb = Supabase.instance.client;
      final clientes = await sb
          .from('clientes')
          .select('id, email, nome')
          .eq('cpf_cnpj', cpf);

      if (clientes.isEmpty) {
        setState(() => _erro = 'CPF não encontrado');
        return;
      }

      Map<String, dynamic>? cliente;
      for (final c in clientes) {
        if ((c['email'] ?? '').toString().isNotEmpty) {
          cliente = c;
          break;
        }
      }
      cliente ??= clientes.first;

      final email = (cliente['email'] ?? '').toString().trim();
      if (email.isEmpty) {
        setState(() {
          _erro = 'Cliente sem e-mail cadastrado. Não é possível recuperar a senha sem e-mail. '
              'Procure a recepção para cadastrar um e-mail.';
        });
        return;
      }

      await sb.auth.resetPasswordForEmail(
        email,
        redirectTo: AppConfig.passwordResetUrl,
      );

      setState(() {
        _sucesso = 'Link de redefinição enviado para $email.';
        _enviado = true;
      });
    } on AuthException catch (e) {
      final mensagem = e.message.toLowerCase();
      setState(() {
        _erro = mensagem.contains('not confirmed')
            ? 'E-mail ainda não foi confirmado. Verifique sua caixa de entrada.'
            : 'Erro ao enviar e-mail. Tente novamente.';
      });
    } catch (_) {
      setState(() => _erro = 'Erro ao conectar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Senha'),
        backgroundColor: skyBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recuperar senha', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Informe seu CPF para receber um link de redefinição de senha no e-mail cadastrado.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _cpfController,
              keyboardType: TextInputType.number,
              maxLength: 14,
              enabled: !_enviado,
              onChanged: (value) {
                final formatted = formatCpf(value);
                _cpfController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              },
              decoration: const InputDecoration(
                labelText: 'CPF',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
                hintText: '000.000.000-00',
                counterText: '',
              ),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 16),
              MessageBanner(message: _erro!),
            ],
            if (_sucesso != null) ...[
              const SizedBox(height: 16),
              MessageBanner(message: _sucesso!, success: true),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _carregando || _enviado ? null : _enviar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: skyBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _carregando
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _enviado ? 'ENVIADO' : 'ENVIAR LINK',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Voltar ao login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
