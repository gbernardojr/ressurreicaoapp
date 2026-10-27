import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/client_data.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/message_banner.dart';
import '../login_screen.dart';
import 'admin_alterar_senha_screen.dart';
import 'admin_cliente_screen.dart';
import 'admin_gerenciar_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final ClientData data;

  const AdminDashboardScreen({super.key, required this.data});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _buscaController = TextEditingController();
  List<Map<String, dynamic>> _resultados = [];
  bool _buscando = false;
  bool _buscou = false;
  String? _erro;

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void _limpar() {
    FocusScope.of(context).unfocus();
    setState(() {
      _buscaController.clear();
      _resultados = [];
      _erro = null;
      _buscou = false;
    });
  }

  Future<void> _sair() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _buscar() async {
    FocusScope.of(context).unfocus();

    final raw = _buscaController.text.trim();
    final digits = onlyDigits(raw);
    final variantes = variantesCodigo(raw);

    setState(() {
      _erro = null;
      _resultados = [];
      _buscou = false;
    });

    if (raw.isEmpty) {
      setState(() => _erro = 'Digite o CPF, CNPJ ou Número do Jazigo/Código');
      return;
    }

    setState(() => _buscando = true);

    try {
      final sb = Supabase.instance.client;
      final conditions = <String>[];
      final temLetras = RegExp(r'[A-Za-z]').hasMatch(raw);

      if (!temLetras && (digits.length == 11 || digits.length == 14)) {
        conditions.add('cpf_cnpj.eq.$digits');
      }

      for (final variante in variantes) {
        conditions.add('codigo_propri.eq.$variante');
      }

      final busca = await sb
          .from('clientes')
          .select('id, codigo_propri, cpf_cnpj, nome, telefone, email, endereco, bairro, cidade, estado')
          .or(conditions.join(','))
          .limit(20);

      _resultados = busca.map((c) => Map<String, dynamic>.from(c)).toList();

      if (_resultados.isEmpty) {
        final jazigoConds = variantes.map((v) => 'jazigo.eq.$v').toList();

        final buscaJazigo = await sb
            .from('mensalidades')
            .select('cliente_id')
            .or(jazigoConds.join(','))
            .limit(20);

        final ids = <String>{};
        for (final row in buscaJazigo) {
          final id = row['cliente_id'];
          if (id != null) ids.add(id.toString());
        }

        if (ids.isNotEmpty) {
          final clientes = await sb
              .from('clientes')
              .select('id, codigo_propri, cpf_cnpj, nome, telefone, email, endereco, bairro, cidade, estado')
              .inFilter('id', ids.toList());
          _resultados = clientes.map((c) => Map<String, dynamic>.from(c)).toList();
        }
      }

      setState(() => _buscou = true);
    } catch (_) {
      setState(() => _erro = 'Erro na consulta. Tente novamente.');
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  void _abrirCliente(Map<String, dynamic> cliente) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminClienteScreen(
          cliente: cliente,
          configBanco: widget.data.configBanco,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminNome = (widget.data.adminUser?['nome'] ?? 'Administrador').toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Ressurreição'),
        backgroundColor: skyBlueDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _buscando ? null : _limpar,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: _sair,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Olá, $adminNome',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.search, color: skyBlueDark),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Consulta de Clientes / Jazigos',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Digite o CPF, CNPJ ou Número do Jazigo (Código) do cliente para acessar os boletos.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _buscaController,
                      maxLength: 18,
                      onChanged: (value) {
                        final formatted = formatCpfCnpj(value);
                        _buscaController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      },
                      onSubmitted: (_) => _buscando ? null : _buscar(),
                      decoration: const InputDecoration(
                        labelText: 'CPF, CNPJ ou Jazigo',
                        hintText: 'ex: 0252 ou 0123-A',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _buscando ? null : _buscar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: skyBlueDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _buscando
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'BUSCAR',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 12),
                      MessageBanner(message: _erro!),
                    ],
                  ],
                ),
              ),
            ),
            if (_resultados.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Clientes / Jazigos encontrados:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._resultados.map((c) => _ClienteResultadoCard(
                    cliente: c,
                    onTap: () => _abrirCliente(c),
                  )),
            ] else if (_buscou && !_buscando) ...[
              const SizedBox(height: 32),
              Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Nenhum cliente ou jazigo encontrado com essa informação.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminAlterarSenhaScreen(
                              nome: adminNome,
                              email: (widget.data.user?.email ??
                                      widget.data.adminUser?['email'] ??
                                      '')
                                  .toString(),
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.key),
                        label: const Text('Alterar Minha Senha'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: skyBlueDark,
                          side: const BorderSide(color: skyBlueDark),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AdminGerenciarScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Gerenciar Administradores'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: skyBlueDark,
                          side: const BorderSide(color: skyBlueDark),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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

class _ClienteResultadoCard extends StatelessWidget {
  final Map<String, dynamic> cliente;
  final VoidCallback onTap;

  const _ClienteResultadoCard({required this.cliente, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nome = (cliente['nome'] ?? '').toString();
    final cpf = onlyDigits((cliente['cpf_cnpj'] ?? '').toString());
    final cidade = (cliente['cidade'] ?? '').toString();
    final estado = (cliente['estado'] ?? '').toString();
    final codigo = (cliente['codigo_propri'] ?? '-').toString();
    final cpfTexto = cpf.isEmpty ? '' : ' | CPF/CNPJ: ${formatCpfCnpj(cpf)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: skyBlueDark,
                foregroundColor: Colors.white,
                child: Text(nome.isEmpty ? '?' : nome[0].toUpperCase()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome.isEmpty ? '-' : nome,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Jazigo / Cód: $codigo$cpfTexto',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    if (cidade.isNotEmpty)
                      Text(
                        '$cidade/$estado',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: skyBlueDark),
            ],
          ),
        ),
      ),
    );
  }
}
