import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/client_data.dart';
import '../theme/app_colors.dart';
import '../widgets/jazigo_selector.dart';
import 'dados_pessoais_screen.dart';
import 'falecidos_screen.dart';
import 'login_screen.dart';
import 'mensalidades_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ClientData data;

  const DashboardScreen({super.key, required this.data});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _atualizando = false;

  Future<void> _recarregar() async {
    setState(() => _atualizando = true);
    try {
      await widget.data.load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar os dados. Tente novamente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _atualizando = false);
    }
  }

  Future<void> _sair() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _abrir(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final cliente = data.cliente;
    final nome = (cliente?['nome'] ?? '').toString();
    final primeiroNome = nome.isEmpty ? '' : nome.split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ressurreição'),
        backgroundColor: skyBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _atualizando ? null : _recarregar,
            icon: _atualizando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: _sair,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: cliente == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_off_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'Cadastro não encontrado',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Não localizamos seus dados de cliente. Procure a recepção do cemitério.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _sair,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sair'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset('assets/images/logo.jpg', height: 100, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    primeiroNome.isEmpty ? 'Olá' : 'Olá, $primeiroNome',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  if ((cliente['codigo_propri'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Código: ${cliente['codigo_propri']}',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                  if (data.todosJazigos.length > 1) ...[
                    const SizedBox(height: 16),
                    JazigoSelector(
                      jazigos: data.todosJazigos,
                      selecionado: data.jazigoSelecionado,
                      onChanged: (jazigo) => setState(() => data.selecionarJazigo(jazigo)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _MenuTile(
                    icon: Icons.person_outline,
                    iconColor: const Color(0xFF2B6CB0),
                    iconBackground: const Color(0xFFE3F2FD),
                    titulo: 'Dados Pessoais',
                    descricao: 'Meus dados cadastrais',
                    onTap: () => _abrir(DadosPessoaisScreen(data: data)),
                  ),
                  const SizedBox(height: 12),
                  _MenuTile(
                    icon: Icons.favorite_border,
                    iconColor: const Color(0xFF7B2D8E),
                    iconBackground: const Color(0xFFF0E6FF),
                    titulo: 'Entes Queridos Falecidos',
                    descricao: 'Familiares sepultados',
                    onTap: () => _abrir(FalecidosScreen(data: data)),
                  ),
                  const SizedBox(height: 12),
                  _MenuTile(
                    icon: Icons.description_outlined,
                    iconColor: const Color(0xFFE67E22),
                    iconBackground: const Color(0xFFFFF3E0),
                    titulo: 'Boletos de Mensalidades',
                    descricao: 'Boletos e pagamentos',
                    onTap: () => _abrir(MensalidadesScreen(data: data)),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'desenvolvido por Gilberto Ap Bernardo Junior\nTecnologia da Informação',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String titulo;
  final String descricao;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.titulo,
    required this.descricao,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      descricao,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
