import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/local_db.dart';
import '../../core/sync_service.dart';
import '../../core/theme.dart';
import '../../shared/preview_app_bar.dart';

class NovaDemandaScreen extends StatefulWidget {
  const NovaDemandaScreen({super.key});

  @override
  State<NovaDemandaScreen> createState() => _NovaDemandaScreenState();
}

class _NovaDemandaScreenState extends State<NovaDemandaScreen> {
  final _form = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _categoria = 'SOCIAL';
  String _prioridade = 'MEDIA';
  bool _saving = false;

  final _categorias = ['SAUDE', 'URBANA', 'SOCIAL', 'JURIDICA', 'OUTRO'];
  final _prioridades = ['BAIXA', 'MEDIA', 'ALTA', 'URGENTE'];

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      if (kIsWeb && AppConstants.previewMode) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demanda salva no modo preview.'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
        return;
      }

      final id = const Uuid().v4();
      final now = DateTime.now().toIso8601String();
      final db = await LocalDb.instance;

      await db.insert(AppConstants.tDemandas, {
        'id': id,
        'titulo': _tituloCtrl.text.trim(),
        'descricao': _descCtrl.text.trim(),
        'categoria': _categoria,
        'prioridade': _prioridade,
        'status': 'ABERTA',
        'sync_status': 'PENDENTE',
        'created_at': now,
      });

      await SyncService.enqueue(
        clientId: id,
        entidade: 'demanda',
        payload: {
          'titulo': _tituloCtrl.text.trim(),
          'descricao': _descCtrl.text.trim(),
          'categoria': _categoria,
          'prioridade': _prioridade,
        },
      );

      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demanda registrada! Entrará em triagem após sincronização.'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar a demanda agora.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreviewAppBar(title: 'Nova Demanda', replaceOnNavigate: true),
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _tituloCtrl,
                decoration: const InputDecoration(labelText: 'Título *'),
                validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _categoria,
                decoration: const InputDecoration(labelText: 'Categoria *'),
                items: _categorias
                    .map((categoria) => DropdownMenuItem(value: categoria, child: Text(categoria)))
                    .toList(),
                onChanged: (value) => setState(() => _categoria = value!),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _prioridade,
                decoration: const InputDecoration(labelText: 'Prioridade'),
                items: _prioridades
                    .map((prioridade) => DropdownMenuItem(value: prioridade, child: Text(prioridade)))
                    .toList(),
                onChanged: (value) => setState(() => _prioridade = value!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Descrição *',
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _salvar,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Registrar Demanda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
