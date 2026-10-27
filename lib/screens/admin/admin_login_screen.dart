import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/client_data.dart';
import '../../theme/app_colors.dart';
import '../../utils/auth_utils.dart';
import '../../utils/formatters.dart';
import '../../widgets/message_banner.dart';
import '../../widgets/password_field.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
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

      final adminReg = await sb
          .from('admin_usuarios')
          .select('email, ativo')
          .eq('cpf', cpf)
          .eq('ativo', true)
          .maybeSingle();

      String? email;
      final emailAdmin = (adminReg?['email'] ?? '').toString().trim();
      if (emailAdmin.isNotEmpty) {
        email = emailAdmin;
      } else {
        final clientesReg = await sb
            .from('clientes')
            .select('email')
            .eq('cpf_cnpj', cpf);
        for (final c in clientesReg) {
          final emailCliente = (c['email'] ?? '').toString().trim();
          if (emailCliente.isNotEmpty) {
            email = emailCliente;
            break;
          }
        }
      }

      if (email == null) {
        if (adminReg != null) {
          email = '$cpf@sememail.com.br';
        } else {
          final clientesReg = await sb
              .from('clientes')
              .select('id')
              .eq('cpf_cnpj', cpf)
              .limit(1);
          if (clientesReg.isNotEmpty) email = '$cpf@sememail.com.br';
        }
      }

      if (email == null) {
        setState(() => _erro = 'CPF de administrador não encontrado ou inativo.');
        return;
      }

      try {
        await sb.auth.signInWithPassword(email: email, password: senha);
      } on AuthException catch (e) {
        setState(() => _erro = mapAuthError(e, admin: true));
        return;
      }

      final data = ClientData();
      await data.load();

      if (!data.isAdmin) {
        await sb.auth.signOut();
        setState(() => _erro = 'Este usuário não possui acesso administrativo.');
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AdminDashboardScreen(data: data)),
        (route) => false,
      );
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
        title: const Text('Área Restrita'),
        backgroundColor: skyBlueDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.admin_panel_settings_outlined, size: 72, color: skyBlueDark),
            const SizedBox(height: 16),
            const Text(
              'Acesso Administrativo',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Entre com o CPF e a senha do administrador.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                        labelText: 'CPF do Administrador',
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
                          backgroundColor: skyBlueDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _carregando
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'ENTRAR COMO ADMIN',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
