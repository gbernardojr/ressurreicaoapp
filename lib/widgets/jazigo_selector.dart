import 'package:flutter/material.dart';

class JazigoSelector extends StatelessWidget {
  final List<String> jazigos;
  final String? selecionado;
  final ValueChanged<String?> onChanged;

  const JazigoSelector({
    super.key,
    required this.jazigos,
    required this.selecionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text('Jazigo:', style: TextStyle(fontSize: 14, color: Color(0xFF555555))),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selecionado ?? '',
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(8),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Todos os jazigos')),
                  ...jazigos.map(
                    (j) => DropdownMenuItem(value: j, child: Text('Jazigo $j')),
                  ),
                ],
                onChanged: (value) => onChanged(value == null || value.isEmpty ? null : value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
