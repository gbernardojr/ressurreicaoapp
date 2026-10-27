import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

Future<void> abrirPoliticaPrivacidade(BuildContext context) async {
  final uri = Uri.parse(AppConfig.privacyPolicyUrl);
  var abriu = false;
  try {
    abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}

  if (abriu || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Não foi possível abrir o link. Acesse: $uri')),
  );
}
