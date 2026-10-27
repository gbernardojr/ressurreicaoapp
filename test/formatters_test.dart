import 'package:flutter_test/flutter_test.dart';

import 'package:face_do_sol/utils/formatters.dart';

void main() {
  group('formatCpfCnpj', () {
    test('mantém códigos curtos sem formatação', () {
      expect(formatCpfCnpj('0252'), '0252');
    });

    test('formata CPF completo', () {
      expect(formatCpfCnpj('12345678901'), '123.456.789-01');
    });

    test('formata CNPJ parcial sem estourar', () {
      expect(formatCpfCnpj('123456789012'), '12.345.678/9012');
      expect(formatCpfCnpj('1234567890123'), '12.345.678/9012-3');
    });

    test('formata CNPJ completo', () {
      expect(formatCpfCnpj('12345678000190'), '12.345.678/0001-90');
    });

    test('preserva letras de códigos de jazigo', () {
      expect(formatCpfCnpj('0123-A'), '0123-A');
      expect(formatCpfCnpj('0376-i'), '0376-I');
    });
  });

  group('normalizarJazigo', () {
    test('ignora espaços, hífen e diferença de maiúsculas', () {
      expect(normalizarJazigo(' 0123-a '), '0123A');
      expect(normalizarJazigo('0376-I'), '0376I');
    });
  });

  group('variantesCodigo', () {
    test('gera variantes com e sem hífen', () {
      expect(variantesCodigo('0123A'), containsAll(['0123A', '0123-A']));
      expect(variantesCodigo('0376-i'), containsAll(['0376-I', '0376I']));
    });

    test('gera variante com zero à esquerda', () {
      expect(variantesCodigo('252'), contains('0252'));
    });
  });

  group('formatCpf', () {
    test('formata CPF parcial de 10 dígitos', () {
      expect(formatCpf('1234567890'), '123.456.789-0');
    });

    test('limita a 11 dígitos', () {
      expect(formatCpf('12345678901234'), '123.456.789-01');
    });
  });
}
