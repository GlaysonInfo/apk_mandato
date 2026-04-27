import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/preview_data.dart';
import '../../core/sync_service.dart';
import '../../core/theme.dart';
import '../../shared/preview_app_bar.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  List<Map<String, dynamic>> _queue = [];
  bool _syncing = false;
  String? _lastResult;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    if (AppConstants.previewMode) {
      if (mounted) {
        setState(() => _queue = List<Map<String, dynamic>>.from(PreviewData.syncQueue));
      }
      return;
    }

    final queue = await SyncService.getQueue();
    if (mounted) {
      setState(() => _queue = queue);
    }
  }

  Future<void> _syncAll() async {
    if (AppConstants.previewMode) {
      if (mounted) {
        setState(() {
          _syncing = false;
          _lastResult = '1 enviado, 1 pendente, 1 erro (preview)';
        });
      }
      return;
    }

    setState(() => _syncing = true);
    final result = await SyncService.syncAll();
    await _loadQueue();
    if (mounted) {
      setState(() {
        _syncing = false;
        _lastResult = '${result['success']} enviados, ${result['errors']} erros';
      });
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'ENVIADO':
        return AppTheme.success;
      case 'ERRO':
        return AppTheme.error;
      default:
        return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _queue.where((item) => item['status'] == 'PENDENTE').length;
    final sent = _queue.where((item) => item['status'] == 'ENVIADO').length;
    final errors = _queue.where((item) => item['status'] == 'ERRO').length;

    return Scaffold(
      appBar: const PreviewAppBar(title: 'Sincronização', replaceOnNavigate: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _StatCard('Pendentes', pending, AppTheme.warning),
                const SizedBox(width: 8),
                _StatCard('Enviados', sent, AppTheme.success),
                const SizedBox(width: 8),
                _StatCard('Erros', errors, AppTheme.error),
              ],
            ),
            const SizedBox(height: 16),
            if (_lastResult != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _lastResult!,
                      style: const TextStyle(color: AppTheme.primary),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _syncing ? null : _syncAll,
              icon: _syncing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(_syncing ? 'Sincronizando...' : 'Sincronizar Tudo'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _queue.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum item na fila',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _queue.length,
                      itemBuilder: (context, index) {
                        final item = _queue[index];
                        final status = item['status'] as String?;
                        final entidade = item['entidade']?.toString() ?? '';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              entidade == 'contato'
                                  ? Icons.person_outline
                                  : entidade == 'demanda'
                                      ? Icons.assignment_outlined
                                      : Icons.directions_walk,
                              color: _statusColor(status),
                            ),
                            title: Text(entidade),
                            subtitle: Text(
                              [
                                item['descricao']?.toString(),
                                if (item['created_at'] != null)
                                  DateFormat('HH:mm').format(
                                    DateTime.parse(item['created_at'] as String),
                                  ),
                                if (status == 'ERRO') 'Toque para reenviar',
                              ].whereType<String>().where((value) => value.isNotEmpty).join(' • '),
                              style: TextStyle(
                                color: status == 'ERRO' ? AppTheme.error : AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Chip(
                              label: Text(status ?? ''),
                              backgroundColor: _statusColor(status).withValues(alpha: 0.1),
                              labelStyle: TextStyle(
                                color: _statusColor(status),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
