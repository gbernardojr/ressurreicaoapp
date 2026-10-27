import 'formatters.dart';

class BoletoModel {
  final String linhaDigitavel;
  final String codigoBarras;

  const BoletoModel({required this.linhaDigitavel, required this.codigoBarras});

  String get linhaLimpa => linhaDigitavel.replaceAll(RegExp(r'[.\s]'), '');
}

class BradescoHelper {
  static BoletoModel? fromMensalidade(
    Map<String, dynamic> mensalidade,
    Map<String, dynamic>? config,
  ) {
    final linhaBanco = (mensalidade['bol_linha_digitavel'] ?? '').toString().trim();
    if (linhaBanco.isNotEmpty) {
      final parsed = parseLinhaDigitavel(linhaBanco);
      if (parsed != null) return parsed;
    }

    if (config == null) return null;

    final valor = (mensalidade['valor'] as num?)?.toDouble() ??
        double.tryParse(mensalidade['valor']?.toString() ?? '') ??
        0;
    final nossoNumero = (mensalidade['nosso_numero'] ?? '').toString().trim();
    final nossoNumeroFinal = nossoNumero.isNotEmpty
        ? nossoNumero
        : (mensalidade['reg'] ?? '').toString();

    return gerarBoleto(
      agencia: (config['agencia'] ?? '0000').toString(),
      carteira: (config['carteira'] ?? '06').toString(),
      nossoNumero: nossoNumeroFinal,
      contaCorrente: (config['conta_corrente'] ?? '0000000').toString(),
      valor: valor,
      vencimento: parseDateSafe(mensalidade['vecto']) ?? DateTime.now(),
    );
  }

  static BoletoModel gerarBoleto({
    required String agencia,
    required String carteira,
    required String nossoNumero,
    required String contaCorrente,
    required double valor,
    required DateTime vencimento,
  }) {
    const banco = '237';
    const moeda = '9';

    final ag = onlyDigits(agencia).padLeft(4, '0');
    final car = onlyDigits(carteira).padLeft(2, '0');
    final nn = onlyDigits(nossoNumero).padLeft(11, '0');
    final cc = onlyDigits(contaCorrente).padLeft(7, '0');

    final fatorStr = _calcularFatorVencimento(vencimento).toString().padLeft(4, '0');
    final valorStr = (valor * 100).round().toString().padLeft(10, '0');
    final campoLivre = '$ag$car$nn$cc' '0';
    final baseParaDv = '$banco$moeda$fatorStr$valorStr$campoLivre';
    final dvGeral = _calcularDVModulo11(baseParaDv, 9);

    final codigoBarras =
        baseParaDv.substring(0, 4) + dvGeral.toString() + baseParaDv.substring(4);

    final c1 = banco + moeda + campoLivre.substring(0, 5);
    final dv1 = _calcularDVModulo10(c1);
    final campo1 = '${c1.substring(0, 5)}.${c1.substring(5)}$dv1';

    final c2 = campoLivre.substring(5, 15);
    final dv2 = _calcularDVModulo10(c2);
    final campo2 = '${c2.substring(0, 5)}.${c2.substring(5)}$dv2';

    final c3 = campoLivre.substring(15, 25);
    final dv3 = _calcularDVModulo10(c3);
    final campo3 = '${c3.substring(0, 5)}.${c3.substring(5)}$dv3';

    return BoletoModel(
      linhaDigitavel: '$campo1 $campo2 $campo3 $dvGeral $fatorStr$valorStr',
      codigoBarras: codigoBarras,
    );
  }

  static BoletoModel? parseLinhaDigitavel(String linha) {
    final cleaned = linha.replaceAll(RegExp(r'[.\s]'), '');
    if (cleaned.length != 47 || !RegExp(r'^\d{47}$').hasMatch(cleaned)) {
      return null;
    }

    final banco = cleaned.substring(0, 3);
    final moeda = cleaned.substring(3, 4);
    final campoLivre1 = cleaned.substring(4, 9);
    final dv1 = cleaned.substring(9, 10);
    final campoLivre2 = cleaned.substring(10, 20);
    final dv2 = cleaned.substring(20, 21);
    final campoLivre3 = cleaned.substring(21, 31);
    final dv3 = cleaned.substring(31, 32);
    final dvGeral = cleaned.substring(32, 33);
    final fator = cleaned.substring(33, 37);
    final valor = cleaned.substring(37, 47);

    final campoLivre = campoLivre1 + campoLivre2 + campoLivre3;
    final codigoBarras = banco + moeda + dvGeral + fator + valor + campoLivre;

    final c1 = banco + moeda + campoLivre1;
    final c1fmt = '${c1.substring(0, 5)}.${c1.substring(5)}$dv1';
    final c2fmt = '${campoLivre2.substring(0, 5)}.${campoLivre2.substring(5)}$dv2';
    final c3fmt = '${campoLivre3.substring(0, 5)}.${campoLivre3.substring(5)}$dv3';

    return BoletoModel(
      linhaDigitavel: '$c1fmt $c2fmt $c3fmt $dvGeral $fator$valor',
      codigoBarras: codigoBarras,
    );
  }

  static int _calcularFatorVencimento(DateTime data) {
    final dataBase = DateTime(1997, 10, 7);
    final alvo = DateTime(data.year, data.month, data.day);
    var diferenca = alvo.difference(dataBase).inDays;

    if (alvo.isAfter(DateTime(2025, 2, 21))) {
      diferenca = (diferenca - 1000) % 9000 + 1000;
    }

    return diferenca;
  }

  static int _calcularDVModulo10(String texto) {
    var soma = 0;
    var peso = 2;
    for (var i = texto.length - 1; i >= 0; i--) {
      var num = int.parse(texto[i]) * peso;
      if (num > 9) {
        num = (num ~/ 10) + (num % 10);
      }
      soma += num;
      peso = peso == 2 ? 1 : 2;
    }
    final resto = soma % 10;
    var dv = 10 - resto;
    if (dv == 10) dv = 0;
    return dv;
  }

  static int _calcularDVModulo11(String texto, int base) {
    var soma = 0;
    var peso = 2;
    for (var i = texto.length - 1; i >= 0; i--) {
      soma += int.parse(texto[i]) * peso;
      peso = peso < base ? peso + 1 : 2;
    }
    final resto = soma % 11;
    var dv = 11 - resto;
    if (dv == 0 || dv == 10 || dv == 11) dv = 1;
    return dv;
  }
}
