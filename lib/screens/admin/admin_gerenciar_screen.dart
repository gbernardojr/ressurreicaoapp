import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import '../../utils/auth_utils.dart';
import '../../utils/formatters.dart';
import '../../widgets/message_banner.dart';
import '../../widgets/password_field.dart';

class AdminGerenciarScreen extends StatefulWidget {
  const AdminGerenciarScreen({super.key});

  @override
  State<AdminGerenciarScreen> createState() => _AdminGerenciarScreenState();
}

class _AdminGerenciarScreenState extends State<AdminGerenciarScreen> {
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  List<Map<String, dynamic>> _admins = [];
  bool _carregandoLista = true;
  String? _erroLista;
  bool _cadastrando = false;
  String? _erroForm;
  String? _sucessoForm;

  @override
  void initState() {
    super.initState();
    _carregarLista();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _carregarLista() async {
    setState(() {
      _carregandoLista = true;
      _erroLista = null;
    });
    try {
      final rows = await Supabase.instance.client
          .from('admin_usuarios')
          .select('*')
          .order('nome', ascending: true);
      if (!mounted) return;
      setState(() {
        _admins = rows.map((a) => Map<String, dynamic>.from(a)).toList();
      });
    } catch (_) {
      if (mounted) setState(() => _erroLista = 'Erro ao carregar lista.');
    } finally {
      if (mounted) setState(() => _carregandoLista = false);
    }
  }

  Future<void> _cadastrar() async {
    FocusScope.of(context).unfocus();

    final nome = _nomeController.text.trim();
    final cpf = onlyDigits(_cpfController.text);
    final email = _emailController.text.trim().toLowerCase();
    final senha = _senhaController.text;

    setState(() {
      _erroForm = null;
      _sucessoForm = null;
    });

    if (nome.isEmpty) {
      setState(() => _erroForm = 'Informe o nome do administrador');
      return;
    }
    if (cpf.length != 11) {
      setState(() => _erroForm = 'CPF inválido');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _erroForm = 'Email inválido');
      return;
    }
    if (senha.length < 6) {
      setState(() => _erroForm = 'Senha deve ter pelo menos 6 caracteres');
      return;
    }

    setState(() => _cadastrando = true);

    try {
      final sb = Supabase.instance.client;

      final existente = await sb
          .from('admin_usuarios')
          .select('id')
          .or('cpf.eq.$cpf,email.eq.$email')
          .limit(1)
          .maybeSingle();

      if (existente != null) {
        setState(() => _erroForm = 'Este CPF ou E-mail já é administrador.');
        return;
      }

      try {
        await signUpPreservingSession(sb, email: email, password: senha);
      } on AuthException catch (e) {
        final mensagem = e.message.toLowerCase();
        final jaExiste = mensagem.contains('already') ||
            mensagem.contains('registered') ||
            mensagem.contains('exists');
        if (!jaExiste) {
          setState(() => _erroForm = 'Erro ao criar conta Auth: ${e.message}');
          return;
        }
      }

      try {
        await sb.from('admin_usuarios').insert({
          'nome': nome,
          'email': email,
          'cpf': cpf,
          'ativo': true,
        });
      } catch (e) {
        final mensagem = e.toString().toLowerCase();
        final erroPermissao = mensagem.contains('row-level security') ||
            mensagem.contains('rls') ||
            mensagem.contains('violates');
        setState(() {
          _erroForm = erroPermissao
              ? 'Erro de permissão no Supabase: a tabela admin_usuarios bloqueou a inserção. '
                  'Verifique as políticas de acesso (RLS) da tabela.'
              : 'Erro ao cadastrar admin: $e';
        });
        return;
      }

      if (!mounted) return;
      _cpfController.clear();
      _nomeController.clear();
      _emailController.clear();
      _senhaController.clear();
      setState(() => _sucessoForm = '$nome cadastrado como administrador com sucesso!');
      await _carregarLista();
    } catch (_) {
      setState(() => _erroForm = 'Erro ao conectar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _cadastrando = false);
    }
  }

  Future<void> _desativar(Map<String, dynamic> admin) async {
    final nome = (admin['nome'] ?? '').toString();
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desativar administrador'),
        content: Text(
          'Desativar o administrador "$nome"? Ele não poderá mais acessar como admin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: dangerRed),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );

    if (confirmou != true) return;

    try {
      await Supabase.instance.client
          .from('admin_usuarios')
          .update({'ativo': false}).eq('id', admin['id']);
      await _carregarLista();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao desativar administrador.')),
        );
      }
    }
  }

  Future<void> _ativar(Map<String, dynamic> admin) async {
    try {
      await Supabase.instance.client
          .from('admin_usuarios')
          .update({'ativo': true}).eq('id', admin['id']);
      await _carregarLista();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao ativar administrador.')),
        );
      }
    }
  }

  Future<void> _excluir(Map<String, dynamic> admin) async {
    final nome = (admin['nome'] ?? '').toString();
    final email = (admin['email'] ?? '').toString();

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir administrador'),
        content: Text(
          'ATENÇÃO: excluir permanentemente o administrador "$nome"?\n\n'
          'Esta ação não pode ser desfeita. O usuário será removido da lista de '
          'administradores e do sistema de autenticação.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: dangerRed),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmou != true) return;

    try {
      final sb = Supabase.instance.client;

      await sb.from('admin_usuarios').delete().eq('id', admin['id']);

      var authAviso = '';
      try {
        await sb.rpc('excluir_admin_auth', params: {'p_email': email});
      } catch (e) {
        final mensagem = e.toString();
        if (mensagem.contains('Could not find') || mensagem.contains('PGRST202')) {
          authAviso = '\n\nA conta de autenticação NÃO foi removida automaticamente '
              'porque a função RPC "excluir_admin_auth" ainda não foi criada no Supabase.';
        } else {
          authAviso = '\n\nO administrador foi removido da lista, mas houve erro ao '
              'remover do Authentication.';
        }
      }

      await _carregarLista();

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Administrador excluído'),
          content: Text('Administrador "$nome" excluído com sucesso!$authAviso'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir administrador: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Admins'),
        backgroundColor: skyBlueDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_carregandoLista)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_erroLista != null)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(_erroLista!, style: const TextStyle(color: dangerRed)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _carregarLista,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Administradores (${_admins.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_admins.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'Nenhum administrador cadastrado.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        )
                      else
                        ..._admins.map(_buildAdminItem),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Novo Administrador',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cadastre os dados do novo administrador abaixo. '
                      'O cadastro de administradores é independente do cadastro de clientes.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Administrador',
                        hintText: 'Nome completo',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                        hintText: '000.000.000-00',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email do Administrador',
                        hintText: 'email@exemplo.com',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _senhaController,
                      label: 'Senha temporária',
                      hint: 'Mínimo 6 caracteres',
                    ),
                    if (_erroForm != null) ...[
                      const SizedBox(height: 16),
                      MessageBanner(message: _erroForm!),
                    ],
                    if (_sucessoForm != null) ...[
                      const SizedBox(height: 16),
                      MessageBanner(message: _sucessoForm!, success: true),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _cadastrando ? null : _cadastrar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: skyBlueDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _cadastrando
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'CADASTRAR ADMIN',
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

  Widget _buildAdminItem(Map<String, dynamic> admin) {
    final ativo = admin['ativo'] == true;
    final cpf = onlyDigits((admin['cpf'] ?? '').toString());

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (admin['nome'] ?? '-').toString(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  (admin['email'] ?? '-').toString(),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  cpf.isNotEmpty ? formatCpf(cpf) : 'Sem CPF',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  ativo ? 'Ativo' : 'Inativo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ativo ? successGreen : dangerRed,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: () => ativo ? _desativar(admin) : _ativar(admin),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    foregroundColor: ativo ? dangerRed : successGreen,
                    side: BorderSide(color: ativo ? dangerRed : successGreen),
                  ),
                  child: Text(
                    ativo ? 'Desativar' : 'Ativar',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: () => _excluir(admin),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    foregroundColor: const Color(0xFFB71C1C),
                    backgroundColor: const Color(0xFFFFEBEE),
                    side: const BorderSide(color: Color(0xFFB71C1C)),
                  ),
                  child: const Text('Excluir', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
