import 'package:flutter/material.dart';

const avisoBoletoCompensacao =
    'Pagamento por boleto pode levar até 3 dias úteis para serem compensados. '
    'Assim, uma pendência financeira pode continuar aparecendo durante este período.';

class AvisoBoletoCompensacao extends StatelessWidget {
  const AvisoBoletoCompensacao({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        border: Border.all(color: const Color(0xFF90CAF9)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        avisoBoletoCompensacao,
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: Color(0xFF1565C0),
        ),
      ),
    );
  }
}
