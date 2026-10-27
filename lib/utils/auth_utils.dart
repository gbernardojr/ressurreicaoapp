import 'package:supabase_flutter/supabase_flutter.dart';

String mapAuthError(Object error, {bool admin = false}) {
  final message = error is AuthException ? error.message : error.toString();
  final lower = message.toLowerCase();

  if (lower.contains('not confirmed')) {
    return admin
        ? 'E-mail do administrador não confirmado. Confirme o e-mail ou libere o acesso no Supabase.'
        : 'E-mail ainda não confirmado. Verifique sua caixa de entrada.';
  }

  if (lower.contains('invalid login') || lower.contains('invalid credentials')) {
    return admin
        ? 'CPF ou senha incorretos.'
        : 'CPF ou senha incorretos. Se ainda não tem conta, use "Primeiro acesso".';
  }

  return admin ? 'CPF ou senha incorretos.' : 'CPF ou senha incorretos.';
}

// signUp pode trocar a sessão atual quando a confirmação de e-mail está
// desativada. Restauramos a sessão do administrador após criar a conta.
Future<AuthResponse> signUpPreservingSession(
  SupabaseClient sb, {
  required String email,
  required String password,
}) async {
  final original = sb.auth.currentSession;
  final originalUserId = original?.user.id;
  final refreshToken = original?.refreshToken;

  try {
    return await sb.auth.signUp(email: email, password: password);
  } finally {
    if (refreshToken != null && originalUserId != null) {
      final current = sb.auth.currentSession;
      if (current == null || current.user.id != originalUserId) {
        try {
          await sb.auth.setSession(refreshToken);
        } catch (_) {}
      }
    }
  }
}
