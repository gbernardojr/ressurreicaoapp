import 'package:flutter_test/flutter_test.dart';

import 'package:face_do_sol/services/client_data.dart';

void main() {
  test('filtra mensalidades por jazigo com letras ignorando formato', () {
    final data = ClientData()
      ..mensalidades = [
        {'id': '1', 'jazigo': '0123-A'},
        {'id': '2', 'jazigo': '0376I'},
        {'id': '3', 'jazigo': '0450'},
      ];

    data.selecionarJazigo('0123-a');
    expect(data.mensalidadesFiltradas.map((m) => m['id']), ['1']);

    data.selecionarJazigo('0376-I');
    expect(data.mensalidadesFiltradas.map((m) => m['id']), ['2']);

    data.selecionarJazigo(null);
    expect(data.mensalidadesFiltradas, hasLength(3));
  });
}
