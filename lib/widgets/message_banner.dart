import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MessageBanner extends StatelessWidget {
  final String message;
  final bool success;

  const MessageBanner({super.key, required this.message, this.success = false});

  @override
  Widget build(BuildContext context) {
    final color = success ? successGreen : dangerRed;
    final background = success ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final icon = success ? Icons.check_circle_outline : Icons.error_outline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
