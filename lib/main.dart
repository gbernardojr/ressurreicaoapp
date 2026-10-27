import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/client_data.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseKey,
  );

  runApp(const RessurreicaoApp());
}

class RessurreicaoApp extends StatelessWidget {
  const RessurreicaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ressurreição',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: skyBlue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _carregando = true;
  ClientData? _data;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    try {
      final sessao = Supabase.instance.client.auth.currentSession;
      if (sessao != null) {
        final data = ClientData();
        await data.load();
        _data = data;
      }
    } catch (_) {
      _data = null;
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_data != null) {
      if (_data!.isAdmin) {
        return AdminDashboardScreen(data: _data!);
      }
      return DashboardScreen(data: _data!);
    }
    return const LoginScreen();
  }
}
