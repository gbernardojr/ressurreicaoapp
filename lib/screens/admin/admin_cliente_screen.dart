import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import '../../utils/auth_utils.dart';
import '../../utils/formatters.dart';
import '../../widgets/aviso_boleto.dart';
import '../../widgets/message_banner.dart';
import '../mensalidade_detalhe_screen.dart';

enum _FiltroAdmin { todas, emAberto, vencido, pago }

class AdminClienteScreen extends StatefulWidget {
  final Map<String, dynamic> cliente;
  final Map<String, dynamic>? configBanco;

  const AdminClienteScreen({
    super.key,
    required this.cliente,
    this.configBanco,
  });

  @override
  State<AdminClienteScreen> createState() => _AdminClienteScreenState();
}

class _AdminClienteScreenState extends State<AdminClienteScreen> {
  List<Map<String, dynamic>> _mensalidades = [];
  List<Map<String, dynamic>> _falecidos = [];
  Map<String, List<Map<String, dynamic>>> _locaisPorFalecido = {};
  bool _carregando = true;
  String? _erro;
  _FiltroAdmin _filtro = _FiltroAdmin.todas;

  bool _criandoConta = false;
  String? _contaErro;
  String? _contaLogin;
  String? _contaSenha;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
      _filtro = _FiltroAdmin.todas;
    });

    try {
      final sb = Supabase.instance.client;
      final clienteId = widget.cliente['id'];

      final mensalidades = await sb
          .from('mensalidades')
          .select()
          .eq('cliente_id', clienteId)
          .order('vecto', ascending: true);

      final falecidos = await sb
          .from('falecidos')
          .select()
          .eq('cliente_id', clienteId)
          .order('nome', ascending: true);

      final locaisMap = <String, List<Map<String, dynamic>>>{};
      final falecidoIds = falecidos
          .map((f) => f['id'])
          .whereType<String>()
          .toList();

      if (falecidoIds.isNotEmpty) {
        final locais = await sb
            .from('falecido_locais')
            .select()
            .inFilter('falecido_id', falecidoIds)
            .order('data_inicio', ascending: false);

        for (final local in locais) {
          final falecidoId = local['falecido_id']?.toString();
          if (falecidoId == null) continue;
          locaisMap.putIfAbsent(falecidoId, () => []).add(
                Map<String, dynamic>.from(local),
              );
        }
      }

      if (!mounted) return;
      setState(() {
        _mensalidades = mensalidades.map((m) => Map<String, dynamic>.from(m)).toList();
        _falecidos = falecidos.map((f) => Map<String, dynamic>.from(f)).toList();
        _locaisPorFalecido = locaisMap;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Erro ao carregar dados do cliente.');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<Map<String, dynamic>> get _mensalidadesFiltradas {
    switch (_filtro) {
      case _FiltroAdmin.todas:
        return _mensalidades;
      case _FiltroAdmin.emAberto:
        return _mensalidades
            .where((m) => !mensalidadePaga(m) && !mensalidadeVencida(m))
            .toList();
      case _FiltroAdmin.vencido:
        return _mensalidades.where((m) => mensalidadeVencida(m)).toList();
      case _FiltroAdmin.pago:
        return _mensalidades.where((m) => mensalidadePaga(m)).toList();
    }
  }

  Future<void> _criarConta() async {
    final email = (widget.cliente['email'] ?? '').toString().trim();
    final documento = onlyDigits((widget.cliente['cpf_cnpj'] ?? '').toString());
    final login = documento.isNotEmpty ? formatCpfCnpj(documento) : email;
    final emailConta = email.isNotEmpty
        ? email
        : (documento.isNotEmpty ? '$documento@sememail.com.br' : '');

    if (emailConta.isEmpty) {
      setState(() => _contaErro = 'Cliente sem e-mail e sem CPF/CNPJ cadastrado.');
      return;
    }

    final senha = 'Ress@${DateTime.now().year}';

    setState(() {
      _criandoConta = true;
      _contaErro = null;
      _contaLogin = null;
      _contaSenha = null;
    });

    try {
      final sb = Supabase.instance.client;
      await signUpPreservingSession(sb, email: emailConta, password: senha);

      if (!mounted) return;
      setState(() {
        _contaLogin = login;
        _contaSenha = senha;
      });
    } on AuthException catch (e) {
      final mensagem = e.message.toLowerCase();
      if (mensagem.contains('already') ||
          mensagem.contains('registered') ||
          mensagem.contains('exists')) {
        setState(() {
          _contaErro = 'Conta já existe para este e-mail. '
              'O cliente pode usar "Esqueci minha senha" para redefinir.';
        });
      } else {
        setState(() => _contaErro = 'Erro: ${e.message}');
      }
    } catch (_) {
      setState(() => _contaErro = 'Erro ao conectar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _criandoConta = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cliente = widget.cliente;
    final nome = (cliente['nome'] ?? '').toString();
    final cpf = onlyDigits((cliente['cpf_cnpj'] ?? '').toString());
    final email = (cliente['email'] ?? '').toString().trim();
    final mensalidades = _mensalidadesFiltradas;

    return Scaffold(
      appBar: AppBar(
        title: Text(nome.isEmpty ? 'Cliente' : nome),
        backgroundColor: skyBlueDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _carregando ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_erro!, style: const TextStyle(color: dangerRed)),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _carregar,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: skyBlueDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              foregroundColor: Colors.white,
                              child: Text(
                                nome.isEmpty ? '?' : nome[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nome.isEmpty ? '-' : nome,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Cód: ${cliente['codigo_propri'] ?? '-'}'
                                    '${cpf.isNotEmpty ? ' | ${formatCpfCnpj(cpf)}' : ''}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (email.isNotEmpty || cpf.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Card(
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Conta de acesso do cliente',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email.isNotEmpty
                                      ? email
                                      : 'Login por CPF/CNPJ: ${formatCpfCnpj(cpf)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    onPressed: _criandoConta ? null : _criarConta,
                                    icon: _criandoConta
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.key),
                                    label: Text(
                                      _criandoConta
                                          ? 'Criando conta...'
                                          : 'Criar conta de acesso',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: skyBlueDark,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_contaErro != null) ...[
                                  const SizedBox(height: 12),
                                  MessageBanner(message: _contaErro!),
                                ],
                                if (_contaLogin != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Conta criada com sucesso!',
                                          style: TextStyle(
                                            color: successGreen,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        SelectableText(
                                          'Login: $_contaLogin\nSenha temporária: $_contaSenha',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Informe estes dados ao cliente. Ele entra com o CPF/CNPJ '
                                          'e pode trocar a senha em "Esqueci minha senha".',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
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
                                'Entes Queridos Falecidos (${_falecidos.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: skyBlueDark,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_falecidos.isEmpty)
                                Text(
                                  'Nenhum ente querido falecido cadastrado para este cliente.',
                                  style: TextStyle(color: Colors.grey.shade600),
                                )
                              else
                                ..._falecidos.map(_buildFalecido),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Mensalidades / Boletos',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const AvisoBoletoCompensacao(),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _AdminFiltroChip(
                              label: 'Todas',
                              selecionado: _filtro == _FiltroAdmin.todas,
                              onTap: () => setState(() => _filtro = _FiltroAdmin.todas),
                            ),
                            const SizedBox(width: 8),
                            _AdminFiltroChip(
                              label: 'Em Aberto',
                              selecionado: _filtro == _FiltroAdmin.emAberto,
                              onTap: () => setState(() => _filtro = _FiltroAdmin.emAberto),
                            ),
                            const SizedBox(width: 8),
                            _AdminFiltroChip(
                              label: 'Vencido',
                              selecionado: _filtro == _FiltroAdmin.vencido,
                              onTap: () => setState(() => _filtro = _FiltroAdmin.vencido),
                            ),
                            const SizedBox(width: 8),
                            _AdminFiltroChip(
                              label: 'Pago',
                              selecionado: _filtro == _FiltroAdmin.pago,
                              onTap: () => setState(() => _filtro = _FiltroAdmin.pago),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_mensalidades.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'Nenhuma mensalidade encontrada para este cliente.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        )
                      else if (mensalidades.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'Nenhuma mensalidade encontrada',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        )
                      else
                        ...mensalidades.map(_buildMensalidade),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFalecido(Map<String, dynamic> f) {
    final locais = _locaisPorFalecido[f['id']?.toString()] ?? const [];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (f['nome'] ?? '-').toString(),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              if ((f['jazigo'] ?? '').toString().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Jazigo: ${f['jazigo']}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _linhaInfo('Data Nascimento', formatDateBr(f['data_nascimento'])),
          _linhaInfo('Data Falecimento', formatDateBr(f['data_falecimento'])),
          _linhaInfo('Data Sepultamento', formatDateBr(f['data_sepultamento'])),
          _linhaInfo('Data Exumação', formatDateBr(f['data_exumacao'])),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          const Text(
            'Locais de Sepultamento:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 6),
          if (locais.isEmpty)
            Text(
              (f['jazigo'] ?? '').toString().isNotEmpty
                  ? 'Jazigo: ${f['jazigo']}'
                  : 'Nenhum local específico cadastrado',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            )
          else
            ...locais.map((l) {
              final titulo = (l['jazigo'] ?? '').toString().isNotEmpty
                  ? l['jazigo']
                  : ((f['jazigo'] ?? '').toString().isNotEmpty
                      ? f['jazigo']
                      : (l['local_tipo'] ?? 'Jazigo'));
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo.toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: skyBlueDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Quadra: ${l['quadra'] ?? '-'}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Carneira: ${l['carneira'] ?? '-'}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ),
                        if (l['data_inicio'] != null)
                          Text(
                            'Início: ${formatDateBr(l['data_inicio'])}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMensalidade(Map<String, dynamic> m) {
    final pago = mensalidadePaga(m);
    final vencida = mensalidadeVencida(m);
    final cor = pago ? successGreen : (vencida ? dangerRed : warningOrange);
    final fundo = pago
        ? const Color(0xFFE8F5E9)
        : (vencida ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MensalidadeDetalheScreen(
              mensalidade: m,
              cliente: widget.cliente,
              configBanco: widget.configBanco,
              exibirCliente: true,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mensalidade ${numeroMensalidade(m)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: fundo,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusMensalidade(m),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Vencimento: ${formatDateBr(m['vecto'])}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                'Valor: ${formatCurrency(m['valor'])}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              if (pago && m['pagto'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Pago em: ${formatDateBr(m['pagto'])}',
                  style: const TextStyle(fontSize: 14, color: successGreen),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _linhaInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AdminFiltroChip extends StatelessWidget {
  final String label;
  final bool selecionado;
  final VoidCallback onTap;

  const _AdminFiltroChip({
    required this.label,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionado ? skyBlueDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selecionado ? skyBlueDark : const Color(0xFFE0E0E0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: selecionado ? Colors.white : const Color(0xFF555555),
              fontWeight: selecionado ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
