import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/local_db.dart';
import '../../core/preview_data.dart';
import '../../core/theme.dart';
import '../../shared/preview_app_bar.dart';

class MeusRegistrosScreen extends StatefulWidget {
  const MeusRegistrosScreen({super.key});

  @override
  State<MeusRegistrosScreen> createState() => _MeusRegistrosScreenState();
}

class _MeusRegistrosScreenState extends State<MeusRegistrosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _contatos = [];
  List<Map<String, dynamic>> _demandas = [];
  List<Map<String, dynamic>> _visitas = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
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
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Nenhum $type registrado',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final sync = item['sync_status'] as String?;
        final createdAt = item['created_at'] as String?;
        final detail = _detailForItem(item, type);
        final timestamp = createdAt != null
            ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(createdAt))
            : '';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
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
