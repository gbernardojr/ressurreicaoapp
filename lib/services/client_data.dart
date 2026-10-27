import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/formatters.dart';

class ClientData {
  User? user;
  Map<String, dynamic>? cliente;
  List<Map<String, dynamic>> mensalidades = [];
  List<Map<String, dynamic>> falecidos = [];
  List<String> todosJazigos = [];
  String? jazigoSelecionado;
  Map<String, dynamic>? configBanco;
  bool isAdmin = false;
  Map<String, dynamic>? adminUser;

  SupabaseClient get _sb => Supabase.instance.client;

  List<Map<String, dynamic>> get mensalidadesFiltradas {
    final jazigo = jazigoSelecionado;
    if (jazigo == null) return mensalidades;
    final alvo = normalizarJazigo(jazigo);
    return mensalidades
        .where((m) => normalizarJazigo(m['jazigo']?.toString()) == alvo)
        .toList();
  }

  void selecionarJazigo(String? jazigo) {
    jazigoSelecionado = jazigo;
  }

  Future<void> load() async {
    cliente = null;
    mensalidades = [];
    falecidos = [];
    todosJazigos = [];
    jazigoSelecionado = null;
    configBanco = null;
    isAdmin = false;
    adminUser = null;

    final currentUser = _sb.auth.currentUser;
    user = currentUser;
    if (currentUser == null) return;

    final email = currentUser.email;
    await _detectarAdmin(email);

    try {
      configBanco = await _sb
          .from('config_banco')
          .select()
          .eq('ativo', true)
          .limit(1)
          .maybeSingle();
    } catch (_) {
      configBanco = null;
    }

    if (email == null) return;

    Map<String, dynamic>? encontrado;
    try {
      encontrado = await _sb
          .from('clientes')
          .select()
          .eq('email', email)
          .limit(1)
          .maybeSingle();
    } catch (_) {
      encontrado = null;
    }

    if (encontrado == null && email.endsWith('@sememail.com.br')) {
      final cpf = email.replaceAll('@sememail.com.br', '');
      encontrado = await _sb
          .from('clientes')
          .select()
          .eq('cpf_cnpj', cpf)
          .limit(1)
          .maybeSingle();
    }

    cliente = encontrado;
    if (encontrado == null) return;

    await _carregarMensalidades(encontrado);
  }

  Future<void> _detectarAdmin(String? email) async {
    Map<String, dynamic>? admin;

    try {
      if (email != null) {
        admin = await _sb
            .from('admin_usuarios')
            .select()
            .eq('email', email)
            .eq('ativo', true)
            .maybeSingle();
      }

      if (admin == null) {
        String? cpf;
        try {
          final registro = await _sb
              .from('clientes')
              .select('cpf_cnpj')
              .eq('email', email ?? '')
              .limit(1)
              .maybeSingle();
          cpf = registro?['cpf_cnpj']?.toString();
        } catch (_) {}

        if ((cpf == null || cpf.isEmpty) &&
            email != null &&
            email.endsWith('@sememail.com.br')) {
          cpf = email.replaceAll('@sememail.com.br', '');
        }

        if (cpf != null && cpf.isNotEmpty) {
          admin = await _sb
              .from('admin_usuarios')
              .select()
              .eq('cpf', cpf)
              .eq('ativo', true)
              .maybeSingle();
        }
      }
    } catch (_) {
      admin = null;
    }

    isAdmin = admin != null;
    adminUser = admin;
  }

  Future<void> _carregarMensalidades(Map<String, dynamic> registro) async {
    final clienteId = registro['id']?.toString();
    if (clienteId == null) return;

    final cpf = registro['cpf_cnpj']?.toString();
    final ids = <String>{clienteId};

    if (cpf != null && cpf.isNotEmpty) {
      final todos = await _sb.from('clientes').select('id').eq('cpf_cnpj', cpf);
      if (todos.length > 1) {
        ids
          ..clear()
          ..addAll(todos.map((c) => c['id'].toString()));
      }
    }

    final rows = await _sb
        .from('mensalidades')
        .select()
        .inFilter('cliente_id', ids.toList())
        .order('vecto', ascending: true);

    mensalidades = rows.map((m) => Map<String, dynamic>.from(m)).toList();

    final jazigos = <String, String>{};
    for (final m in mensalidades) {
      final original = (m['jazigo'] ?? '').toString().trim();
      if (original.isEmpty) continue;
      jazigos.putIfAbsent(normalizarJazigo(original), () => original);
    }
    todosJazigos = jazigos.values.toList()..sort();
  }

  Future<void> loadFalecidos() async {
    final clienteId = cliente?['id'];
    if (clienteId == null) {
      falecidos = [];
      return;
    }

    final rows = await _sb
        .from('falecidos')
        .select()
        .eq('cliente_id', clienteId)
        .order('nome', ascending: true);

    falecidos = rows.map((f) => Map<String, dynamic>.from(f)).toList();
  }
}
