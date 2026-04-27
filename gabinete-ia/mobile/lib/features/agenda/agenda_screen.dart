import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/preview_data.dart';
import '../../core/theme.dart';
import '../../shared/preview_app_bar.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String _filter = 'ABERTOS';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (AppConstants.previewMode) {
      if (mounted) {
        setState(() {
          _items = PreviewData.agenda;
          _loading = false;
        });
      }
      return;
    }

    try {
      final res = await ApiClient.instance.get('/agenda/hoje');
      if (mounted) {
        setState(() {
          _items = res.data as List<dynamic>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _items.where((raw) {
      final item = raw as Map<String, dynamic>;
      final status = (item['status'] ?? 'AGENDADO').toString();
      if (_filter == 'TODOS') return true;
      if (_filter == 'ABERTOS') return !['CONCLUIDO', 'CONCLUIDA', 'ARQUIVADO'].contains(status);
      return status == _filter;
    }).toList();

    return Scaffold(
      appBar: const PreviewAppBar(title: 'Agenda', replaceOnNavigate: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available, size: 64, color: AppTheme.textSecondary),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum compromisso hoje',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: visibleItems.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['ABERTOS', 'TODOS', 'AGENDADO', 'CONCLUIDO', 'ARQUIVADO']
                                .map(
                                  (filter) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(filter == 'ABERTOS' ? 'Abertos' : filter),
                                      selected: _filter == filter,
                                      onSelected: (_) => setState(() => _filter = filter),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      );
                    }
                    final item = visibleItems[index - 1] as Map<String, dynamic>;
                    final rawDate = (item['data_hora_inicio'] ?? item['data_inicio'] ?? DateTime.now().toIso8601String()).toString();
                    final dt = DateTime.tryParse(rawDate) ?? DateTime.now();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () => _openEditor(item: item),
                        leading: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            DateFormat('HH:mm').format(dt),
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text((item['titulo'] ?? '') as String),
                        subtitle: Text((item['descricao'] ?? '') as String),
                        trailing: Chip(
                          label: Text((item['status'] ?? '') as String),
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                          labelStyle: const TextStyle(color: AppTheme.primary),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _openEditor({Map<String, dynamic>? item}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AgendaEditorScreen(
          item: item,
          onSave: (changes) async {
            if (AppConstants.previewMode) {
              setState(() {
                if (item == null) {
                  _items = [
                    {
                      'id': 'agenda-${DateTime.now().millisecondsSinceEpoch}',
                      ...changes,
                    },
                    ..._items,
                  ];
                } else {
                  item.addAll(changes);
                }
              });
              return;
            }

            final endpoint = item == null ? '/agenda-eventos' : '/agenda-eventos/${item['id']}';
            if (item == null) {
              await ApiClient.instance.post(endpoint, data: changes);
            } else {
              await ApiClient.instance.put(endpoint, data: changes);
            }
            await _load();
          },
        ),
      ),
    );
    await _load();
  }
}

class _AgendaEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? item;
  final Future<void> Function(Map<String, dynamic> changes) onSave;

  const _AgendaEditorScreen({this.item, required this.onSave});

  @override
  State<_AgendaEditorScreen> createState() => _AgendaEditorScreenState();
}

class _AgendaEditorScreenState extends State<_AgendaEditorScreen> {
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _descricaoCtrl;
  late final TextEditingController _localCtrl;
  late DateTime _data;
  String _status = 'AGENDADO';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _tituloCtrl = TextEditingController(text: (item?['titulo'] ?? '').toString());
    _descricaoCtrl = TextEditingController(text: (item?['descricao'] ?? '').toString());
    _localCtrl = TextEditingController(text: (item?['local'] ?? item?['local_texto'] ?? '').toString());
    _data = DateTime.tryParse((item?['data_hora_inicio'] ?? item?['data_inicio'] ?? '').toString()) ?? DateTime.now();
    _status = (item?['status'] ?? 'AGENDADO').toString();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_data));
    if (time == null) return;
    setState(() => _data = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save([String? status]) async {
    setState(() => _saving = true);
    await widget.onSave({
      'titulo': _tituloCtrl.text.trim(),
      'descricao': _descricaoCtrl.text.trim(),
      'local': _localCtrl.text.trim(),
      'local_texto': _localCtrl.text.trim(),
      'data_hora_inicio': _data.toIso8601String(),
      'data_inicio': _data.toIso8601String(),
      'status': status ?? _status,
    });
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (status != null) _status = status;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agenda atualizada.'), backgroundColor: AppTheme.success));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreviewAppBar(title: widget.item == null ? 'Novo compromisso' : 'Compromisso', replaceOnNavigate: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _tituloCtrl, decoration: const InputDecoration(labelText: 'Titulo')),
          const SizedBox(height: 14),
          TextField(controller: _descricaoCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Descricao')),
          const SizedBox(height: 14),
          TextField(controller: _localCtrl, decoration: const InputDecoration(labelText: 'Local')),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule, color: AppTheme.primary),
            title: Text(DateFormat('dd/MM/yyyy HH:mm').format(_data)),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: _pickDate,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(onPressed: _saving ? null : () => _save(), icon: const Icon(Icons.save_outlined), label: const Text('Salvar')),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: _saving ? null : () => _save('CONCLUIDO'), icon: const Icon(Icons.check_circle_outline), label: const Text('Finalizar')),
          OutlinedButton.icon(onPressed: _saving ? null : () => _save('ARQUIVADO'), icon: const Icon(Icons.archive_outlined), label: const Text('Arquivar')),
          OutlinedButton.icon(onPressed: _saving ? null : _pickDate, icon: const Icon(Icons.update), label: const Text('Remarcar')),
        ],
      ),
    );
  }
}
