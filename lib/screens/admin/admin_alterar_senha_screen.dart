import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import '../../widgets/message_banner.dart';
import '../../widgets/password_field.dart';

class AdminAlterarSenhaScreen extends StatefulWidget {
  final String nome;
  final String email;

  const AdminAlterarSenhaScreen({
    super.key,
    required this.nome,
    required this.email,
  });

  @override
  State<AdminAlterarSenhaScreen> createState() => _AdminAlterarSenhaScreenState();
}

class _AdminAlterarSenhaScreenState extends State<AdminAlterarSenhaScreen> {
  final _atualController = TextEditingController();
  final _novaController = TextEditingController();
  final _confirmaController = TextEditingController();
  bool _carregando = false;
  String? _erro;
  String? _sucesso;

  @override
  void dispose() {
    _atualController.dispose();
    _novaController.dispose();
    _confirmaController.dispose();
    super.dispose();
  }

  Future<void> _alterarSenha() async {
    FocusScope.of(context).unfocus();
    final atual = _atualController.text;
    final nova = _novaController.text;
    final confirma = _confirmaController.text;

    setState(() {
      _erro = null;
      _sucesso = null;
    });

    if (atual.isEmpty || nova.isEmpty || confirma.isEmpty) {
      setState(() => _erro = 'Preencha todos os campos');
      return;
    }
    if (nova.length < 6) {
      setState(() => _erro = 'Nova senha deve ter pelo menos 6 caracteres');
      return;
    }
    if (nova != confirma) {
      setState(() => _erro = 'As senhas não conferem');
      return;
    }

    setState(() => _carregando = true);

    try {
      final sb = Supabase.instance.client;
      final email = sb.auth.currentUser?.email ?? widget.email;
      if (email.isEmpty) {
        setState(() => _erro = 'Usuário não autenticado');
        return;
      }

      try {
        await sb.auth.signInWithPassword(email: email, password: atual);
      } on AuthException {
        setState(() => _erro = 'Senha atual incorreta.');
        return;
      }

      await sb.auth.updateUser(UserAttributes(password: nova));

      if (!mounted) return;
      _atualController.clear();
      _novaController.clear();
      _confirmaController.clear();
      setState(() => _sucesso = 'Senha do administrador alterada com sucesso!');
    } on AuthException catch (e) {
      setState(() => _erro = 'Erro ao alterar senha: ${e.message}');
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
        title: const Text('Alterar Senha do Admin'),
        backgroundColor: skyBlueDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.key, color: skyBlueDark),
                    SizedBox(width: 8),
                    Text(
                      'Alterar Minha Senha',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: skyBlueDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Usuário atual: ${widget.nome} (${widget.email})',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                PasswordField(
                  controller: _atualController,
                  label: 'Senha Atual',
                  hint: 'Sua senha atual',
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _novaController,
                  label: 'Nova Senha',
                  hint: 'Mínimo 6 caracteres',
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _confirmaController,
                  label: 'Confirmar Nova Senha',
                  hint: 'Repita a nova senha',
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
                    onPressed: _carregando ? null : _alterarSenha,
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
                            'ALTERAR SENHA',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
