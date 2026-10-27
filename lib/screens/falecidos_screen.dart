import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/client_data.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/info_row.dart';

class FalecidosScreen extends StatefulWidget {
  final ClientData data;

  const FalecidosScreen({super.key, required this.data});

  @override
  State<FalecidosScreen> createState() => _FalecidosScreenState();
}

class _FalecidosScreenState extends State<FalecidosScreen> {
  bool _carregando = true;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = false;
    });
    try {
      await widget.data.loadFalecidos();
    } catch (_) {
      _erro = true;
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entes Queridos Falecidos'),
        backgroundColor: skyBlue,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Builder(
              builder: (context) {
                if (_erro) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Erro ao carregar os familiares.'),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _carregar, child: const Text('Tentar novamente')),
                      ],
                    ),
                  );
                }

                final lista = widget.data.falecidos;
                if (lista.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum familiar cadastrado',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final f = lista[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FalecidoDetalheScreen(falecido: f),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF0E6FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.church, color: Color(0xFF7B2D8E)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (f['nome'] ?? '-').toString(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if ((f['jazigo'] ?? '').toString().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Jazigo: ${f['jazigo']}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class FalecidoDetalheScreen extends StatefulWidget {
  final Map<String, dynamic> falecido;

  const FalecidoDetalheScreen({super.key, required this.falecido});

  @override
  State<FalecidoDetalheScreen> createState() => _FalecidoDetalheScreenState();
}

class _FalecidoDetalheScreenState extends State<FalecidoDetalheScreen> {
  bool _carregando = true;
  bool _erro = false;
  List<Map<String, dynamic>> _locais = [];

  @override
  void initState() {
    super.initState();
    _carregarLocais();
  }

  Future<void> _carregarLocais() async {
    setState(() {
      _carregando = true;
      _erro = false;
    });
    try {
      final rows = await Supabase.instance.client
          .from('falecido_locais')
          .select()
          .eq('falecido_id', widget.falecido['id'])
          .order('data_inicio', ascending: false);
      _locais = rows.map((l) => Map<String, dynamic>.from(l)).toList();
    } catch (_) {
      _erro = true;
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.falecido;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Falecido'),
        backgroundColor: skyBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE3F2FD),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.church, color: skyBlueDark, size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      (f['nome'] ?? '-').toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoRow(label: 'Nome', value: f['nome'] ?? '-'),
                    InfoRow(label: 'Data Nascimento', value: formatDateBr(f['data_nascimento'])),
                    InfoRow(label: 'Data Falecimento', value: formatDateBr(f['data_falecimento'])),
                    InfoRow(label: 'Data Sepultamento', value: formatDateBr(f['data_sepultamento'])),
                    InfoRow(label: 'Data Exumação', value: formatDateBr(f['data_exumacao'])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Locais de Sepultamento',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    if (_carregando)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ))
                    else if (_erro)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            const Text('Erro ao carregar locais'),
                            TextButton(onPressed: _carregarLocais, child: const Text('Tentar novamente')),
                          ],
                        ),
                      )
                    else if (_locais.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'Nenhum local cadastrado',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      )
                    else
                      ..._locais.map((l) {
                        final titulo = (l['jazigo'] ?? '').toString().isNotEmpty
                            ? l['jazigo']
                            : ((f['jazigo'] ?? '').toString().isNotEmpty
                                ? f['jazigo']
                                : (l['local_tipo'] ?? 'Jazigo'));
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titulo.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: skyBlueDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InfoRow(label: 'Quadra', value: l['quadra'] ?? '-'),
                              InfoRow(label: 'Carneira', value: l['carneira'] ?? '-'),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
