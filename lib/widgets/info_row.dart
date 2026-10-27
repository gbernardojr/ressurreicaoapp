import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final dynamic value;
  final bool small;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(fontSize: small ? 12 : 14, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value?.toString() ?? '-',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: small ? 12 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
