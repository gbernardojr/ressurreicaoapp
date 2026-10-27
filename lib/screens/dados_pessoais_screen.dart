import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/client_data.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../utils/links.dart';
import '../widgets/info_row.dart';
import '../widgets/message_banner.dart';
import '../widgets/password_field.dart';
import 'login_screen.dart';

class DadosPessoaisScreen extends StatefulWidget {
  final ClientData data;

  const DadosPessoaisScreen({super.key, required this.data});

  @override
  State<DadosPessoaisScreen> createState() => _DadosPessoaisScreenState();
}

class _DadosPessoaisScreenState extends State<DadosPessoaisScreen> {
  final _atualController = TextEditingController();
  final _novaController = TextEditingController();
  final _confirmaController = TextEditingController();
  bool _carregando = false;
  bool _excluindo = false;
  String? _erro;
  String? _sucesso;
  String? _erroExclusao;

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
      final email = sb.auth.currentUser?.email;
      if (email == null) {
        setState(() => _erro = 'Usuário não autenticado');
        return;
      }

      try {
        await sb.auth.signInWithPassword(email: email, password: atual);
      } on AuthException {
        setState(() => _erro = 'Senha atual incorreta');
        return;
      }

      await sb.auth.updateUser(UserAttributes(password: nova));

      if (!mounted) return;
      _atualController.clear();
      _novaController.clear();
      _confirmaController.clear();
      setState(() => _sucesso = 'Senha alterada com sucesso!');
    } on AuthException catch (e) {
      setState(() => _erro = 'Erro ao alterar senha: ${e.message}');
    } catch (_) {
      setState(() => _erro = 'Erro ao conectar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _excluirConta() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir minha conta'),
        content: const Text(
          'Sua conta de acesso será excluída definitivamente e você não poderá mais entrar '
          'no aplicativo.\n\n'
          'Os dados cadastrais e financeiros mantidos pelo cemitério (mensalidades, boletos '
          'e registros de sepultamento) permanecem armazenados por obrigação legal e '
          'contratual. Para solicitar a remoção desses dados, procure a administração do '
          'cemitério.\n\n'
          'Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('EXCLUIR CONTA'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    setState(() {
      _excluindo = true;
      _erroExclusao = null;
    });

    try {
      final sb = Supabase.instance.client;
      await sb.rpc('excluir_minha_conta');
      try {
        await sb.auth.signOut();
      } catch (_) {}

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Conta excluída'),
          content: const Text(
            'Sua conta foi excluída com sucesso. Você será direcionado para a tela de login.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on PostgrestException catch (e) {
      final detalhe = '${e.code ?? ''} ${e.message}'.toLowerCase();
      setState(() {
        _erroExclusao = detalhe.contains('pgrst202') || detalhe.contains('could not find the function')
            ? 'Exclusão indisponível: a função "excluir_minha_conta" ainda não foi criada no Supabase.'
            : 'Não foi possível excluir a conta: ${e.message}';
      });
    } on AuthException catch (e) {
      setState(() => _erroExclusao = 'Não foi possível concluir: ${e.message}');
    } catch (_) {
      setState(() => _erroExclusao = 'Erro ao conectar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _excluindo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.data.cliente;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dados Pessoais'),
        backgroundColor: skyBlue,
        foregroundColor: Colors.white,
      ),
      body: c == null
          ? const Center(child: Text('Dados do cliente não disponíveis.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: skyBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 40),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            (c['nome'] ?? '-').toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Código: ${c['codigo_propri'] ?? '-'}',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informações Cadastrais',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          InfoRow(label: 'Nome', value: c['nome'] ?? '-'),
                          InfoRow(
                            label: 'CPF/CNPJ',
                            value: formatCpfCnpj((c['cpf_cnpj'] ?? '').toString()),
                          ),
                          InfoRow(label: 'Telefone', value: c['telefone'] ?? '-'),
                          InfoRow(label: 'E-mail', value: c['email'] ?? '-'),
                          InfoRow(label: 'Endereço', value: c['endereco'] ?? '-'),
                          InfoRow(label: 'Cidade', value: c['cidade'] ?? '-'),
                          InfoRow(label: 'Estado', value: c['estado'] ?? '-'),
                          InfoRow(label: 'CEP', value: c['cep'] ?? '-'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Alterar Senha',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
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
                                backgroundColor: skyBlue,
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
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Conta e Privacidade',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.privacy_tip_outlined, color: skyBlue),
                            title: const Text('Política de Privacidade'),
                            subtitle: const Text('Saiba como seus dados são tratados'),
                            trailing: const Icon(Icons.open_in_new, size: 18),
                            onTap: () => abrirPoliticaPrivacidade(context),
                          ),
                          const Divider(),
                          const SizedBox(height: 4),
                          Text(
                            'Excluir a conta remove seu acesso ao aplicativo. Os registros '
                            'do cemitério são mantidos por obrigação legal.',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                          if (_erroExclusao != null) ...[
                            const SizedBox(height: 12),
                            MessageBanner(message: _erroExclusao!),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _excluindo ? null : _excluirConta,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(color: Colors.red.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: _excluindo
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.red.shade700,
                                      ),
                                    )
                                  : const Icon(Icons.delete_forever_outlined),
                              label: Text(
                                _excluindo ? 'EXCLUINDO...' : 'EXCLUIR MINHA CONTA',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
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
