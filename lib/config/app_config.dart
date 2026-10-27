class AppConfig {
  static const String supabaseUrl = 'https://pfzulktbhivfkfzuvztd.supabase.co';
  static const String supabaseKey = 'sb_publishable__GD7DmF9qF1_vFbHT-OMtw_oaa5dlct';

  static const String appName = 'Ressurreição';
  static const String appVersion = '1.0.0';
  static const String cedenteNome = 'CEMITÉRIO DA RESSURREIÇÃO';
  static const String passwordResetUrl =
      'https://ressurreicao.vercel.app/#/redefinir-senha';

  static const Duration syncInterval = Duration(minutes: 30);
  static const Duration fullSyncInterval = Duration(hours: 24);
}
