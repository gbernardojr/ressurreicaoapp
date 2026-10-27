import 'package:flutter/material.dart';

import '../services/client_data.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/aviso_boleto.dart';
import 'mensalidade_detalhe_screen.dart';

enum FiltroMensalidade { todas, emAberto, vencido, pago }

class MensalidadesScreen extends StatefulWidget {
  final ClientData data;

  const MensalidadesScreen({super.key, required this.data});

  @override
  State<MensalidadesScreen> createState() => _MensalidadesScreenState();
}

class _MensalidadesScreenState extends State<MensalidadesScreen> {
  FiltroMensalidade _filtro = FiltroMensalidade.todas;

  List<Map<String, dynamic>> get _filtradas {
    final base = widget.data.mensalidadesFiltradas;
    switch (_filtro) {
      case FiltroMensalidade.todas:
        return base;
      case FiltroMensalidade.emAberto:
        return base.where((m) => !mensalidadePaga(m) && !mensalidadeVencida(m)).toList();
      case FiltroMensalidade.vencido:
        return base.where((m) => mensalidadeVencida(m)).toList();
      case FiltroMensalidade.pago:
        return base.where((m) => mensalidadePaga(m)).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtradas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensalidades'),
        backgroundColor: skyBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _FiltroChip(
                  label: 'Todas',
                  selecionado: _filtro == FiltroMensalidade.todas,
                  onTap: () => setState(() => _filtro = FiltroMensalidade.todas),
                ),
                const SizedBox(width: 8),
                _FiltroChip(
                  label: 'Em Aberto',
                  selecionado: _filtro == FiltroMensalidade.emAberto,
                  onTap: () => setState(() => _filtro = FiltroMensalidade.emAberto),
                ),
                const SizedBox(width: 8),
                _FiltroChip(
                  label: 'Vencido',
                  selecionado: _filtro == FiltroMensalidade.vencido,
                  onTap: () => setState(() => _filtro = FiltroMensalidade.vencido),
                ),
                const SizedBox(width: 8),
                _FiltroChip(
                  label: 'Pago',
                  selecionado: _filtro == FiltroMensalidade.pago,
                  onTap: () => setState(() => _filtro = FiltroMensalidade.pago),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: AvisoBoletoCompensacao(),
          ),
          Expanded(
            child: lista.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma mensalidade encontrada',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final m = lista[index];
                      return _MensalidadeCard(
                        mensalidade: m,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MensalidadeDetalheScreen(
                              mensalidade: m,
                              cliente: widget.data.cliente ?? const {},
                              configBanco: widget.data.configBanco,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool selecionado;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionado ? skyBlue : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selecionado ? skyBlue : const Color(0xFFE0E0E0)),
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

class _MensalidadeCard extends StatelessWidget {
  final Map<String, dynamic> mensalidade;
  final VoidCallback onTap;

  const _MensalidadeCard({required this.mensalidade, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pago = mensalidadePaga(mensalidade);
    final vencida = mensalidadeVencida(mensalidade);

    final cor = pago
        ? successGreen
        : (vencida ? dangerRed : warningOrange);
    final fundo = pago
        ? const Color(0xFFE8F5E9)
        : (vencida ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0));

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mensalidade ${numeroMensalidade(mensalidade)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: fundo,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusMensalidade(mensalidade),
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
                'Vencimento: ${formatDateBr(mensalidade['vecto'])}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                'Valor: ${formatCurrency(mensalidade['valor'])}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              if (pago && mensalidade['pagto'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Pago em: ${formatDateBr(mensalidade['pagto'])}',
                  style: const TextStyle(fontSize: 14, color: successGreen),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
