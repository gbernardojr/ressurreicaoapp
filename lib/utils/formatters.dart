String onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

String normalizarJazigo(String? value) =>
    (value ?? '').trim().toUpperCase().replaceAll(RegExp(r'[\s-]+'), '');

List<String> variantesCodigo(String value) {
  final base = value.trim().toUpperCase().replaceAll(RegExp(r'[^0-9A-Z-]'), '');
  final variantes = <String>[];

  void adicionar(String v) {
    if (v.isNotEmpty && !variantes.contains(v)) variantes.add(v);
  }

  adicionar(base);
  final semHifen = base.replaceAll('-', '');
  adicionar(semHifen);

  final comHifen = RegExp(r'^(\d{1,4})([A-Z])$').firstMatch(semHifen);
  if (comHifen != null) {
    final numero = comHifen.group(1)!.padLeft(4, '0');
    adicionar('$numero-${comHifen.group(2)}');
    adicionar('$numero${comHifen.group(2)}');
  }
  if (RegExp(r'^\d{1,4}$').hasMatch(base)) {
    adicionar(base.padLeft(4, '0'));
  }
  return variantes;
}

String formatCpf(String value) {
  final raw = onlyDigits(value);
  final d = raw.length > 11 ? raw.substring(0, 11) : raw;
  if (d.length <= 3) return d;
  if (d.length <= 6) return '${d.substring(0, 3)}.${d.substring(3)}';
  if (d.length <= 9) {
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6)}';
  }
  final base = '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}';
  return '$base-${d.substring(9)}';
}

String formatCpfCnpj(String value) {
  final texto = value.trim();
  if (RegExp(r'[A-Za-z]').hasMatch(texto)) {
    final limpo = texto.toUpperCase().replaceAll(RegExp(r'[^0-9A-Z-]'), '');
    return limpo.length > 18 ? limpo.substring(0, 18) : limpo;
  }

  final raw = onlyDigits(texto);
  if (raw.length <= 6) return texto.replaceAll(RegExp(r'[^0-9-]'), '');
  if (raw.length <= 11) return formatCpf(raw);

  final d = raw.length > 14 ? raw.substring(0, 14) : raw;
  final out = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i == 2 || i == 5) out.write('.');
    if (i == 8) out.write('/');
    if (i == 12) out.write('-');
    out.write(d[i]);
  }
  return out.toString();
}

DateTime? parseDateSafe(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;

  final text = value.toString().trim();
  if (text.isEmpty) return null;

  final dateOnly = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  final match = dateOnly.firstMatch(text);
  if (match != null) {
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  return DateTime.tryParse(text)?.toLocal();
}

String formatDateBr(dynamic value) {
  final date = parseDateSafe(value);
  if (date == null) return '-';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String formatCurrency(dynamic value) {
  final raw = value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
  if (raw == null) return 'R\$ 0,00';
  return 'R\$ ${raw.toStringAsFixed(2).replaceAll('.', ',')}';
}

String numeroMensalidade(Map<String, dynamic> m) {
  return (m['num'] ?? m['reg'] ?? '-').toString();
}

bool mensalidadePaga(Map<String, dynamic> m) => m['pago'] == true;

bool mensalidadeVencida(Map<String, dynamic> m) {
  if (mensalidadePaga(m)) return false;
  final vencimento = parseDateSafe(m['vecto']);
  if (vencimento == null) return false;
  final hoje = DateTime.now();
  final venc = DateTime(vencimento.year, vencimento.month, vencimento.day);
  final hojeZero = DateTime(hoje.year, hoje.month, hoje.day);
  return venc.isBefore(hojeZero);
}

String statusMensalidade(Map<String, dynamic> m) {
  if (mensalidadePaga(m)) return 'Pago';
  if (mensalidadeVencida(m)) return 'Vencido';
  return 'em Aberto';
}
