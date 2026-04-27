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
    return Scaffold(
      appBar: const PreviewAppBar(title: 'Agenda do Dia', replaceOnNavigate: true),
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
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index] as Map<String, dynamic>;
                    final dt = DateTime.parse(item['data_hora_inicio'] as String);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
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
}
