import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../utils/boleto_utils.dart';
import '../utils/formatters.dart';
import '../widgets/info_row.dart';

class MensalidadeDetalheScreen extends StatelessWidget {
  final Map<String, dynamic> mensalidade;
  final Map<String, dynamic> cliente;
  final Map<String, dynamic>? configBanco;
  final bool exibirCliente;

  const MensalidadeDetalheScreen({
    super.key,
    required this.mensalidade,
    required this.cliente,
    this.configBanco,
    this.exibirCliente = false,
  });

  @override
  Widget build(BuildContext context) {
    final pago = mensalidadePaga(mensalidade);
    final boleto = pago ? null : BradescoHelper.fromMensalidade(mensalidade, configBanco);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mensalidade ${numeroMensalidade(mensalidade)}'),
        backgroundColor: skyBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (exibirCliente)
                      InfoRow(label: 'Cliente', value: cliente['nome'] ?? '-'),
                    InfoRow(
                      label: 'Mensalidade',
                      value: numeroMensalidade(mensalidade),
                    ),
                    InfoRow(
                      label: 'Vencimento',
                      value: formatDateBr(mensalidade['vecto']),
                    ),
                    InfoRow(
                      label: 'Valor',
                      value: formatCurrency(mensalidade['valor']),
                    ),
                    InfoRow(label: 'Jazigo', value: mensalidade['jazigo'] ?? '-'),
                    if ((mensalidade['nosso_numero'] ?? '').toString().isNotEmpty)
                      InfoRow(
                        label: 'Nosso Número',
                        value: mensalidade['nosso_numero'],
                      ),
                    if ((mensalidade['bol_pagador_nome'] ?? '').toString().isNotEmpty)
                      InfoRow(
                        label: 'Pagador',
                        value: mensalidade['bol_pagador_nome'],
                      ),
                    if ((mensalidade['bol_mensagem2'] ?? '').toString().isNotEmpty)
                      InfoRow(
                        label: 'Mensagem',
                        value: mensalidade['bol_mensagem2'],
                        small: true,
                      ),
                    InfoRow(
                      label: 'Status',
                      value: pago ? 'Pago' : 'Pendente',
                    ),
                    if (pago && mensalidade['pagto'] != null)
                      InfoRow(
                        label: 'Pago em',
                        value: formatDateBr(mensalidade['pagto']),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (pago)
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, color: successGreen, size: 56),
                      const SizedBox(height: 16),
                      const Text(
                        'Mensalidade paga',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: successGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Esta mensalidade já foi quitada.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else if (boleto == null)
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.warning_amber_outlined, color: warningOrange, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Dados bancários não disponíveis',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Não foi possível gerar a linha digitável desta mensalidade. '
                        'Procure a recepção do cemitério.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 90,
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          child: BarcodeWidget(
                            barcode: Barcode.code128(),
                            data: boleto.codigoBarras,
                            width: 700,
                            height: 90,
                            drawText: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: SelectableText(
                          boleto.linhaDigitavel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => _copiar(context, boleto),
                          icon: const Icon(Icons.copy),
                          label: const Text(
                            'COPIAR CÓDIGO DE BARRA',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: skyBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _gerarPdf(context, boleto),
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text(
                            'GERAR PDF',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: skyBlue,
                            side: const BorderSide(color: skyBlue),
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

  void _copiar(BuildContext context, BoletoModel boleto) {
    Clipboard.setData(ClipboardData(text: boleto.linhaLimpa));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado!')),
    );
  }

  Future<void> _gerarPdf(BuildContext context, BoletoModel boleto) async {
    try {
      final bytes = await _buildPdf(boleto);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'boleto_${numeroMensalidade(mensalidade)}.pdf',
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao gerar o PDF do boleto.')),
        );
      }
    }
  }

  Future<Uint8List> _buildPdf(BoletoModel boleto) async {
    const cedente = AppConfig.cedenteNome;
    final cnpjCedente = (cliente['cpf_cnpj'] ?? mensalidade['cpf_cnpj'] ?? '').toString();
    final agencia = (configBanco?['agencia'] ?? '').toString();
    final conta = (configBanco?['conta_corrente'] ?? '').toString();
    final nossoNumero = (mensalidade['nosso_numero'] ?? '').toString();
    final vencimento = parseDateSafe(mensalidade['vecto']) ?? DateTime.now();
    final emissao = parseDateSafe(mensalidade['bol_emissao']) ?? DateTime.now();
    final valor = (mensalidade['valor'] as num?)?.toDouble() ??
        double.tryParse(mensalidade['valor']?.toString() ?? '') ??
        0;
    final mensagem = (mensalidade['bol_mensagem2'] ??
            'APOS 30 DIAS DO VENCIMENTO O TITULO SERA PROTESTADO AUTOMAT.')
        .toString();
    final especie = (mensalidade['bol_especie'] ?? '12').toString();
    final multa = mensalidade['bol_multa_perc'];
    final mora = mensalidade['bol_mora'];
    final pagadorNome =
        (mensalidade['bol_pagador_nome'] ?? cliente['nome'] ?? '').toString();
    final pagadorCpf =
        (mensalidade['bol_pagador_cpf_cnpj'] ?? cliente['cpf_cnpj'] ?? '').toString();

    var enderecoPagador = (mensalidade['bol_pagador_endereco'] ?? '').toString();
    final bairro = (mensalidade['bol_pagador_bairro'] ?? '').toString();
    final cidade = (mensalidade['bol_pagador_cidade'] ?? '').toString();
    final uf = (mensalidade['bol_pagador_uf'] ?? '').toString();
    final cep = (mensalidade['bol_pagador_cep'] ?? '').toString();
    if (bairro.isNotEmpty) enderecoPagador += ' - $bairro';
    if (cidade.isNotEmpty) enderecoPagador += ' - $cidade';
    if (uf.isNotEmpty) enderecoPagador += '/$uf';
    if (cep.isNotEmpty) enderecoPagador += ' - CEP: $cep';

    const especies = {
      '01': 'CHEQUE',
      '02': 'DM',
      '03': 'DMI',
      '04': 'NOTA',
      '12': 'DM',
      '17': 'RC',
      '20': 'AP',
      '99': 'OU',
    };
    final especieLabel = especies[especie] ?? especie;
    final multaNum = multa is num ? multa : double.tryParse(multa?.toString() ?? '');
    final moraNum = mora is num ? mora : double.tryParse(mora?.toString() ?? '');
    final multaValor = multaNum != null && multaNum > 0 ? '$multaNum%' : '';
    final moraValor = moraNum != null && moraNum > 0 ? formatCurrency(moraNum) : '';

    final pdf = pw.Document();

    pw.Widget campo(String label, String value, {int flex = 1, bool bold = true, double fontSize = 9}) {
      return pw.Expanded(
        flex: flex,
        child: pw.Container(
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700)),
              pw.SizedBox(height: 1),
              pw.Text(
                value.isEmpty ? ' ' : value,
                style: pw.TextStyle(
                  fontSize: fontSize,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    }

    pw.Widget linha(List<pw.Widget> cells) => pw.Row(children: cells);

    pw.Widget cabecalhoBradesco({bool comLinha = false}) {
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('BANCO BRADESCO',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.orange, width: 2)),
                child: pw.Text('237-2',
                    style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange)),
              ),
              if (comLinha) ...[
                pw.SizedBox(width: 8),
                pw.Text(boleto.linhaDigitavel,
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ],
            ],
          ),
        ],
      );
    }

    pw.Widget barcodePdf({double height = 50, double width = 350}) {
      return pw.SizedBox(
        height: height,
        child: pw.Center(
          child: pw.BarcodeWidget(
            barcode: pw.Barcode.code128(),
            data: boleto.codigoBarras,
            width: width,
            height: height - 5,
            drawText: false,
          ),
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(15),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              cabecalhoBradesco(),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.orange, width: 2)),
                child: pw.Column(
                  children: [
                    pw.Text(
                      boleto.linhaDigitavel,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    barcodePdf(),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('RECIBO DO PAGADOR',
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700)),
              pw.SizedBox(height: 2),
              linha([
                campo('Beneficiário', cedente, flex: 4),
                campo('CNPJ/CPF', cnpjCedente, flex: 2),
              ]),
              linha([
                campo('Agência/Código', '$agencia / $conta', flex: 2),
                campo('Vencimento', formatDateBr(vencimento), flex: 1),
                campo('Valor', formatCurrency(valor), flex: 1),
              ]),
              linha([
                campo('Nosso Número', nossoNumero, flex: 2),
                campo('Espécie', especieLabel, flex: 1),
                if (multaValor.isNotEmpty) campo('Multa', multaValor, flex: 1),
                if (moraValor.isNotEmpty) campo('Mora', moraValor, flex: 1),
              ]),
              linha([
                campo('Pagador', pagadorNome, flex: 3),
                campo('CPF/CNPJ', pagadorCpf, flex: 1),
              ]),
              if (enderecoPagador.isNotEmpty)
                linha([campo('Endereço', enderecoPagador)]),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                child: pw.Text(mensagem,
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                    ),
                  ),
                  pw.Text('  CORTE AQUI  ',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  pw.Expanded(
                    child: pw.Text(
                      '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              cabecalhoBradesco(comLinha: true),
              pw.SizedBox(height: 4),
              linha([
                campo('Local de Pagamento', 'PAGÁVEL PREFERENCIALMENTE NA REDE BRADESCO', flex: 3),
                campo('Vencimento', formatDateBr(vencimento), flex: 1),
              ]),
              linha([
                campo('Beneficiário', '$cedente - CNPJ: $cnpjCedente', flex: 3),
                campo('Ag/Código Beneficiário', '$agencia / $conta', flex: 1),
              ]),
              linha([
                campo('Data Emissão', formatDateBr(emissao), flex: 1),
                campo('Nosso Número', nossoNumero, flex: 1),
                campo('Espécie', especieLabel, flex: 1),
                campo('Quantidade', '', flex: 1),
                campo('Valor', formatCurrency(valor), flex: 1),
              ]),
              linha([
                campo('(-) Desconto / Abatimento', '', flex: 2),
                if (multaValor.isNotEmpty) campo('(+) Multa', multaValor, flex: 1),
                if (moraValor.isNotEmpty) campo('(+) Mora/Dia', moraValor, flex: 1),
                campo('(=) Valor Total', formatCurrency(valor), flex: 1),
              ]),
              linha([
                campo('Pagador', pagadorNome, flex: 3),
                campo('CPF/CNPJ', pagadorCpf, flex: 1),
              ]),
              if (enderecoPagador.isNotEmpty)
                linha([campo('Endereço', enderecoPagador)]),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Mensagem:',
                        style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700)),
                    pw.Text(mensagem, style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              barcodePdf(height: 55, width: 380),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
