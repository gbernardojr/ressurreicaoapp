import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/client_data.dart';
import '../theme/app_colors.dart';
import '../utils/auth_utils.dart';
import '../utils/formatters.dart';
import '../widgets/message_banner.dart';
import '../widgets/password_field.dart';
import 'admin/admin_login_screen.dart';
import 'dashboard_screen.dart';
import 'esqueci_senha_screen.dart';
import 'primeiro_acesso_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _cpfController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _cpfController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();
    final cpf = onlyDigits(_cpfController.text);
    final senha = _senhaController.text;

    setState(() => _erro = null);

    if (cpf.isEmpty || senha.isEmpty) {
      setState(() => _erro = 'Preencha todos os campos');
      return;
    }
    if (cpf.length != 11) {
      setState(() => _erro = 'CPF inválido');
      return;
    }

    setState(() => _carregando = true);

    try {
      final sb = Supabase.instance.client;
      final clientes = await sb
          .from('clientes')
          .select('id, email, nome, cpf_cnpj')
          .eq('cpf_cnpj', cpf);

      if (clientes.isEmpty) {
        setState(() => _erro = 'CPF não encontrado');
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
      final email = emailCadastrado.isNotEmpty ? emailCadastrado : '$cpf@sememail.com.br';

      await sb.auth.signInWithPassword(email: email, password: senha);

      final data = ClientData();
      await data.load();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DashboardScreen(data: data)),
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _erro = mapAuthError(e));
    } catch (_) {
      if (mounted) setState(() => _erro = 'Erro ao conectar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [skyBlue, skyBlueLight],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ressurreição',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Consulta de Mensalidades',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          TextField(
                            controller: _cpfController,
                            keyboardType: TextInputType.number,
                            maxLength: 14,
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
                          const SizedBox(height: 16),
                          PasswordField(
                            controller: _senhaController,
                            hint: 'Sua senha de acesso',
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _carregando ? null : _entrar(),
                          ),
                          if (_erro != null) ...[
                            const SizedBox(height: 16),
                            MessageBanner(message: _erro!),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _carregando ? null : _entrar,
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
                                  : const Text(
                                      'ENTRAR',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const EsqueciSenhaScreen()),
                            ),
                            child: const Text('Esqueci minha senha'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PrimeiroAcessoScreen()),
                            ),
                            child: const Text('Primeiro acesso? Cadastre sua senha'),
                          ),
                          const Divider(height: 24),
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                            ),
                            icon: const Icon(Icons.lock_outline, size: 18),
                            label: const Text('Área Restrita'),
                          ),
                        ],
                      ),
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
}
