import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/client_data.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/message_banner.dart';
import '../widgets/password_field.dart';
import 'dashboard_screen.dart';

class PrimeiroAcessoScreen extends StatefulWidget {
  const PrimeiroAcessoScreen({super.key});

  @override
  State<PrimeiroAcessoScreen> createState() => _PrimeiroAcessoScreenState();
}

class _PrimeiroAcessoScreenState extends State<PrimeiroAcessoScreen> {
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmaController = TextEditingController();
  bool _carregando = false;
  String? _erro;
  String? _sucesso;

  @override
  void dispose() {
    _cpfController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    FocusScope.of(context).unfocus();
    final documento = onlyDigits(_cpfController.text);
    final emailInformado = _emailController.text.trim().toLowerCase();
    final senha = _senhaController.text;
    final confirma = _confirmaController.text;

    setState(() {
      _erro = null;
      _sucesso = null;
    });

    if (documento.isEmpty || senha.isEmpty || confirma.isEmpty) {
      setState(() => _erro = 'Preencha todos os campos');
      return;
    }
    if (!documentoValido(documento)) {
      setState(() => _erro = 'Informe um CPF ou CNPJ válido');
      return;
    }
    if (senha.length < 6) {
      setState(() => _erro = 'Senha deve ter pelo menos 6 caracteres');
      return;
    }
    if (senha != confirma) {
      setState(() => _erro = 'As senhas não conferem');
      return;
    }

    setState(() => _carregando = true);

    try {
      final sb = Supabase.instance.client;
      final clientes = await sb
          .from('clientes')
          .select('id, email, cpf_cnpj')
          .eq('cpf_cnpj', documento);

      if (clientes.isEmpty) {
        setState(() => _erro = 'CPF/CNPJ não encontrado. Procure a recepção.');
        return;
      }

      Map<String, dynamic> cliente = clientes.first;
      for (final c in clientes) {
        if ((c['email'] ?? '').toString().isNotEmpty) {
          cliente = c;
          break;
        }
      }

      final emailCadastrado = (cliente['email'] ?? '').toString().trim();
      final emailFinal = emailCadastrado.isNotEmpty
          ? emailCadastrado
          : (emailInformado.isNotEmpty ? emailInformado : '$documento@sememail.com.br');

      final auth = await sb.auth.signUp(email: emailFinal, password: senha);
      if (auth.user == null) {
        setState(() => _erro = 'O cadastro não pôde ser concluído no momento.');
        return;
      }

      if (emailCadastrado.isEmpty && emailInformado.isNotEmpty) {
        await sb.from('clientes').update({'email': emailInformado}).eq('id', cliente['id']);
      }

      try {
        await sb.auth.signInWithPassword(email: emailFinal, password: senha);
        final data = ClientData();
        await data.load();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => DashboardScreen(data: data)),
          (route) => false,
        );
        return;
      } on AuthException {
        setState(() {
          _sucesso = 'Conta criada! Verifique seu e-mail para confirmar o acesso. '
              'Se não encontrar, confira a caixa de spam.';
        });
      }
    } on AuthException catch (e) {
      final mensagem = e.message.toLowerCase();
      if (mensagem.contains('already') ||
          mensagem.contains('registered') ||
          mensagem.contains('exists')) {
        setState(() {
          _erro = 'Esta conta já possui cadastro. Use a opção "Esqueci minha senha" no login.';
        });
      } else {
        setState(() => _erro = 'Erro ao criar conta: ${e.message}');
      }
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
        title: const Text('Primeiro Acesso'),
        backgroundColor: skyBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cadastre sua senha', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Informe seu CPF ou CNPJ para criar sua conta. O e-mail é opcional.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _cpfController,
              keyboardType: TextInputType.number,
              maxLength: 18,
              onChanged: (value) {
                final formatted = formatCpfCnpj(value);
                _cpfController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              },
              decoration: const InputDecoration(
                labelText: 'CPF ou CNPJ',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
                hintText: 'CPF ou CNPJ',
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail (opcional)',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
                hintText: 'seu@email.com',
              ),
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _senhaController,
              label: 'Nova Senha',
              hint: 'Mínimo 6 caracteres',
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _confirmaController,
              label: 'Confirmar Senha',
              hint: 'Repita a senha',
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
                onPressed: _carregando ? null : _cadastrar,
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
                    : const Text('CADASTRAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Já tem conta? Faça login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
