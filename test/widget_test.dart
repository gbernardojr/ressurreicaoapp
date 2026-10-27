import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:face_do_sol/main.dart';
import 'package:face_do_sol/widgets/aviso_boleto.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RessurreicaoApp());

    expect(find.text('Ressurreição'), findsOneWidget);
    expect(find.text('ENTRAR'), findsOneWidget);
  });

  testWidgets('Aviso de compensação de boleto é exibido', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AvisoBoletoCompensacao()),
      ),
    );

    expect(find.text(avisoBoletoCompensacao), findsOneWidget);
  });
}
