import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/local_db.dart';
import '../../core/preview_data.dart';
import '../../core/theme.dart';
import '../../shared/preview_app_bar.dart';

class MeusRegistrosScreen extends StatefulWidget {
  final int initialTab;
  final String? initialStatusFilter;

  const MeusRegistrosScreen({
    super.key,
    this.initialTab = 0,
    this.initialStatusFilter,
  });

  @override
  State<MeusRegistrosScreen> createState() => _MeusRegistrosScreenState();
}

class _MeusRegistrosScreenState extends State<MeusRegistrosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _contatos = [];
  List<Map<String, dynamic>> _demandas = [];
  List<Map<String, dynamic>> _visitas = [];
  String _statusFilter = 'TODOS';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this, initialIndex: widget.initialTab.clamp(0, 2));
    _statusFilter = widget.initialStatusFilter ?? 'TODOS';
    _load();
  }

  Future<void> _load() async {
    if (AppConstants.previewMode) {
      if (mounted) {
        setState(() {
          _contatos = List<Map<String, dynamic>>.from(PreviewData.contatos);
          _demandas = List<Map<String, dynamic>>.from(PreviewData.demandas);
          _visitas = List<Map<String, dynamic>>.from(PreviewData.visitas);
        });
      }
      return;
    }

    final db = await LocalDb.instance;
    final contatos = await db.query(AppConstants.tContatos, orderBy: 'created_at DESC');
    final demandas = await db.query(AppConstants.tDemandas, orderBy: 'created_at DESC');
    final visitas = await db.query(AppConstants.tVisitas, orderBy: 'created_at DESC');
    if (mounted) {
      setState(() {
        _contatos = contatos;
        _demandas = demandas;
        _visitas = visitas;
      });
    }
  }

  Color _syncColor(String? status) {
    switch (status) {
      case 'ENVIADO':
        return AppTheme.success;
      case 'ERRO':
        return AppTheme.error;
      default:
        return AppTheme.warning;
    }
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> items, String titleKey) {
    return items.where((item) {
      final status = (item['status'] ?? item['sync_status'] ?? '').toString();
      final title = (item[titleKey] ?? '').toString().toLowerCase();
      final detail = item.values.join(' ').toLowerCase();
      final matchesStatus = _statusFilter == 'TODOS' || status == _statusFilter;
      final matchesQuery = _query.isEmpty || title.contains(_query.toLowerCase()) || detail.contains(_query.toLowerCase());
      return matchesStatus && matchesQuery;
    }).toList();
  }

  Future<void> _updateLocal(String table, Map<String, dynamic> item, Map<String, dynamic> changes) async {
    if (AppConstants.previewMode) {
      setState(() {
        item.addAll(changes);
      });
      return;
    }

    final db = await LocalDb.instance;
    await db.update(table, changes, where: 'id = ?', whereArgs: [item['id']]);
    await _load();
  }

  Future<void> _openDetail(Map<String, dynamic> item, String type) async {
    final table = switch (type) {
      'contato' => AppConstants.tContatos,
      'demanda' => AppConstants.tDemandas,
      _ => AppConstants.tVisitas,
    };
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _RegistroDetailScreen(
          item: item,
          type: type,
          onUpdate: (changes) => _updateLocal(table, item, changes),
        ),
      ),
    );
    await _load();
  }

  String _detailForItem(Map<String, dynamic> item, String type) {
    switch (type) {
      case 'contato':
        final relacionamento = item['nivel_relacionamento']?.toString();
        final engajamento = item['engajamento']?.toString();
        final bairro = item['bairro']?.toString();
        final finalidades = <String>[
          if (item['eh_lideranca'] == true || item['eh_lideranca'] == 1) 'Liderança',
          if (item['eh_apoiador'] == true || item['eh_apoiador'] == 1) 'Apoiador',
          if (item['eh_beneficiario'] == true || item['eh_beneficiario'] == 1) 'Beneficiário',
          if (item['eh_parceria'] == true || item['eh_parceria'] == 1) 'Parceria',
        ];
        return [relacionamento, engajamento, bairro, if (finalidades.isNotEmpty) finalidades.join(', ')]
            .whereType<String>()
            .where((value) => value.isNotEmpty)
            .join(' • ');
      case 'demanda':
        final area = item['area']?.toString();
        final prioridade = item['prioridade']?.toString();
        final bairro = item['bairro']?.toString();
        return [area, prioridade, bairro]
            .whereType<String>()
            .where((value) => value.isNotEmpty)
            .join(' • ');
      case 'visita':
        final local = item['local']?.toString();
        final bairro = item['bairro']?.toString();
        return [local, bairro].whereType<String>().where((value) => value.isNotEmpty).join(' • ');
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreviewAppBar(
        title: 'Meus Registros',
        replaceOnNavigate: true,
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Contatos'),
            Tab(text: 'Demandas'),
            Tab(text: 'Visitas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildList(_contatos, 'nome', 'contato'),
          _buildList(_demandas, 'titulo', 'demanda'),
          _buildList(_visitas, 'tipo', 'visita'),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, String titleKey, String type) {
    final filtered = _filtered(items, titleKey);

    if (items.isEmpty) {
      return Center(
        child: Text(
          'Nenhum $type registrado',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Buscar',
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['TODOS', 'ATIVO', 'ABERTA', 'PENDENTE', 'ENVIADO', 'ERRO', 'CONCLUIDA', 'ARQUIVADA']
                      .map(
                        (status) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(status == 'TODOS' ? 'Todos' : status),
                            selected: _statusFilter == status,
                            onSelected: (_) => setState(() => _statusFilter = status),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Nenhum registro para este filtro.', style: TextStyle(color: AppTheme.textSecondary)))
              : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final sync = item['sync_status'] as String?;
        final createdAt = item['created_at'] as String?;
        final detail = _detailForItem(item, type);
        final timestamp = createdAt != null
            ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(createdAt))
            : '';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: () => _openDetail(item, type),
            leading: type == 'contato'
                ? _ContactAvatar(photoBase64: item['foto_base64']?.toString(), label: item[titleKey]?.toString() ?? '')
                : null,
            title: Text(item[titleKey]?.toString() ?? ''),
            subtitle: Text(
              detail.isEmpty ? timestamp : '$detail\n$timestamp',
              style: const TextStyle(fontSize: 12),
            ),
            isThreeLine: detail.isNotEmpty,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _syncColor(sync).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                sync ?? 'PENDENTE',
                style: TextStyle(
                  color: _syncColor(sync),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    ),
        ),
      ],
    );
  }
}

class _RegistroDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final String type;
  final Future<void> Function(Map<String, dynamic> changes) onUpdate;

  const _RegistroDetailScreen({
    required this.item,
    required this.type,
    required this.onUpdate,
  });

  @override
  State<_RegistroDetailScreen> createState() => _RegistroDetailScreenState();
}

class _RegistroDetailScreenState extends State<_RegistroDetailScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: (widget.item[widget.type == 'contato' ? 'nome' : widget.type == 'demanda' ? 'titulo' : 'tipo'] ?? '').toString());
    _descCtrl = TextEditingController(text: (widget.item['descricao'] ?? widget.item['observacoes'] ?? widget.item['local'] ?? '').toString());
    _status = (widget.item['status'] ?? widget.item['sync_status'] ?? 'PENDENTE').toString();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save([String? status]) async {
    setState(() => _saving = true);
    final titleKey = widget.type == 'contato'
        ? 'nome'
        : widget.type == 'demanda'
            ? 'titulo'
            : 'tipo';
    final descKey = widget.type == 'contato' ? 'observacoes' : widget.type == 'demanda' ? 'descricao' : 'local';
    await widget.onUpdate({
      titleKey: _titleCtrl.text.trim(),
      descKey: _descCtrl.text.trim(),
      if (status != null) 'status': status,
      if (status != null) 'sync_status': 'PENDENTE',
    });
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (status != null) _status = status;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(status == null ? 'Registro atualizado.' : 'Status atualizado para $status.'), backgroundColor: AppTheme.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.type) {
      'contato' => 'Contato',
      'demanda' => 'Demanda',
      _ => 'Visita',
    };

    return Scaffold(
      appBar: PreviewAppBar(title: title, replaceOnNavigate: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _titleCtrl, decoration: InputDecoration(labelText: title)),
          const SizedBox(height: 14),
          TextField(controller: _descCtrl, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'Detalhes')),
          const SizedBox(height: 14),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Status atual'),
            child: Text(_status, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: _saving ? null : () => _save(),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Salvar ajustes'),
          ),
          const SizedBox(height: 12),
          if (widget.type == 'demanda') ...[
            _action('Assumir / em atendimento', Icons.playlist_add_check, 'EM_ATENDIMENTO'),
            _action('Fechar como concluida', Icons.check_circle_outline, 'CONCLUIDA'),
            _action('Arquivar demanda', Icons.archive_outlined, 'ARQUIVADA'),
          ],
          if (widget.type == 'contato') ...[
            _action('Marcar ativo', Icons.verified_user_outlined, 'ATIVO'),
            _action('Restringir contato', Icons.lock_outline, 'RESTRITO'),
            _action('Arquivar contato', Icons.archive_outlined, 'ARQUIVADO'),
          ],
        ],
      ),
    );
  }

  Widget _action(String label, IconData icon, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton.icon(
        onPressed: _saving ? null : () => _save(status),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _ContactAvatar extends StatelessWidget {
  final String? photoBase64;
  final String label;

  const _ContactAvatar({required this.photoBase64, required this.label});

  @override
  Widget build(BuildContext context) {
    if (photoBase64 != null && photoBase64!.isNotEmpty) {
      try {
        return CircleAvatar(backgroundImage: MemoryImage(base64Decode(photoBase64!)));
      } catch (_) {}
    }

    final initial = label.isEmpty ? '?' : label.trim().characters.first.toUpperCase();
    return CircleAvatar(
      backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
      child: Text(initial, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
    );
  }
}
